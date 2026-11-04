import 'package:flutter/services.dart';

/// Semantic haptic moments. Screens say what happened, not how to buzz.
enum HapticMoment { sold, undo, lowStock, soldOut, selection, error, success }

class HapticsService {
  HapticsService({this.enabled = true, this.intensity = 1.0});

  /// User settings: on/off and 0..1 intensity (some vendors lay the phone flat).
  bool enabled;
  double intensity;

  Future<void> play(HapticMoment m) async {
    if (!enabled) return;
    // TODO(haptics): route success/warning/error to UINotificationFeedbackGenerator
    // on iOS and HapticFeedbackConstants.CONFIRM/REJECT on Android 11+ via a
    // small platform channel. Until then, compose from Flutter's impacts.
    switch (m) {
      case HapticMoment.sold:
        await _impact(medium: true);
      case HapticMoment.undo:
        await HapticFeedback.lightImpact();
      case HapticMoment.selection:
        await HapticFeedback.selectionClick();
      case HapticMoment.lowStock:
        await _impact(medium: true);
        await _gap();
        await HapticFeedback.lightImpact();
      case HapticMoment.soldOut:
        await HapticFeedback.heavyImpact();
        await _gap();
        await HapticFeedback.heavyImpact();
      case HapticMoment.error:
        for (var i = 0; i < 3; i++) {
          await HapticFeedback.heavyImpact();
          await _gap(60);
        }
      case HapticMoment.success:
        await HapticFeedback.lightImpact();
        await _gap();
        await _impact(medium: true);
    }
  }

  Future<void> _impact({required bool medium}) => intensity < 0.4
      ? HapticFeedback.lightImpact()
      : (intensity > 0.8 && !medium ? HapticFeedback.heavyImpact() : HapticFeedback.mediumImpact());

  Future<void> _gap([int ms = 90]) => Future<void>.delayed(Duration(milliseconds: ms));
}
