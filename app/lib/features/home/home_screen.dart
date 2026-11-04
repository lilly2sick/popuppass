import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/pp_scaffold.dart';
import '../../app/router.dart';
import '../../data/db/database.dart';
import '../../design/components/ascii_pups.dart';
import '../../design/components/sticker.dart';
import '../../design/components/stats.dart';
import '../../design/components/tiles.dart';
import '../../design/tokens.dart';
import '../../domain/money.dart';
import '../../providers.dart';
import '../../services/haptics_service.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(todayStatsProvider).valueOrNull ?? const TodayStats();
    final products = ref.watch(productsProvider).valueOrNull ?? const <Product>[];
    final stock = ref.watch(stockProvider).valueOrNull ?? const {};
    final sold = ref.watch(soldCountsProvider).valueOrNull ?? const {};
    final low = products.where((p) => (stock[p.id] ?? 0) <= p.lowStockThreshold).toList();
    final favs = [...products]..sort((a, b) => (sold[b.id] ?? 0).compareTo(sold[a.id] ?? 0));
    final top = favs.take(3).toList();
    final maxSold = top.isEmpty ? 1 : (sold[top.first.id] ?? 0).clamp(1, 1 << 30);

    return PPScaffold(
      eyebrow: 'Made for the makers',
      title: 'Hey, maker.',
      searchHint: 'Search items, sales, events',
      action: PPButton(label: 'Open table', onPressed: () => context.go(AppTab.sell.path)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: StatCard(label: 'Gross', value: Money.format(today.grossCents))),
              const SizedBox(width: PPSpace.sm),
              Expanded(child: StatCard(label: 'Sold', value: '${today.units}')),
              const SizedBox(width: PPSpace.sm),
              Expanded(
                child: StatCard(
                  label: 'Low',
                  value: '${low.length}',
                  unit: low.length == 1 ? 'item' : 'items',
                  warn: low.isNotEmpty,
                  onTap: () => context.go(AppTab.shop.path),
                ),
              ),
            ],
          ),
          if (low.isNotEmpty) ...[
            const SizedBox(height: PPSpace.md),
            StickerCard(
              iridescent: true,
              fill: PPColors.surface,
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: PPColors.pink),
                    child: Text('!', style: PPType.body(size: 18, weight: FontWeight.w900, color: PPColors.onAccent)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${low.first.name} is almost gone.', style: PPType.body(size: 15, weight: FontWeight.w800)),
                        Text('${stock[low.first.id] ?? 0} left.', style: PPType.body(size: 13, color: PPColors.muted)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (top.isNotEmpty) ...[
            const SizedBox(height: PPSpace.md),
            StickerCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Fan favorites', style: PPType.title(size: 20)),
                  const SizedBox(height: PPSpace.sm),
                  for (var i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(width: 26, child: Text('0${i + 1}', style: PPType.number(size: 16, color: PPColors.violet))),
                          SizedBox(width: 110, child: Text(top[i].name, maxLines: 1, overflow: TextOverflow.ellipsis, style: PPType.body(size: 14, weight: FontWeight.w800))),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: (sold[top[i].id] ?? 0) / maxSold,
                                minHeight: 10,
                                backgroundColor: PPColors.raised,
                                color: PPColors.teal,
                              ),
                            ),
                          ),
                          SizedBox(width: 56, child: Text('${sold[top[i].id] ?? 0} sold', textAlign: TextAlign.right, style: PPType.body(size: 13, weight: FontWeight.w800))),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: PPSpace.lg),
          Text('Room to experiment', style: PPType.title(size: 20)),
          const SizedBox(height: PPSpace.sm),
          const _TrendDeck(),
          const SizedBox(height: PPSpace.xl),
          const AsciiPups(),
        ],
      ),
    );
  }
}

/// Swipe right to keep an idea, left to pass. Ranked on device.
class _TrendDeck extends ConsumerStatefulWidget {
  const _TrendDeck();

  @override
  ConsumerState<_TrendDeck> createState() => _TrendDeckState();
}

class _TrendDeckState extends ConsumerState<_TrendDeck> {
  final _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _record(CachedTrend t, bool liked) async {
    ref.read(hapticsProvider).play(HapticMoment.selection);
    final db = ref.read(dbProvider);
    await db.into(db.swipeFeedback).insertOnConflictUpdate(
          SwipeFeedbackCompanion.insert(trendId: t.id, liked: liked, at: Value(DateTime.now())),
        );
  }

  @override
  Widget build(BuildContext context) {
    final trends = ref.watch(trendsProvider).valueOrNull ?? const [];
    final swiped = ref.watch(swipedIdsProvider).valueOrNull ?? const {};
    final brand = ref.watch(brandProvider).valueOrNull;
    final ranked = ref.watch(recommendationProvider).rank(
          trends: trends,
          shopTags: {...?brand?.nicheTags},
          swipedIds: swiped,
        );

    if (ranked.isEmpty) {
      return const EmptyState(title: 'All caught up', message: 'New ideas land when the trend board refreshes.');
    }

    return Column(
      children: [
        SizedBox(
          height: 220,
          child: CardSwiper(
            controller: _controller,
            cardsCount: ranked.length,
            numberOfCardsDisplayed: ranked.length.clamp(1, 2),
            isLoop: false,
            padding: EdgeInsets.zero,
            onSwipe: (i, _, dir) {
              _record(ranked[i], dir == CardSwiperDirection.right);
              return true;
            },
            cardBuilder: (context, i, _, __) {
              final t = ranked[i];
              return TrendCard(title: t.title, why: t.why, badge: 'Rising', sources: t.sources);
            },
          ),
        ),
        const SizedBox(height: PPSpace.md),
        Row(
          children: [
            Expanded(
              child: PPButton.secondary(
                label: 'Not for me',
                icon: Icons.close_rounded,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),
            ),
            const SizedBox(width: PPSpace.sm),
            Expanded(
              child: PPButton(
                label: 'Try it',
                icon: Icons.check_rounded,
                onPressed: () => _controller.swipe(CardSwiperDirection.right),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
