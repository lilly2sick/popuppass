import 'package:flutter/material.dart';

import '../../domain/money.dart';
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
    final pill = soldOut
        ? const PPPill('Sold out', glyph: 'x')
        : low
            ? PPPill('$inStock left', tone: PillTone.warn)
            : PPPill('$inStock in stock', glyph: '#');
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
                    Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: PPType.body(size: 14, weight: FontWeight.w800)),
                    Text('${Money.format(priceCents)} / sold $soldCount', style: PPType.body(size: 12, color: PPColors.muted)),
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
                label: 'Remove one $name sale',
                child: SizedBox(
                  width: 52,
                  child: PPButton.secondary(label: '-1', onPressed: onUnsell, height: PPTap.sell),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Semantics(
                  label: 'Sell one $name',
                  child: PPButton(label: soldOut ? 'Sold out' : '+1 sold', onPressed: soldOut ? null : onSell, height: PPTap.sell),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class TrendCard extends StatelessWidget {
  const TrendCard({
    super.key,
    required this.title,
    required this.why,
    required this.badge,
    required this.sources,
  });

  final String title;
  final String why;
  final String badge;
  final List<String> sources;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      iridescent: true,
      fill: PPColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          PPPill(badge, tone: PillTone.good),
          const SizedBox(height: PPSpace.sm),
          Text(title, style: PPType.title(size: 21)),
          const SizedBox(height: PPSpace.xs),
          Text(why, style: PPType.body(size: 13, color: PPColors.muted)),
          const Spacer(),
          Text('Sources: ${sources.join(', ')}'.toUpperCase(), style: PPType.label(size: 9, color: PPColors.muted)),
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
          child: Container(height: 10, decoration: BoxDecoration(color: PPColors.raised, borderRadius: BorderRadius.circular(6))),
        );
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('AI version writing. Keep working.'.toUpperCase(), style: PPType.label(color: PPColors.violet)),
          const SizedBox(height: PPSpace.sm),
          bar(1),
          const SizedBox(height: PPSpace.sm),
          bar(0.7),
        ],
      ),
    );
  }
}
