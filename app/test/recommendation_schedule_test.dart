import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:popup_pass/domain/enums.dart';
import 'package:popup_pass/domain/recommendation_schedule.dart';
import 'package:popup_pass/domain/recommendation_service.dart';
import 'package:popup_pass/data/db/database.dart';
import 'package:popup_pass/services/recommendation_schedule_store.dart';

void main() {
  // Friday 2026-11-06 09:30 local.
  final now = DateTime(2026, 11, 6, 9, 30);
  RecommendationSchedule schedule(RecommendationFrequency f, {int hour = 9, int minute = 0}) =>
      RecommendationSchedule(
        anchor: DateTime(2026, 11, 6),
        frequency: f,
        hour: hour,
        minute: minute,
      );

  test('weekly is the default', () {
    expect(RecommendationFrequency.defaultValue, RecommendationFrequency.weekly);
  });

  test('off schedules nothing', () {
    expect(schedule(RecommendationFrequency.off).upcoming(now), isEmpty);
    expect(schedule(RecommendationFrequency.off).enabled, isFalse);
  });

  test('daily lands at the chosen time every day, starting after now', () {
    final times = schedule(RecommendationFrequency.daily, hour: 18, minute: 15).upcoming(now);
    expect(times.first, DateTime(2026, 11, 6, 18, 15));
    expect(times[1], DateTime(2026, 11, 7, 18, 15));
    expect(times, hasLength(14));
  });

  test('a time already passed today starts tomorrow', () {
    final times = schedule(RecommendationFrequency.daily).upcoming(now);
    expect(times.first, DateTime(2026, 11, 7, 9));
  });

  test('weekly keeps the anchor weekday, seven days apart', () {
    final times = schedule(RecommendationFrequency.weekly).upcoming(now);
    expect(times.first, DateTime(2026, 11, 13, 9));
    expect(times.every((t) => t.weekday == DateTime.friday), isTrue);
    expect(times[1].difference(times[0]).inDays, 7);
  });

  test('every two weeks is fourteen days apart', () {
    final times = schedule(RecommendationFrequency.biweekly).upcoming(now);
    expect(times.first, DateTime(2026, 11, 20, 9));
    expect(times[1], DateTime(2026, 12, 4, 9));
  });

  test('an anchor long ago still gives the next on-cadence day', () {
    final s = RecommendationSchedule(
      anchor: DateTime(2026, 1, 2),
      frequency: RecommendationFrequency.biweekly,
    );
    final first = s.upcoming(now).first;
    expect(first.isAfter(now), isTrue);
    expect(first.difference(DateTime(2026, 1, 2, 9)).inDays % 14, 0);
  });

  test('the store round trips the choice and defaults to weekly at 9:00', () async {
    FlutterSecureStorage.setMockInitialValues({});
    final store = RecommendationScheduleStore(const FlutterSecureStorage());
    final fresh = await store.read();
    expect(fresh.frequency, RecommendationFrequency.weekly);
    expect((fresh.hour, fresh.minute), (9, 0));

    await store.write(schedule(RecommendationFrequency.biweekly, hour: 7, minute: 45));
    final saved = await store.read();
    expect(saved.frequency, RecommendationFrequency.biweekly);
    expect((saved.hour, saved.minute), (7, 45));
    expect(saved.anchor, DateTime(2026, 11, 6));
  });

  test('the batch drops swiped cards and is capped', () {
    CachedTrend trend(String id, double score) => CachedTrend(
      id: id,
      keyword: id,
      niche: 'cozy',
      score: score,
      title: id,
      why: '',
      sources: const [],
      snapshotVersion: 'v1',
    );
    final batch = const RecommendationService().batch(
      trends: [for (var i = 0; i < 9; i++) trend('t$i', i.toDouble())],
      shopTags: const {},
      swipedIds: const {'t8'},
      limit: 3,
    );
    expect([for (final t in batch) t.id], ['t7', 't6', 't5']);
  });
}
