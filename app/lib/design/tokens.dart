import 'package:flutter/material.dart';

/// Design tokens. Mirrors the "UI system" artboard on the design canvas.
///
/// Black ground with a light grid and an iridescent shimmer. Pastel violet,
/// pink and teal are reserved for things you tap or toggle, and always carry
/// [onAccent] text. Teal = up / on / profit. Pink = low / down / Sell badge.
/// Direction is never shown by color alone: add a sign or an icon.
abstract final class PPColors {
  static const bg = Color(0xFF0B0B0F);
  static const surface = Color(0xFF15151B);
  static const card = Color(0xFF1C1C24);
  static const raised = Color(0xFF24242E);
  static const line = Color(0x1AFFFFFF);
  static const lineStrong = Color(0x38FFFFFF);
  /// Kept very dim so numbers and copy stay easy to read over it.
  static const grid = Color(0x06FFFFFF);

  static const text = Color(0xFFF5F4FA);
  static const muted = Color(0xFFA9A7B8);
  static const onAccent = Color(0xFF0B0B0F);

  static const violet = Color(0xFFB9A6FF);
  static const violetSoft = Color(0x29B9A6FF);
  static const pink = Color(0xFFFF9AD5);
  static const pinkSoft = Color(0x29FF9AD5);
  static const teal = Color(0xFF7FE7D9);
  static const tealSoft = Color(0x297FE7D9);
  static const lilac = Color(0xFFD9CCFF);

  static const iridescent = [violet, pink, teal, Color(0xFF9C8CFF), violet];
  static const badgeGradient = [Color(0xFFD9CCFF), Color(0xFFFFD6EE), Color(0xFFCFF6F0)];
}

abstract final class PPSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const gutter = 16.0;
}

abstract final class PPRadius {
  static const chip = 999.0;
  static const button = 16.0;
  static const tile = 18.0;
  static const card = 22.0;
}

/// Minimum tap targets. Sell uses [sell].
abstract final class PPTap {
  static const min = 48.0;
  static const sell = 56.0;
}

/// Card surfaces: hairline border, or an iridescent ring for hero cards.
abstract final class PPSurface {
  static const borderWidth = 1.0;

  static BoxDecoration decoration({
    Color fill = PPColors.card,
    double radius = PPRadius.card,
    bool border = true,
    bool dashed = false,
  }) {
    return BoxDecoration(
      color: dashed ? Colors.transparent : fill,
      borderRadius: BorderRadius.circular(radius),
      border: border || dashed ? Border.all(color: dashed ? PPColors.lineStrong : PPColors.line, width: borderWidth) : null,
    );
  }

  static const iridescentGradient = LinearGradient(
    begin: Alignment(-1, -0.6),
    end: Alignment(1, 0.6),
    colors: [PPColors.violet, PPColors.pink, PPColors.teal],
  );
}

/// Ronzino for display and numbers, BDO Grotesk for body and labels.
abstract final class PPType {
  static const display = 'Ronzino';
  static const support = 'BDOGrotesk';

  static TextStyle number({double size = 56, Color color = PPColors.text}) => TextStyle(
        fontFamily: display,
        fontSize: size,
        fontWeight: FontWeight.w700,
        height: 1,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle title({double size = 28, Color color = PPColors.text}) =>
      TextStyle(fontFamily: display, fontSize: size, fontWeight: FontWeight.w700, height: 1.05, color: color);

  static TextStyle heading({double size = 20, Color color = PPColors.text}) =>
      TextStyle(fontFamily: display, fontSize: size, fontWeight: FontWeight.w500, color: color);

  /// BDO Grotesk is a variable font: weight goes through the wght axis.
  static TextStyle body({double size = 16, Color color = PPColors.text, FontWeight weight = FontWeight.w400}) => TextStyle(
        fontFamily: support,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color,
        height: 1.4,
      );

  static TextStyle label({double size = 11, Color color = PPColors.text}) => TextStyle(
        fontFamily: support,
        fontSize: size,
        fontWeight: FontWeight.w800,
        fontVariations: const [FontVariation('wght', 850)],
        letterSpacing: size * 0.14,
        color: color,
      );
}
