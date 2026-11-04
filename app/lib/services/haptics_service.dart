import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Semantic haptic moments. Screens say what happened, not how to buzz.
enum HapticMoment { sold, undo, lowStock, soldOut, selection, error, success }

/// Primitive feedback kinds. The first four map to Flutter's HapticFeedback.
/// The last three are notification feedback, played natively when a platform
/// channel is present (iOS UINotificationFeedbackGenerator, Android
/// HapticFeedbackConstants CONFIRM/REJECT on API 30+) and composed from
/// impacts otherwise.
enum HapticKind { selection, light, medium, heavy, success, warning, error }

/// SPEC 12 table: which primitive(s) each moment plays, in order.
const Map<HapticMoment, List<HapticKind>> hapticPatterns = {
  HapticMoment.sold: [HapticKind.medium],
  HapticMoment.undo: [HapticKind.light],
  HapticMoment.lowStock: [HapticKind.warning],
  HapticMoment.soldOut: [HapticKind.heavy, HapticKind.heavy],
  HapticMoment.selection: [HapticKind.selection],
  HapticMoment.error: [HapticKind.error],
  HapticMoment.success: [HapticKind.success],
};

/// Impact sequences used when native notification feedback is unavailable.
const Map<HapticKind, List<HapticKind>> hapticFallbacks = {
  HapticKind.success: [HapticKind.light, HapticKind.medium],
  HapticKind.warning: [HapticKind.medium, HapticKind.light],
  HapticKind.error: [HapticKind.heavy, HapticKind.heavy, HapticKind.heavy],
};

class HapticsService {
  HapticsService({this.enabled = true, this.intensity = 1.0, MethodChannel? channel})
    : _channel = channel ?? const MethodChannel(channelName);

  static const channelName = 'com.popuppass/haptics';

  /// User settings: on/off and 0..1 intensity (some vendors lay the phone flat).
  bool enabled;
  double intensity;

  final MethodChannel _channel;

  Future<void> play(HapticMoment m) async {
    if (!enabled) return;
    final kinds = hapticPatterns[m]!;
    for (var i = 0; i < kinds.length; i++) {
      if (i > 0) await _gap();
      await _play(kinds[i]);
    }
  }

  Future<void> _play(HapticKind k) async {
    switch (k) {
      case HapticKind.selection:
        await HapticFeedback.selectionClick();
      case HapticKind.light:
        await HapticFeedback.lightImpact();
      case HapticKind.medium:
        await HapticFeedback.mediumImpact();
      case HapticKind.heavy:
        await HapticFeedback.heavyImpact();
      case HapticKind.success || HapticKind.warning || HapticKind.error:
        if (await _native(k)) return;
        final seq = hapticFallbacks[k]!;
        for (var i = 0; i < seq.length; i++) {
          if (i > 0) await _gap(k == HapticKind.error ? 60 : 90);
          await _play(seq[i]);
        }
    }
  }

  /// Returns true if the platform handled it.
  Future<bool> _native(HapticKind k) async {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.iOS &&
            defaultTargetPlatform != TargetPlatform.android)) {
      return false;
    }
    try {
      final handled = await _channel.invokeMethod<bool>('notify', {
        'type': k.name,
        'intensity': intensity,
      });
      return handled ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  Future<void> _gap([int ms = 90]) => Future<void>.delayed(Duration(milliseconds: ms));
}
