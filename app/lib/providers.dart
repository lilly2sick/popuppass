import 'dart:async';

import 'package:clock/clock.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app/router.dart';
import 'config.dart';
import 'l10n/app_localizations.dart';
import 'l10n/app_localizations_en.dart';
import 'connectors/ai/ai_provider.dart';
import 'connectors/csv/csv_product_import.dart';
import 'connectors/csv/csv_sales_import.dart';
import 'connectors/events/animecons_feed.dart';
import 'connectors/events/con_source.dart';
import 'connectors/events/fake_con_source.dart';
import 'connectors/events/ics_connector.dart';
import 'connectors/payment/fake_payment_provider.dart';
import 'connectors/payment/payment_provider.dart';
import 'connectors/payment/square_provider.dart';
import 'connectors/sync_cursor.dart';
import 'connectors/trends/trend_feed.dart';
import 'data/db/database.dart';
import 'data/repos/event_repo.dart';
import 'data/repos/inventory_repo.dart';
import 'data/repos/product_repo.dart';
import 'data/repos/repository.dart';
import 'data/repos/sales_repo.dart';
import 'data/sample_seed.dart';
import 'domain/analytics_service.dart';
import 'domain/enums.dart';
import 'domain/pricing_service.dart';
import 'domain/recommendation_schedule.dart';
import 'domain/recommendation_service.dart';
import 'export/export_service.dart';
import 'services/auth_service.dart';
import 'services/entitlements.dart';
import 'services/haptics_service.dart';
import 'services/job_runner.dart';
import 'services/purchase_service.dart';
import 'services/recommendation_notifier.dart';
import 'services/recommendation_schedule_store.dart';
import 'services/social_share_service.dart';
import 'services/sync_service.dart';

// ---------------- core ----------------

final configProvider = Provider<AppConfig>((_) => AppConfig.fromEnvironment());

final dbProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

final deviceIdProvider = StateProvider<String>((_) => 'unset');

final secureStorageProvider = Provider((_) => const FlutterSecureStorage());

/// Null when running without a backend (free-only or fakes).
final supabaseProvider = Provider<SupabaseClient?>((ref) {
  return ref.watch(configProvider).hasBackend ? Supabase.instance.client : null;
});

final hapticsProvider = Provider((_) => HapticsService());

final socialShareProvider = Provider(
  (ref) => SocialShareService(metaAppId: ref.watch(configProvider).metaAppId),
);

/// Strings for code that runs outside the widget tree (labels derived in
/// providers). English is the only shipped locale; override when adding more.
final l10nProvider = Provider<AppLocalizations>((_) => AppLocalizationsEn());

// ---------------- plan ----------------

final purchasesProvider = Provider<PurchaseService>((ref) {
  final c = ref.watch(configProvider);
  return c.useFakes
      ? FakePurchases()
      : RevenueCatPurchases(appleKey: c.revenueCatAppleKey, googleKey: c.revenueCatGoogleKey);
});

final entitlementsProvider = StateProvider<Entitlements>((_) => Entitlements.free);

final authProvider = Provider<AuthService?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null
      ? null
      : AuthService(
          client,
          googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'),
        );
});

// ---------------- data ----------------

final syncServiceProvider = Provider<SyncService?>((ref) {
  final client = ref.watch(supabaseProvider);
  if (client == null) return null;
  return SyncService(
    ref.watch(dbProvider),
    client,
    isPro: () => ref.read(entitlementsProvider).can(Feature.cloudBackup),
  );
});

final changeTrackerProvider = Provider<ChangeTracker>(
  (ref) => ref.watch(syncServiceProvider) ?? const NoopChangeTracker(),
);

final productRepoProvider = Provider(
  (ref) => ProductRepo(
    ref.watch(dbProvider),
    ref.watch(changeTrackerProvider),
    ref.watch(deviceIdProvider),
  ),
);
final eventRepoProvider = Provider(
  (ref) => EventRepo(
    ref.watch(dbProvider),
    ref.watch(changeTrackerProvider),
    ref.watch(deviceIdProvider),
  ),
);
final inventoryRepoProvider = Provider(
  (ref) => InventoryRepo(
    ref.watch(dbProvider),
    ref.watch(changeTrackerProvider),
    ref.watch(deviceIdProvider),
  ),
);
final salesRepoProvider = Provider(
  (ref) => SalesRepo(
    ref.watch(dbProvider),
    ref.watch(changeTrackerProvider),
    ref.watch(deviceIdProvider),
    ref.watch(productRepoProvider),
    ref.watch(inventoryRepoProvider),
  ),
);

// ---------------- connectors ----------------

final syncCursorProvider = Provider((ref) => SyncCursor(ref.watch(dbProvider)));

final paymentProviderProvider = Provider<PaymentProvider>((ref) {
  final c = ref.watch(configProvider);
  final cursors = ref.watch(syncCursorProvider);
  final sales = ref.watch(salesRepoProvider);
  final client = ref.watch(supabaseProvider);
  if (c.useFakes || client == null) return FakePaymentProvider(cursors, sales);
  return SquareProvider(
    cursors,
    sales,
    appId: c.squareAppId,
    storage: ref.watch(secureStorageProvider),
    tokenExchange: (body) async =>
        (await client.functions.invoke('square-token', body: body)).data as Map<String, dynamic>,
    authorize: (url, callbackScheme) =>
        FlutterWebAuth2.authenticate(url: url.toString(), callbackUrlScheme: callbackScheme),
  );
});

final conSourceProvider = Provider<ConSource>((ref) {
  final c = ref.watch(configProvider);
  return c.hasBackend && !c.useFakes
      ? AnimeConsFeed(supabaseUrl: c.supabaseUrl, anonKey: c.supabaseAnonKey)
      : FakeConSource();
});

final icsConnectorProvider = Provider(
  (ref) => IcsConnector(ref.watch(syncCursorProvider), ref.watch(eventRepoProvider)),
);

final csvProductImportProvider = Provider(
  (ref) => CsvProductImport(
    ref.watch(syncCursorProvider),
    ref.watch(productRepoProvider),
    (id, qty) => ref.read(inventoryRepoProvider).restock(id, qty),
  ),
);

final csvSalesImportProvider = Provider(
  (ref) => CsvSalesImport(
    ref.watch(syncCursorProvider),
    ref.watch(salesRepoProvider),
    ref.watch(productRepoProvider),
  ),
);

final trendFeedProvider = Provider<TrendFeed?>((ref) {
  final c = ref.watch(configProvider);
  if (!c.hasBackend || c.useFakes) return null;
  return TrendFeed(
    ref.watch(syncCursorProvider),
    ref.watch(dbProvider),
    supabaseUrl: c.supabaseUrl,
    anonKey: c.supabaseAnonKey,
  );
});

final aiProvider = Provider<AiProvider>((ref) {
  final c = ref.watch(configProvider);
  final auth = ref.watch(authProvider);
  final pro = ref.watch(entitlementsProvider).can(Feature.aiCaption);
  if (!pro || auth == null) return const LocalTemplateProvider();
  return ClaudeProxyProvider(
    functionsUrl: '${c.supabaseUrl}/functions/v1',
    accessToken: auth.accessToken,
  );
});

final jobRunnerProvider = Provider((ref) {
  final runner = JobRunner(ref.watch(dbProvider), ref.watch(aiProvider));
  ref.onDispose(runner.stop);
  return runner;
});

// ---------------- domain ----------------

final pricingProvider = Provider((_) => const PricingService());
final analyticsProvider = Provider((ref) => AnalyticsService(ref.watch(salesRepoProvider)));
final recommendationProvider = Provider((_) => const RecommendationService());

final recommendationNotifierProvider = Provider<RecommendationNotifier>(
  (_) => LocalRecommendationNotifier(),
);

final recommendationScheduleStoreProvider = Provider(
  (ref) => RecommendationScheduleStore(ref.watch(secureStorageProvider)),
);

/// The vendor's SPEC 16 choice (default weekly at 9:00). Changing it saves
/// it and re-queues the local notifications.
class RecommendationScheduleController extends AsyncNotifier<RecommendationSchedule> {
  @override
  Future<RecommendationSchedule> build() => ref.read(recommendationScheduleStoreProvider).read();

  Future<void> choose({RecommendationFrequency? frequency, int? hour, int? minute}) async {
    final current = await future;
    final next = current.copyWith(
      frequency: frequency,
      hour: hour,
      minute: minute,
      // Weekly and biweekly land on the weekday the choice was made.
      anchor: frequency != null && frequency != current.frequency ? clock.now() : null,
    );
    state = AsyncData(next);
    await ref.read(recommendationScheduleStoreProvider).write(next);
    await apply();
  }

  /// Re-queues notifications from the saved choice and today's batch. Runs
  /// on every start so the lookahead window keeps moving.
  Future<void> apply() async {
    final schedule = await future;
    final l10n = ref.read(l10nProvider);
    final trends = await ref.read(trendsProvider.future);
    final swiped = await ref.read(swipedIdsProvider.future);
    final brand = await ref.read(brandProvider.future);
    final cards = ref
        .read(recommendationProvider)
        .batch(trends: trends, shopTags: {...?brand?.nicheTags}, swipedIds: swiped);
    final best = ref.read(bestSellerProvider);
    await ref
        .read(recommendationNotifierProvider)
        .replaceAll(
          schedule.upcoming(clock.now()),
          title: l10n.recommendationNotificationTitle,
          body: best == null
              ? l10n.recommendationNotificationBody(cards.length)
              : l10n.recommendationNotificationBodyBest(best.name, cards.length),
        );
  }
}

final recommendationScheduleProvider =
    AsyncNotifierProvider<RecommendationScheduleController, RecommendationSchedule>(
      RecommendationScheduleController.new,
    );

/// The product with the most units sold, if anything has sold.
final bestSellerProvider = Provider<Product?>((ref) {
  final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
  final sold = ref.watch(soldCountsProvider).valueOrNull ?? const <String, int>{};
  Product? best;
  for (final p in products) {
    if ((sold[p.id] ?? 0) > (best == null ? 0 : sold[best.id] ?? 0)) best = p;
  }
  return best;
});

/// Product id Create should open with a draft ready. Set by Home's best
/// seller suggestion; Create clears it once it has picked the item.
final createDraftProductProvider = StateProvider<String?>((_) => null);

final exportServiceProvider = Provider((ref) {
  final brand = ref.watch(brandProvider).valueOrNull;
  return ExportService(
    entitlements: () => ref.read(entitlementsProvider),
    shopName: brand?.shopName ?? 'My shop',
  );
});

// ---------------- streams the UI reads ----------------

final productsProvider = StreamProvider((ref) => ref.watch(productRepoProvider).watchAll());
final stockProvider = StreamProvider((ref) => ref.watch(inventoryRepoProvider).watchStock());
final eventsProvider = StreamProvider((ref) => ref.watch(eventRepoProvider).watchAll());
final currentEventProvider = StreamProvider((ref) => ref.watch(eventRepoProvider).watchCurrent());

final brandProvider = StreamProvider<Brand?>((ref) {
  final db = ref.watch(dbProvider);
  return (db.select(db.brands)..limit(1)).watchSingleOrNull();
});

final trendsProvider = StreamProvider((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.trendCache).watch();
});

final swipedIdsProvider = StreamProvider<Set<String>>((ref) {
  final db = ref.watch(dbProvider);
  return db.select(db.swipeFeedback).watch().map((rows) => {for (final r in rows) r.trendId});
});

/// Right-swiped cards, newest first, with the trend they came from. The
/// Home inspiration board's "Saved ideas" list.
final savedIdeasProvider = StreamProvider<List<CachedTrend>>((ref) {
  final db = ref.watch(dbProvider);
  final q =
      db.select(db.swipeFeedback).join([
          innerJoin(db.trendCache, db.trendCache.id.equalsExp(db.swipeFeedback.trendId)),
        ])
        ..where(db.swipeFeedback.liked.equals(true))
        ..orderBy([OrderingTerm.desc(db.swipeFeedback.at)]);
  return q.watch().map((rows) => [for (final r in rows) r.readTable(db.trendCache)]);
});

class TodayStats {
  const TodayStats({this.grossCents = 0, this.costCents = 0, this.units = 0});
  final int grossCents;
  final int costCents;
  final int units;
  int get netCents => grossCents - costCents;
}

final todayStatsProvider = StreamProvider<TodayStats>((ref) {
  final db = ref.watch(dbProvider);
  final now = clock.now();
  final start = DateTime(now.year, now.month, now.day);
  return db
      .customSelect(
        'SELECT COALESCE(SUM(l.qty * l.unit_price_cents), 0) AS gross, '
        'COALESCE(SUM(l.qty * l.unit_cost_cents), 0) AS cost, COALESCE(SUM(l.qty), 0) AS units '
        'FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
        'WHERE s.deleted = 0 AND l.deleted = 0 AND s.sold_at >= ?',
        variables: [Variable.withDateTime(start)],
        readsFrom: {db.sales, db.saleLines},
      )
      .watchSingle()
      .map(
        (r) => TodayStats(
          grossCents: r.read<int>('gross'),
          costCents: r.read<int>('cost'),
          units: r.read<int>('units'),
        ),
      );
});

final connectionLabelProvider = StreamProvider<String>((ref) async* {
  final l10n = ref.watch(l10nProvider);
  final pro = ref.watch(entitlementsProvider).can(Feature.cloudBackup);
  final sync = ref.watch(syncServiceProvider);
  Future<String> label(List<ConnectivityResult> r) async {
    if (r.contains(ConnectivityResult.none)) return l10n.connectionOffline;
    if (!pro || sync == null) return l10n.connectionSavedOnPhone;
    final n = await sync.pendingCount();
    return n == 0 ? l10n.connectionSynced : l10n.connectionSyncing(n);
  }

  final connectivity = Connectivity();
  yield await label(await connectivity.checkConnectivity());
  await for (final r in connectivity.onConnectivityChanged) {
    yield await label(r);
  }
});

class EventBarState {
  const EventBarState({
    required this.eventName,
    required this.statusLabel,
    required this.isLive,
    required this.netTodayCents,
    required this.connectionLabel,
    this.boothLabel,
  });

  final String eventName;
  final String statusLabel;
  final bool isLive;
  final String? boothLabel;
  final int netTodayCents;
  final String connectionLabel;
}

final eventBarProvider = Provider<EventBarState>((ref) {
  final event = ref.watch(currentEventProvider).valueOrNull;
  final today = ref.watch(todayStatsProvider).valueOrNull ?? const TodayStats();
  final l10n = ref.watch(l10nProvider);
  final conn = ref.watch(connectionLabelProvider).valueOrNull ?? l10n.connectionSavedOnPhone;
  final now = clock.now();
  if (event == null) {
    return EventBarState(
      eventName: l10n.eventBarNoEvent,
      statusLabel: l10n.eventBarAddOne,
      isLive: false,
      netTodayCents: today.netCents,
      connectionLabel: conn,
    );
  }
  final live = !now.isBefore(event.startsAt) && !now.isAfter(event.endsAt);
  final status = live
      ? l10n.eventBarLiveDay(
          now
                  .difference(
                    DateTime(event.startsAt.year, event.startsAt.month, event.startsAt.day),
                  )
                  .inDays +
              1,
        )
      : event.startsAt.isAfter(now)
      ? l10n.eventBarInDays(event.startsAt.difference(now).inDays + 1)
      : l10n.eventBarEnded;
  return EventBarState(
    eventName: event.name,
    statusLabel: status,
    isLive: live,
    boothLabel: event.boothLabel,
    netTodayCents: today.netCents,
    connectionLabel: conn,
  );
});

// ---------------- table state ----------------

final paymentMethodProvider = StateProvider<PaymentMethod>((_) => PaymentMethod.cash);

/// productId -> sale ids logged this session, newest last. -1 pops from here,
/// so it can only take back sales made on this screen.
final sessionSalesProvider = StateProvider<Map<String, List<String>>>((_) => const {});

/// productId -> units sold (all time, voids excluded).
final soldCountsProvider = StreamProvider<Map<String, int>>((ref) {
  final db = ref.watch(dbProvider);
  return db
      .customSelect(
        'SELECT l.product_id, SUM(l.qty) AS units FROM sale_lines l JOIN sales s ON s.id = l.sale_id '
        'WHERE s.deleted = 0 AND l.deleted = 0 AND l.product_id IS NOT NULL GROUP BY l.product_id',
        readsFrom: {db.sales, db.saleLines},
      )
      .watch()
      .map((rows) => {for (final r in rows) r.read<String>('product_id'): r.read<int>('units')});
});

// ---------------- startup ----------------

final bootstrapProvider = FutureProvider<void>((ref) async {
  final config = ref.read(configProvider);
  final storage = ref.read(secureStorageProvider);

  var deviceId = await storage.read(key: 'device_id');
  if (deviceId == null) {
    deviceId = newId();
    await storage.write(key: 'device_id', value: deviceId);
  }
  ref.read(deviceIdProvider.notifier).state = deviceId;

  if (config.hasBackend) {
    await Supabase.initialize(url: config.supabaseUrl, publishableKey: config.supabaseAnonKey);
  }

  final purchases = ref.read(purchasesProvider);
  purchases.entitlements.listen((e) => ref.read(entitlementsProvider.notifier).state = e);
  unawaited(purchases.init().catchError((_) {}));

  if (config.useFakes) await SampleSeed(ref.read(dbProvider)).seedIfEmpty();

  ref.read(jobRunnerProvider).start();
  unawaited(ref.read(trendFeedProvider)?.ingest());

  final notifier = ref.read(recommendationNotifierProvider);
  await notifier.init(onOpen: () => ref.read(routerProvider).go(AppTab.home.path));
  unawaited(ref.read(recommendationScheduleProvider.notifier).apply());
});
