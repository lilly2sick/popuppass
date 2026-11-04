import 'package:flutter/material.dart';

import '../tokens.dart';

/// Base surface for every card. Always opaque so the grid never shows
/// through content.
class StickerCard extends StatelessWidget {
  const StickerCard({
    super.key,
    required this.child,
    this.fill = PPColors.card,
    this.padding = const EdgeInsets.all(PPSpace.lg),
    this.radius = PPRadius.card,
    this.shadow = true,
    this.iridescent = false,
    this.onTap,
  });

  final Widget child;
  final Color fill;
  final EdgeInsets padding;
  final double radius;

  /// Kept for call-site compatibility; `false` drops the hairline border.
  final bool shadow;

  /// Hero cards get the violet-pink-teal ring.
  final bool iridescent;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    Widget box = DecoratedBox(
      decoration: PPSurface.decoration(fill: fill, radius: radius, border: shadow && !iridescent),
      child: Padding(padding: padding, child: child),
    );
    if (iridescent) {
      box = DecoratedBox(
        decoration: BoxDecoration(gradient: PPSurface.iridescentGradient, borderRadius: BorderRadius.circular(radius)),
        child: Padding(padding: const EdgeInsets.all(1), child: box),
      );
    }
    if (onTap == null) return box;
    return Semantics(button: true, child: GestureDetector(onTap: onTap, child: box));
  }
}

enum PPButtonKind { primary, secondary, dashed }

class PPButton extends StatelessWidget {
  const PPButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.kind = PPButtonKind.primary,
    this.icon,
    this.height = PPTap.min,
    this.expand = false,
  });

  const PPButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.height = PPTap.min,
    this.expand = false,
  }) : kind = PPButtonKind.secondary;

  final String label;
  final VoidCallback? onPressed;
  final PPButtonKind kind;
  final IconData? icon;
  final double height;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    final (fill, fg) = switch (kind) {
      PPButtonKind.primary => (enabled ? PPColors.violet : PPColors.raised, enabled ? PPColors.onAccent : PPColors.muted),
      PPButtonKind.secondary => (PPColors.raised, enabled ? PPColors.text : PPColors.muted),
      PPButtonKind.dashed => (PPColors.card, PPColors.text),
    };
    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
        onTap: onPressed,
        child: Container(
          height: height,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: PPSpace.lg),
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(PPRadius.button),
            border: kind == PPButtonKind.primary ? null : Border.all(color: PPColors.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: PPSpace.sm)],
              Flexible(child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: PPType.body(color: fg, weight: FontWeight.w800))),
            ],
          ),
        ),
      ),
    );
  }
}

/// Toggle chip, e.g. payment method or filter. Selected = teal.
class PPChip extends StatelessWidget {
  const PPChip({super.key, required this.label, required this.selected, required this.onTap, this.leading});

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: selected ? PPColors.teal : PPColors.raised,
            borderRadius: BorderRadius.circular(PPRadius.chip),
            border: selected ? null : Border.all(color: PPColors.lineStrong),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 6)],
              Text(
                label,
                style: PPType.body(size: 14, weight: FontWeight.w800, color: selected ? PPColors.onAccent : PPColors.text),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

enum PillTone { neutral, warn, good, info }

/// Status pill with a round glyph: "! 3 LEFT", "+ 87% MARGIN".
class PPPill extends StatelessWidget {
  const PPPill(this.text, {super.key, this.tone = PillTone.neutral, this.glyph});

  final String text;
  final PillTone tone;

  /// Single character in the dot. Defaults: warn "!", good "+".
  final String? glyph;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = switch (tone) {
      PillTone.warn => (PPColors.pink, PPColors.onAccent),
      PillTone.good => (PPColors.teal, PPColors.onAccent),
      PillTone.info => (PPColors.lilac, PPColors.onAccent),
      PillTone.neutral => (PPColors.raised, PPColors.text),
    };
    final g = glyph ?? switch (tone) { PillTone.warn => '!', PillTone.good => '+', _ => null };
    return Container(
      height: 26,
      padding: EdgeInsets.fromLTRB(g == null ? 10 : 3, 0, 10, 0),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(PPRadius.chip),
        border: tone == PillTone.neutral ? Border.all(color: PPColors.lineStrong) : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (g != null) ...[
            Container(
              width: 20,
              height: 20,
              alignment: Alignment.center,
              decoration: BoxDecoration(shape: BoxShape.circle, color: tone == PillTone.neutral ? PPColors.card : PPColors.onAccent),
              child: Text(g, style: PPType.body(size: 12, weight: FontWeight.w900, color: tone == PillTone.neutral ? PPColors.text : bg)),
            ),
            const SizedBox(width: 6),
          ],
          Text(text.toUpperCase(), style: PPType.label(color: fg)),
        ],
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.title, required this.message, this.action});

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return StickerCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: PPType.heading()),
          const SizedBox(height: PPSpace.xs),
          Text(message, style: PPType.body(size: 14, color: PPColors.muted)),
          if (action != null) ...[const SizedBox(height: PPSpace.md), action!],
        ],
      ),
    );
  }
}
