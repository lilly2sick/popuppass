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
import '../../design/components/swinging_pass.dart';
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

    // Bottom of the ranking, valued after the cost of everything stocked.
    Product? slow;
    var slowNet = 0;
    if (products.length > top.length && favs.isNotEmpty) {
      slow = favs.last;
      final unitsSold = sold[slow.id] ?? 0;
      final stocked = (stock[slow.id] ?? 0) + unitsSold;
      slowNet = unitsSold * slow.priceCents - stocked * slow.unitCostCents;
    }

    return PPScaffold(
      title: l10n.homeTitle,
      searchHint: l10n.homeSearchHint,
      hero: _Hero(onOpenTable: () => context.go(AppTab.sell.path)),
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
            const SizedBox(height: PPSpace.lg),
            StickerCard(
              iridescent: true,
              fill: PPColors.surface,
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: PPColors.pink,
                        ),
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
                      Text(l10n.homeJustNow, style: PPType.label(size: 10, color: PPColors.muted)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: _AlertButton(
                          label: l10n.homeGoToMyTable,
                          onTap: () => context.go(AppTab.sell.path),
                        ),
                      ),
                      const SizedBox(width: PPSpace.sm),
                      Expanded(
                        child: _AlertButton(
                          label: l10n.homeRestockNote,
                          onTap: () => context.go(AppTab.shop.path),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
          if (top.isNotEmpty) ...[
            const SizedBox(height: PPSpace.lg),
            StickerCard(
              radius: 20,
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Expanded(child: Text(l10n.homeFanFavorites, style: PPType.title(size: 20))),
                      GestureDetector(
                        onTap: () => context.go(AppTab.insights.path),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: PPTap.min),
                          child: Align(
                            widthFactor: 1,
                            alignment: Alignment.centerRight,
                            child: Text(
                              l10n.homeSeeAll,
                              style: PPType.body(
                                size: 13,
                                weight: FontWeight.w700,
                                color: PPColors.violet,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
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
                  if (slow != null) ...[
                    const SizedBox(height: PPSpace.sm),
                    const Divider(height: 1, color: PPColors.line),
                    const SizedBox(height: PPSpace.sm),
                    Row(
                      children: [
                        Text(
                          l10n.homeNotSoPopular,
                          style: PPType.body(
                            size: 13,
                            weight: FontWeight.w800,
                            color: PPColors.muted,
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text.rich(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            TextSpan(
                              style: PPType.body(size: 13),
                              children: [
                                TextSpan(
                                  text: slow.name,
                                  style: PPType.body(size: 13, weight: FontWeight.w800),
                                ),
                                TextSpan(
                                  text: ' ${l10n.homeAfterCost(Money.signed(slowNet))}',
                                  style: PPType.body(
                                    size: 13,
                                    color: slowNet < 0 ? PPColors.pink : PPColors.teal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
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

  /// Cards handled this session, for the "N OF M" count.
  int _done = 0;

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
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.homeExperiment, style: PPType.title(size: 20)),
          const SizedBox(height: PPSpace.sm),
          EmptyState(title: l10n.homeCaughtUpTitle, message: l10n.homeCaughtUpMessage),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text(l10n.homeExperiment, style: PPType.title(size: 20))),
            Text(
              l10n.homeDeckCount(_done + 1, ranked.length + _done),
              style: PPType.label(size: 11, color: PPColors.muted),
            ),
          ],
        ),
        const SizedBox(height: PPSpace.sm),
        SizedBox(
          height: 236,
          child: CardSwiper(
            controller: _controller,
            cardsCount: ranked.length,
            numberOfCardsDisplayed: ranked.length.clamp(1, 2),
            isLoop: false,
            padding: EdgeInsets.zero,
            onSwipe: (i, _, dir) {
              _record(ranked[i], dir == CardSwiperDirection.right);
              setState(() => _done++);
              return true;
            },
            cardBuilder: (context, i, _, __) {
              final t = ranked[i];
              return TrendCard(title: t.title, why: t.why, badge: l10n.homeRising, niche: t.niche);
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

/// Greeting, primary action and the swinging pass (Home artboard hero).
class _Hero extends StatelessWidget {
  const _Hero({required this.onOpenTable});

  final VoidCallback onOpenTable;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.homeEyebrow.toUpperCase(), style: PPType.label(color: PPColors.violet)),
                const SizedBox(height: 8),
                Text(l10n.homeHeroGreeting, style: PPType.title(size: 34).copyWith(height: 0.98)),
                const SizedBox(height: 8),
                Text(l10n.homeHeroSubtitle, style: PPType.body(size: 14, color: PPColors.muted)),
                const SizedBox(height: 12),
                PPButton(
                  label: l10n.homeOpenTable,
                  icon: Icons.arrow_forward_rounded,
                  onPressed: onOpenTable,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: PPSpace.md),
        const SwingingPass(),
      ],
    );
  }
}

class _AlertButton extends StatelessWidget {
  const _AlertButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: PPColors.raised,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: PPColors.lineStrong),
          ),
          child: Text(label, style: PPType.body(size: 14, weight: FontWeight.w700)),
        ),
      ),
    );
  }
}
