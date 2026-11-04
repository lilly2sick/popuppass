import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/services/haptics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('pattern table matches SPEC 12', () {
    expect(hapticPatterns[HapticMoment.sold], [HapticKind.medium]);
    expect(hapticPatterns[HapticMoment.undo], [HapticKind.light]);
    expect(hapticPatterns[HapticMoment.lowStock], [HapticKind.warning]);
    expect(hapticPatterns[HapticMoment.soldOut], [HapticKind.heavy, HapticKind.heavy]);
    expect(hapticPatterns[HapticMoment.selection], [HapticKind.selection]);
    expect(hapticPatterns[HapticMoment.error], [HapticKind.error]);
    expect(hapticPatterns[HapticMoment.success], [HapticKind.success]);
    expect(hapticPatterns.keys.toSet(), HapticMoment.values.toSet());
  });

  test('every notification kind has an impact fallback', () {
    for (final k in [HapticKind.success, HapticKind.warning, HapticKind.error]) {
      expect(hapticFallbacks[k], isNotEmpty);
      expect(
        hapticFallbacks[k]!.any((f) => hapticFallbacks.containsKey(f)),
        isFalse,
        reason: 'fallbacks must be plain impacts',
      );
    }
  });

  group('playback', () {
    final played = <String>[];

    setUp(() {
      played.clear();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'HapticFeedback.vibrate') played.add(call.arguments as String);
          return null;
        },
      );
    });

    test('sold is a medium impact, soldOut is heavy twice', () async {
      final h = HapticsService();
      await h.play(HapticMoment.sold);
      await h.play(HapticMoment.soldOut);
      expect(played, [
        'HapticFeedbackType.mediumImpact',
        'HapticFeedbackType.heavyImpact',
        'HapticFeedbackType.heavyImpact',
      ]);
    });

    test('error composes three heavy impacts off device', () async {
      await HapticsService().play(HapticMoment.error);
      expect(played, List.filled(3, 'HapticFeedbackType.heavyImpact'));
    });

    test('disabled plays nothing', () async {
      await HapticsService(enabled: false).play(HapticMoment.sold);
      expect(played, isEmpty);
    });
  });
}
