import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';
import 'connectors/ai/ai_provider.dart';
import 'connectors/connector.dart';
import 'connectors/csv/csv_import_connector.dart';
import 'connectors/events/event_sources.dart';
import 'connectors/events/ics_codec.dart';
import 'connectors/payment/fake_payment_provider.dart';
import 'connectors/payment/payment_provider.dart';
import 'connectors/payment/square_provider.dart';
import 'connectors/trends/trend_feed.dart';
import 'data/db/database.dart';
import 'data/db/tables.dart' show newId;
import 'data/repos/event_repo.dart';
import 'data/repos/inventory_repo.dart';
import 'data/repos/product_repo.dart';
import 'data/repos/repository.dart';
import 'data/repos/sales_repo.dart';
import 'data/sample_seed.dart';
import 'domain/analytics_service.dart';
import 'domain/enums.dart';
import 'domain/pricing_service.dart';
import 'domain/recommendation_service.dart';
import 'export/export_service.dart';
import 'services/auth_service.dart';
import 'services/entitlements.dart';
import 'services/haptics_service.dart';
import 'services/job_runner.dart';
import 'services/purchase_service.dart';
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

// ---------------- plan ----------------

final purchasesProvider = Provider<PurchaseService>((ref) {
  final c = ref.watch(configProvider);
  return c.useFakes ? FakePurchases() : RevenueCatPurchases(appleKey: c.revenueCatAppleKey, googleKey: c.revenueCatGoogleKey);
});

final entitlementsProvider = StateProvider<Entitlements>((_) => Entitlements.free);

final authProvider = Provider<AuthService?>((ref) {
  final client = ref.watch(supabaseProvider);
  return client == null ? null : AuthService(client, googleServerClientId: const String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID'));
});

// ---------------- data ----------------

final syncServiceProvider = Provider<SyncService?>((ref) {
  final client = ref.watch(supabaseProvider);
  if (client == null) return null;
  return SyncService(ref.watch(dbProvider), client, isPro: () => ref.read(entitlementsProvider).can(Feature.cloudBackup));
});

final changeTrackerProvider = Provider<ChangeTracker>((ref) => ref.watch(syncServiceProvider) ?? const NoopChangeTracker());

final productRepoProvider = Provider(
  (ref) => ProductRepo(ref.watch(dbProvider), ref.watch(changeTrackerProvider), ref.watch(deviceIdProvider)),
);
final eventRepoProvider = Provider(
  (ref) => EventRepo(ref.watch(dbProvider), ref.watch(changeTrackerProvider), ref.watch(deviceIdProvider)),
);
final inventoryRepoProvider = Provider(
  (ref) => InventoryRepo(ref.watch(dbProvider), ref.watch(changeTrackerProvider), ref.watch(deviceIdProvider)),
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

final cursorStoreProvider = Provider((ref) => CursorStore(ref.watch(dbProvider)));

final paymentProviderProvider = Provider<PaymentProvider>((ref) {
  final c = ref.watch(configProvider);
  final cursors = ref.watch(cursorStoreProvider);
  final sales = ref.watch(salesRepoProvider);
  final client = ref.watch(supabaseProvider);
  if (c.useFakes || client == null) return FakePaymentProvider(cursors, sales);
  return SquareProvider(
    cursors,
    sales,
    storage: ref.watch(secureStorageProvider),
    tokenExchange: (body) async => (await client.functions.invoke('square-token', body: body)).data as Map<String, dynamic>,
  );
});

final conSourceProvider = Provider<ConSource>((ref) {
  final c = ref.watch(configProvider);
  return c.hasBackend && !c.useFakes ? AnimeConsFeed(supabaseUrl: c.supabaseUrl, anonKey: c.supabaseAnonKey) : FakeConSource();
});

final icsConnectorProvider = Provider((ref) => IcsConnector(ref.watch(cursorStoreProvider), ref.watch(eventRepoProvider)));

final csvImportProvider = Provider(
  (ref) => CsvProductImport(
    ref.watch(cursorStoreProvider),
    ref.watch(productRepoProvider),
    (id, qty) => ref.read(inventoryRepoProvider).restock(id, qty),
  ),
);

final trendFeedProvider = Provider<TrendFeed?>((ref) {
  final c = ref.watch(configProvider);
  if (!c.hasBackend || c.useFakes) return null;
  return TrendFeed(ref.watch(cursorStoreProvider), ref.watch(dbProvider), supabaseUrl: c.supabaseUrl, anonKey: c.supabaseAnonKey);
});

final aiProvider = Provider<AiProvider>((ref) {
  final c = ref.watch(configProvider);
  final auth = ref.watch(authProvider);
  final pro = ref.watch(entitlementsProvider).can(Feature.aiCaption);
  if (!pro || auth == null) return const LocalTemplateProvider();
  return ClaudeProxyProvider(functionsUrl: '${c.supabaseUrl}/functions/v1', accessToken: auth.accessToken);
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

final exportServiceProvider = Provider((ref) {
  final brand = ref.watch(brandProvider).valueOrNull;
  return ExportService(entitlements: () => ref.read(entitlementsProvider), shopName: brand?.shopName ?? 'My shop');
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

class TodayStats {
  const TodayStats({this.grossCents = 0, this.costCents = 0, this.units = 0});
  final int grossCents;
  final int costCents;
  final int units;
  int get netCents => grossCents - costCents;
}

final todayStatsProvider = StreamProvider<TodayStats>((ref) {
  final db = ref.watch(dbProvider);
  final now = DateTime.now();
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
      .map((r) => TodayStats(grossCents: r.read<int>('gross'), costCents: r.read<int>('cost'), units: r.read<int>('units')));
});

final connectionLabelProvider = StreamProvider<String>((ref) async* {
  final pro = ref.watch(entitlementsProvider).can(Feature.cloudBackup);
  final sync = ref.watch(syncServiceProvider);
  Future<String> label(List<ConnectivityResult> r) async {
    if (r.contains(ConnectivityResult.none)) return 'Offline, saved on phone';
    if (!pro || sync == null) return 'Saved on phone';
    final n = await sync.pendingCount();
    return n == 0 ? 'Synced' : 'Syncing $n';
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
  final conn = ref.watch(connectionLabelProvider).valueOrNull ?? 'Saved on phone';
  final now = DateTime.now();
  if (event == null) {
    return EventBarState(eventName: 'No event yet', statusLabel: 'Add one', isLive: false, netTodayCents: today.netCents, connectionLabel: conn);
  }
  final live = !now.isBefore(event.startsAt) && !now.isAfter(event.endsAt);
  final status = live
      ? 'Live day ${now.difference(DateTime(event.startsAt.year, event.startsAt.month, event.startsAt.day)).inDays + 1}'
      : event.startsAt.isAfter(now)
          ? 'In ${event.startsAt.difference(now).inDays + 1} d'
          : 'Ended';
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
    await Supabase.initialize(url: config.supabaseUrl, anonKey: config.supabaseAnonKey);
  }

  final purchases = ref.read(purchasesProvider);
  purchases.entitlements.listen((e) => ref.read(entitlementsProvider.notifier).state = e);
  unawaited(purchases.init().catchError((_) {}));

  if (config.useFakes) await SampleSeed(ref.read(dbProvider)).seedIfEmpty();

  ref.read(jobRunnerProvider).start();
  unawaited(ref.read(trendFeedProvider)?.ingest());
});
