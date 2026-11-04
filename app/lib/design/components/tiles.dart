import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../../l10n/app_localizations.dart';
import '../tokens.dart';
import 'sticker.dart';

/// Sell-screen tile: -1 to fix a double tap, +1 to log a sale.
class ProductTile extends StatelessWidget {
  const ProductTile({
    super.key,
    required this.name,
    required this.priceCents,
    required this.inStock,
    required this.soldCount,
    required this.lowThreshold,
    required this.onSell,
    required this.onUnsell,
    this.image,
  });

  final String name;
  final int priceCents;
  final int inStock;
  final int soldCount;
  final int lowThreshold;
  final VoidCallback onSell;

  /// Null when there is nothing to take back.
  final VoidCallback? onUnsell;
  final ImageProvider? image;

  bool get soldOut => inStock <= 0;
  bool get low => !soldOut && inStock <= lowThreshold;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final pill = soldOut
        ? PPPill(l10n.sellSoldOut, glyph: 'x')
        : low
        ? PPPill(l10n.shopLeft(inStock), tone: PillTone.warn)
        : PPPill(l10n.shopInStock(inStock), glyph: '#');
    return StickerCard(
      padding: const EdgeInsets.all(10),
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(11),
                  gradient: const LinearGradient(colors: PPColors.badgeGradient),
                  image: image == null ? null : DecorationImage(image: image!, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: PPSpace.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PPType.body(size: 14, weight: FontWeight.w800),
                    ),
                    Text(
                      l10n.sellPriceSold(Money.format(priceCents), soldCount),
                      style: PPType.body(size: 12, color: PPColors.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: PPSpace.sm),
          Align(alignment: Alignment.centerLeft, child: pill),
          const SizedBox(height: PPSpace.sm),
          Row(
            children: [
              Semantics(
                label: l10n.sellRemoveOneSale(name),
                child: SizedBox(
                  width: 52,
                  child: PPButton.secondary(
                    label: l10n.sellMinus1,
                    onPressed: onUnsell,
                    height: PPTap.sell,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: l10n.sellSellOne(name),
                  child: PPButton(
                    label: soldOut ? l10n.sellSoldOut : l10n.sellOneSold,
                    onPressed: soldOut ? null : onSell,
                    height: PPTap.sell,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Home deck card: moodboard header, status pills, idea title and the reason
/// it was picked. Matches the "Room to experiment" artboard.
class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.title,
    required this.why,
    required this.badge,
    required this.niche,
  });

  final String title;
  final String why;
  final String badge;
  final String niche;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return StickerCard(
      iridescent: true,
      fill: PPColors.surface,
      radius: 24,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 82,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: PPColors.badgeGradient,
              ),
            ),
            child: Text(
              l10n.homeTrendMoodboard,
              style: PPType.label(size: 12, color: PPColors.onAccent),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              PPPill(badge, tone: PillTone.good, glyph: '+'),
              const SizedBox(width: 6),
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: PPColors.raised,
                  borderRadius: BorderRadius.circular(PPRadius.chip),
                  border: Border.all(color: PPColors.lineStrong),
                ),
                child: Text(niche.toUpperCase(), style: PPType.label(size: 10)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis, style: PPType.title(size: 21)),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              why,
              overflow: TextOverflow.ellipsis,
              style: PPType.body(size: 13, color: PPColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Placeholder while an AI job runs. Never blocks: the user keeps working.
class PendingAi extends StatelessWidget {
  const PendingAi({super.key});

  @override
  Widget build(BuildContext context) {
    Widget bar(double f) => FractionallySizedBox(
      widthFactor: f,
      child: Container(
        height: 10,
        decoration: BoxDecoration(color: PPColors.raised, borderRadius: BorderRadius.circular(6)),
      ),
    );
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalizations.of(context).aiPendingCaption,
            style: PPType.label(color: PPColors.violet),
          ),
          const SizedBox(height: PPSpace.sm),
          bar(1),
          const SizedBox(height: PPSpace.sm),
          bar(0.7),
        ],
      ),
    );
  }
}
