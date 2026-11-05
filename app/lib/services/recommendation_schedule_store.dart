import 'package:clock/clock.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../domain/enums.dart';
import '../domain/recommendation_schedule.dart';

/// Persists the user's [RecommendationSchedule] choice.
class RecommendationScheduleStore {
  RecommendationScheduleStore(this.storage);

  final FlutterSecureStorage storage;

  static const _frequencyKey = 'recommendation.frequency';
  static const _hourKey = 'recommendation.hour';
  static const _minuteKey = 'recommendation.minute';
  static const _anchorKey = 'recommendation.anchor';

  Future<RecommendationSchedule> read() async {
    final name = await storage.read(key: _frequencyKey);
    final frequency = RecommendationFrequency.values.firstWhere(
      (f) => f.name == name,
      orElse: () => RecommendationFrequency.defaultValue,
    );
    final hour = int.tryParse(await storage.read(key: _hourKey) ?? '') ?? 9;
    final minute = int.tryParse(await storage.read(key: _minuteKey) ?? '') ?? 0;
    final anchor = DateTime.tryParse(await storage.read(key: _anchorKey) ?? '') ?? clock.now();
    return RecommendationSchedule(frequency: frequency, hour: hour, minute: minute, anchor: anchor);
  }

  Future<void> write(RecommendationSchedule s) => Future.wait([
    storage.write(key: _frequencyKey, value: s.frequency.name),
    storage.write(key: _hourKey, value: '${s.hour}'),
    storage.write(key: _minuteKey, value: '${s.minute}'),
    storage.write(key: _anchorKey, value: s.anchor.toIso8601String()),
  ]);
}
