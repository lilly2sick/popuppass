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
import '../../l10n/app_localizations.dart';
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

    final l10n = AppLocalizations.of(context);
    final totalSold = sold.values.fold<int>(0, (a, b) => a + b);
    final totalStocked = stock.values.fold<int>(0, (a, b) => a + b) + totalSold;

    return PPScaffold(
      eyebrow: l10n.homeEyebrow,
      title: l10n.homeTitle,
      searchHint: l10n.homeSearchHint,
      action: PPButton(label: l10n.homeOpenTable, onPressed: () => context.go(AppTab.sell.path)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: StatCard(label: l10n.homeStatGross, value: Money.format(today.grossCents)),
              ),
              const SizedBox(width: PPSpace.sm),
              Expanded(
                child: StatCard(label: l10n.homeStatSold, value: '${today.units}'),
              ),
              const SizedBox(width: PPSpace.sm),
              Expanded(
                child: StatCard(
                  label: l10n.homeStatLow,
                  value: '${low.length}',
                  unit: low.length == 1 ? l10n.homeItemOne : l10n.homeItemMany,
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
                    child: Text(
                      '!',
                      style: PPType.body(
                        size: 18,
                        weight: FontWeight.w900,
                        color: PPColors.onAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.homeAlmostGone(low.first.name),
                          style: PPType.body(size: 15, weight: FontWeight.w800),
                        ),
                        Text(
                          l10n.homeLeft(stock[low.first.id] ?? 0),
                          style: PPType.body(size: 13, color: PPColors.muted),
                        ),
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
                  Text(l10n.homeFanFavorites, style: PPType.title(size: 20)),
                  const SizedBox(height: PPSpace.sm),
                  for (var i = 0; i < top.length; i++)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 26,
                            child: Text(
                              '0${i + 1}',
                              style: PPType.number(size: 16, color: PPColors.violet),
                            ),
                          ),
                          SizedBox(
                            width: 110,
                            child: Text(
                              top[i].name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: PPType.body(size: 14, weight: FontWeight.w800),
                            ),
                          ),
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
                          SizedBox(
                            width: 56,
                            child: Text(
                              l10n.homeSoldCount(sold[top[i].id] ?? 0),
                              textAlign: TextAlign.right,
                              style: PPType.body(size: 13, weight: FontWeight.w800),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: PPSpace.lg),
          Text(l10n.homeDayTitle, style: PPType.title(size: 20)),
          const SizedBox(height: PPSpace.sm),
          _DaySteps(
            steps: [
              _Step(
                l10n.homeStepBeforeTag,
                l10n.homeStepBeforeTitle,
                l10n.homeStepBeforeText(totalStocked),
                _StepState.done,
              ),
              _Step(
                l10n.homeStepNowTag,
                l10n.homeStepNowTitle,
                l10n.homeStepNowText(today.units),
                _StepState.now,
              ),
              _Step(
                l10n.homeStepPostTag,
                l10n.homeStepPostTitle,
                l10n.homeStepPostText(top.isEmpty ? '' : top.first.name),
                _StepState.next,
              ),
              _Step(
                l10n.homeStepAfterTag,
                l10n.homeStepAfterTitle,
                l10n.homeStepAfterText,
                _StepState.next,
              ),
            ],
          ),
          const SizedBox(height: PPSpace.lg),
          Text(l10n.homeExperiment, style: PPType.title(size: 20)),
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
    await db
        .into(db.swipeFeedback)
        .insertOnConflictUpdate(
          SwipeFeedbackCompanion.insert(trendId: t.id, liked: liked, at: Value(DateTime.now())),
        );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final trends = ref.watch(trendsProvider).valueOrNull ?? const [];
    final swiped = ref.watch(swipedIdsProvider).valueOrNull ?? const {};
    final brand = ref.watch(brandProvider).valueOrNull;
    final ranked = ref
        .watch(recommendationProvider)
        .rank(trends: trends, shopTags: {...?brand?.nicheTags}, swipedIds: swiped);

    if (ranked.isEmpty) {
      return EmptyState(title: l10n.homeCaughtUpTitle, message: l10n.homeCaughtUpMessage);
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
              return TrendCard(
                title: t.title,
                why: t.why,
                badge: l10n.homeRising,
                sources: t.sources,
              );
            },
          ),
        ),
        const SizedBox(height: PPSpace.md),
        Row(
          children: [
            Expanded(
              child: PPButton.secondary(
                label: l10n.homeNotForMe,
                icon: Icons.close_rounded,
                onPressed: () => _controller.swipe(CardSwiperDirection.left),
              ),
            ),
            const SizedBox(width: PPSpace.sm),
            Expanded(
              child: PPButton(
                label: l10n.homeTryIt,
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

enum _StepState { done, now, next }

class _Step {
  const _Step(this.tag, this.title, this.text, this.state);

  final String tag;
  final String title;
  final String text;
  final _StepState state;
}

/// The day as four small steps; the current one is filled teal.
class _DaySteps extends StatelessWidget {
  const _DaySteps({required this.steps});

  final List<_Step> steps;

  @override
  Widget build(BuildContext context) {
    Widget tile(_Step s) {
      final now = s.state == _StepState.now;
      final fg = now ? PPColors.onAccent : PPColors.text;
      return Container(
        constraints: const BoxConstraints(minHeight: 92),
        padding: const EdgeInsets.all(PPSpace.md),
        decoration: BoxDecoration(
          color: now
              ? PPColors.teal
              : s.state == _StepState.done
              ? const Color(0xFF2E2B40)
              : PPColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: now ? PPColors.teal : const Color(0xFF2E2E38)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.tag.toUpperCase(), style: PPType.label(size: 10, color: fg)),
            const SizedBox(height: 4),
            Text(s.title, style: PPType.heading(size: 17).copyWith(color: fg)),
            const SizedBox(height: 4),
            Text(s.text, style: PPType.body(size: 12, color: fg)),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (var i = 0; i < steps.length; i += 2)
          Padding(
            padding: EdgeInsets.only(top: i == 0 ? 0 : PPSpace.sm),
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(child: tile(steps[i])),
                  const SizedBox(width: PPSpace.sm),
                  Expanded(child: tile(steps[i + 1])),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
