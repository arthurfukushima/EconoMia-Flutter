import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Platform wrapper for local notifications — scheduling and permission.
/// Initialize with [init] once before [runApp]; call [requestPermission] when
/// contextually appropriate; use [scheduleDaily] to add/update, [cancel] to remove.
abstract final class NotificationService {
  static const int _dailyReminderId = 1001;

  static final _notifications = FlutterLocalNotificationsPlugin();

  /// One-time init: timezone setup, Android channel, plugin init.
  /// Call once from [main] before [runApp].
  static Future<void> init() async {
    tz.initializeTimeZones();
    final timezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timezone.identifier));

    const androidChannel = AndroidNotificationChannel(
      'economia_daily',
      'Lembretes diários',
      description: 'Lembretes e notificações do EconoMia',
      importance: Importance.defaultImportance,
    );

    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(androidChannel);

    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
    );
  }

  /// Request notification permission — Android 13+, iOS.
  /// Safe to call multiple times (will skip if already asked).
  static Future<bool> requestPermission() async {
    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    return false;
  }

  /// Schedule a daily notification at [hour]:[minute] (24-hour, local time).
  /// Replaces any existing scheduled notification with the same id.
  static Future<void> scheduleDaily({
    required String title,
    required String body,
    int hour = 18,
    int minute = 0,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final scheduled = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    final when = scheduled.isBefore(now)
        ? scheduled.add(const Duration(days: 1))
        : scheduled;

    await _notifications.zonedSchedule(
      id: _dailyReminderId,
      title: title,
      body: body,
      scheduledDate: when,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'economia_daily',
          'Lembretes diários',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      matchDateTimeComponents: DateTimeComponents.time,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
    );
  }

  /// Cancel any pending scheduled notification with id.
  static Future<void> cancel(int id) async {
    await _notifications.cancel(id: id);
  }

  /// Cancel the daily reminder specifically.
  static Future<void> cancelDaily() async {
    await cancel(_dailyReminderId);
  }
}
