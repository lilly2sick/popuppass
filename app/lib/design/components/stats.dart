import 'package:flutter/material.dart';

import '../../domain/money.dart';
import '../tokens.dart';
import 'sticker.dart';

/// The big +/- money card. Direction is shown by sign and arrow as well as
/// color.
class MoneyDelta extends StatelessWidget {
  const MoneyDelta({super.key, required this.cents, required this.caption, this.eyebrow, this.large = false});

  final int cents;
  final String caption;
  final String? eyebrow;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final up = cents >= 0;
    final badge = large ? 60.0 : 44.0;
    return StickerCard(
      iridescent: true,
      fill: PPColors.surface,
      child: Row(
        children: [
          Container(
            width: badge,
            height: badge,
            decoration: BoxDecoration(shape: BoxShape.circle, color: up ? PPColors.teal : PPColors.pink),
            child: Icon(up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded, color: PPColors.onAccent, size: badge / 2),
          ),
          const SizedBox(width: PPSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null) Text(eyebrow!.toUpperCase(), style: PPType.label(size: 10, color: PPColors.muted)),
                Text(Money.signed(cents), style: PPType.number(size: large ? 48 : 34)),
                Text(caption, style: PPType.body(size: 13, color: PPColors.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Compact tile whose value fills the box. A [unit] ("items") renders small
/// next to the value so long values never overflow.
class StatCard extends StatelessWidget {
  const StatCard({super.key, required this.label, required this.value, this.unit, this.warn = false, this.onTap});

  final String label;
  final String value;
  final String? unit;
  final bool warn;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = warn ? PPColors.onAccent : PPColors.text;
    return SizedBox(
      height: 76,
      child: StickerCard(
        onTap: onTap,
        radius: 16,
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        fill: warn ? PPColors.pink : PPColors.card,
        shadow: !warn,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${warn ? '! ' : ''}${label.toUpperCase()}', style: PPType.label(size: 10, color: warn ? fg : PPColors.muted)),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.bottomLeft,
              child: Text.rich(
                TextSpan(children: [
                  TextSpan(text: value, style: PPType.number(size: 30, color: fg)),
                  if (unit != null) TextSpan(text: ' $unit', style: PPType.body(size: 14, weight: FontWeight.w700, color: fg)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
