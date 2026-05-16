import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static Future<void> init() async {
    tz_data.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone));

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    await _plugin.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: darwinSettings,
      ),
    );

    await _createChannels();
  }

  static Future<void> _createChannels() async {
    final androidPlugin =
        _plugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    final channels = [
      const AndroidNotificationChannel(
        'medication',
        'Medikamente',
        description: 'Erinnerungen für Medikamenteneinnahme',
        importance: Importance.high,
      ),
      const AndroidNotificationChannel(
        'supplement',
        'Supplements',
        description: 'Supplement-Erinnerungen',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'workout',
        'Training',
        description: 'Workout-Erinnerungen',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'water',
        'Wasser',
        description: 'Wasser-Trink-Erinnerungen',
        importance: Importance.low,
      ),
      const AndroidNotificationChannel(
        'habit',
        'Gewohnheiten',
        description: 'Gewohnheits-Check-ins',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'todo',
        'Aufgaben',
        description: 'Fällige Todos',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'period',
        'Zyklus',
        description: 'Periodenvorhersage',
        importance: Importance.defaultImportance,
      ),
      const AndroidNotificationChannel(
        'budget',
        'Budget',
        description: 'Budget-Warnungen',
        importance: Importance.defaultImportance,
      ),
    ];

    for (final channel in channels) {
      await androidPlugin?.createNotificationChannel(channel);
    }
  }

  static Future<void> scheduleDailyAt({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required String channelId,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduledDate,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channelId,
          channelId,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> cancel(int id) => _plugin.cancel(id);

  static Future<void> cancelAll() => _plugin.cancelAll();

  static Future<void> rescheduleAll(Map<String, dynamic> prefs) async {
    await cancelAll();
    // Re-schedule based on prefs
    if (prefs['notif_medication'] == true) {
      final time = (prefs['notif_medication_time'] as String?) ?? '08:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: 1,
        title: 'Medikamente',
        body: 'Zeit für deine Medikamente',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'medication',
      );
    }
    if (prefs['notif_workout'] == true) {
      final time = (prefs['notif_workout_time'] as String?) ?? '18:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: 2,
        title: 'Training',
        body: 'Zeit für dein Workout!',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'workout',
      );
    }
    if (prefs['notif_habit'] == true) {
      final time = (prefs['notif_habit_time'] as String?) ?? '20:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: 3,
        title: 'Gewohnheiten',
        body: 'Hast du deine Gewohnheiten für heute erledigt?',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'habit',
      );
    }
  }
}
