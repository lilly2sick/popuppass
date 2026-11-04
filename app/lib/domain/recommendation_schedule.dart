import 'enums.dart';

/// User choice for SPEC 16's recommendation schedule: how often plus what
/// time of day the local notification fires. Weekly and every-two-weeks
/// schedules land on the weekday of [anchor], the day the schedule was set.
class RecommendationSchedule {
  const RecommendationSchedule({
    required this.anchor,
    this.frequency = RecommendationFrequency.defaultValue,
    this.hour = 9,
    this.minute = 0,
  });

  final RecommendationFrequency frequency;

  /// Time of day the notification is due, 24h local time.
  final int hour;
  final int minute;

  /// Calendar day the cadence counts from (time of day ignored).
  final DateTime anchor;

  bool get enabled => frequency != RecommendationFrequency.off;

  RecommendationSchedule copyWith({
    RecommendationFrequency? frequency,
    int? hour,
    int? minute,
    DateTime? anchor,
  }) => RecommendationSchedule(
    frequency: frequency ?? this.frequency,
    hour: hour ?? this.hour,
    minute: minute ?? this.minute,
    anchor: anchor ?? this.anchor,
  );

  /// How many upcoming times are queued ahead. Local notifications cannot
  /// repeat every two weeks, so the next few are scheduled and the list is
  /// rebuilt whenever the app starts or the setting changes.
  int get lookahead => switch (frequency) {
    RecommendationFrequency.off => 0,
    RecommendationFrequency.daily => 14,
    RecommendationFrequency.weekly => 8,
    RecommendationFrequency.biweekly => 6,
  };

  /// The next [lookahead] times strictly after [now]. Day arithmetic is done
  /// on the calendar so daylight saving changes never shift the hour.
  List<DateTime> upcoming(DateTime now) {
    final step = frequency.intervalDays;
    if (step == null) return const [];
    DateTime at(int days) => DateTime(anchor.year, anchor.month, anchor.day + days, hour, minute);
    final today = DateTime(now.year, now.month, now.day);
    final sinceAnchor = today.difference(DateTime(anchor.year, anchor.month, anchor.day)).inDays;
    var k = sinceAnchor <= 0 ? 0 : (sinceAnchor ~/ step) - 1;
    if (k < 0) k = 0;
    while (!at(k * step).isAfter(now)) {
      k++;
    }
    return [for (var i = 0; i < lookahead; i++) at((k + i) * step)];
  }
}
