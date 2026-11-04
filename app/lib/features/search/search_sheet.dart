import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../app/router.dart';
import '../../design/components/sticker.dart';
import '../../design/tokens.dart';
import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../../providers.dart';
import '../events/events_sheet.dart';

/// Opens the jump-to item for a product on the Sell card view.
final sellFocusProvider = StateProvider<String?>((_) => null);

/// App-wide search: items and events. Everything is local, so it works offline.
Future<void> showSearchResults(BuildContext context, String query) async {
  if (query.trim().isEmpty) return;
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) =>
        FractionallySizedBox(heightFactor: 0.8, child: _Results(query: query.trim().toLowerCase())),
  );
}

class _Results extends ConsumerWidget {
  const _Results({required this.query});

  final String query;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = (ref.watch(productsProvider).valueOrNull ?? const [])
        .where((p) => p.name.toLowerCase().contains(query))
        .toList();
    final events = (ref.watch(eventsProvider).valueOrNull ?? const [])
        .where((e) => e.name.toLowerCase().contains(query))
        .toList();
    final stock = ref.watch(stockProvider).valueOrNull ?? const {};
    final l10n = AppLocalizations.of(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(PPSpace.gutter, 0, PPSpace.gutter, PPSpace.xl),
      children: [
        Text(l10n.searchResultsFor(query), style: PPType.title(size: 22)),
        const SizedBox(height: PPSpace.md),
        if (products.isEmpty && events.isEmpty)
          EmptyState(title: l10n.searchNothingFoundTitle, message: l10n.searchNothingFoundMessage),
        if (products.isNotEmpty)
          Text(l10n.searchItemsHeader, style: PPType.label(color: PPColors.muted)),
        for (final p in products)
          Padding(
            padding: const EdgeInsets.only(top: PPSpace.sm),
            child: StickerCard(
              radius: PPRadius.tile,
              padding: const EdgeInsets.all(PPSpace.md),
              onTap: () {
                ref.read(sellFocusProvider.notifier).state = p.id;
                Navigator.pop(context);
                context.go(AppTab.sell.path);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(p.name, style: PPType.body(weight: FontWeight.w800)),
                  ),
                  Text(
                    l10n.searchLeftPrice(stock[p.id] ?? 0, Money.format(p.priceCents)),
                    style: PPType.body(size: 13, color: PPColors.muted),
                  ),
                ],
              ),
            ),
          ),
        if (events.isNotEmpty) ...[
          const SizedBox(height: PPSpace.lg),
          Text(l10n.searchEventsHeader, style: PPType.label(color: PPColors.muted)),
        ],
        for (final e in events)
          Padding(
            padding: const EdgeInsets.only(top: PPSpace.sm),
            child: StickerCard(
              radius: PPRadius.tile,
              padding: const EdgeInsets.all(PPSpace.md),
              onTap: () {
                Navigator.pop(context);
                showEventsSheet(context);
              },
              child: Row(
                children: [
                  Expanded(
                    child: Text(e.name, style: PPType.body(weight: FontWeight.w800)),
                  ),
                  Text(
                    DateFormat('MMM d').format(e.startsAt),
                    style: PPType.body(size: 13, color: PPColors.muted),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
