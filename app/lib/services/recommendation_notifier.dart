import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Delivers the SPEC 16 recommendation reminder. No server push: the batch is
/// built from the cached trend feed, so this works fully offline.
abstract interface class RecommendationNotifier {
  /// Prepare the platform. [onOpen] runs when the user taps a notification.
  Future<void> init({required VoidCallback onOpen});

  /// Replace everything pending with one notification per entry in [times]
  /// (local time). An empty list cancels them all.
  Future<void> replaceAll(List<DateTime> times, {required String title, required String body});
}

/// Real implementation on `flutter_local_notifications`.
class LocalRecommendationNotifier implements RecommendationNotifier {
  LocalRecommendationNotifier({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// Ids _firstId .. _firstId + _maxQueued are reserved for this feature.
  static const _firstId = 1601;
  static const _maxQueued = 32;
  static const channelId = 'recommendations';

  @override
  Future<void> init({required VoidCallback onOpen}) async {
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
      onDidReceiveNotificationResponse: (_) => onOpen(),
    );
  }

  Future<void> _requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  @override
  Future<void> replaceAll(
    List<DateTime> times, {
    required String title,
    required String body,
  }) async {
    for (var i = 0; i < _maxQueued; i++) {
      await _plugin.cancel(id: _firstId + i);
    }
    if (times.isEmpty) return;
    await _requestPermission();
    for (var i = 0; i < times.length && i < _maxQueued; i++) {
      await _plugin.zonedSchedule(
        id: _firstId + i,
        title: title,
        body: body,
        // The instant is exact whatever the device zone, so UTC is enough and
        // no native timezone lookup is needed.
        scheduledDate: tz.TZDateTime.from(times[i], tz.UTC),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            channelId,
            'New ideas',
            channelDescription: 'Fresh post and restock ideas from your trend board.',
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// Records what would have been scheduled. Used with USE_FAKES and in tests.
class FakeRecommendationNotifier implements RecommendationNotifier {
  List<DateTime> scheduled = const [];
  String? lastTitle;
  String? lastBody;
  VoidCallback? onOpen;

  @override
  Future<void> init({required VoidCallback onOpen}) async => this.onOpen = onOpen;

  @override
  Future<void> replaceAll(
    List<DateTime> times, {
    required String title,
    required String body,
  }) async {
    scheduled = times;
    lastTitle = title;
    lastBody = body;
  }
}
