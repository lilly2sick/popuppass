import 'package:flutter/material.dart';

import 'tokens.dart';

abstract final class PPTheme {
  static ThemeData dark() {
    const scheme = ColorScheme.dark(
      primary: PPColors.violet,
      onPrimary: PPColors.onAccent,
      secondary: PPColors.teal,
      onSecondary: PPColors.onAccent,
      tertiary: PPColors.pink,
      onTertiary: PPColors.onAccent,
      surface: PPColors.surface,
      onSurface: PPColors.text,
      error: PPColors.pink,
      onError: PPColors.onAccent,
    );
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(PPRadius.button),
      borderSide: const BorderSide(color: PPColors.lineStrong),
    );
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: PPColors.bg,
      fontFamily: PPType.support,
      textTheme: TextTheme(
        displayLarge: PPType.number(),
        headlineMedium: PPType.title(),
        titleMedium: PPType.heading(),
        bodyMedium: PPType.body(),
        labelSmall: PPType.label(),
      ),
      materialTapTargetSize: MaterialTapTargetSize.padded,
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: PPColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          side: BorderSide(color: PPColors.lineStrong),
        ),
        showDragHandle: true,
        dragHandleColor: PPColors.lineStrong,
      ),
      dialogTheme: const DialogThemeData(backgroundColor: PPColors.surface),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: PPColors.raised,
        contentTextStyle: PPType.body(size: 14),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? PPColors.onAccent : PPColors.muted),
        trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? PPColors.teal : PPColors.raised),
      ),
      sliderTheme: const SliderThemeData(activeTrackColor: PPColors.violet, thumbColor: PPColors.violet),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: PPColors.bg,
        labelStyle: PPType.body(size: 14, color: PPColors.muted),
        border: border,
        enabledBorder: border,
        focusedBorder: border.copyWith(borderSide: const BorderSide(color: PPColors.violet, width: 2)),
      ),
    );
  }
}
