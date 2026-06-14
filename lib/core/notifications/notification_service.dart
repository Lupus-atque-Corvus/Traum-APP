import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/database/traum_database.dart';

/// Action id for the "Genommen" (taken) button on medication reminders.
const String kMedTakenActionId = 'med_taken';

/// Marks the next due dose of each active medication as taken for today.
///
/// Opens its own [TraumDatabase] so it works from a background isolate
/// (same pattern as [widgetWorkmanagerDispatcher]).
Future<void> markMedicationsTakenFromNotification() async {
  final db = TraumDatabase();
  try {
    final meds = await db.medicationDao.getActiveMedications();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final logs = await db.medicationDao.watchLogsForDate(todayStart).first;
    for (final med in meds) {
      List<String> times;
      try {
        times = (jsonDecode(med.timings) as List).cast<String>();
      } catch (_) {
        times = const [];
      }
      if (times.isEmpty) continue;
      final takenCount =
          logs.where((l) => l.medicationId == med.id && l.taken).length;
      if (takenCount >= times.length) continue;
      final parts = times[takenCount].split(':');
      var sched = DateTime(now.year, now.month, now.day);
      if (parts.length == 2) {
        sched = DateTime(now.year, now.month, now.day,
            int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
      }
      await db.medicationDao.insertLog(MedicationLogsCompanion.insert(
        medicationId: med.id,
        scheduledAt: sched,
        takenAt: Value(now),
        taken: const Value(true),
      ));
    }
  } catch (_) {
    // Never let a notification action crash the isolate.
  } finally {
    await db.close();
  }
}

/// Background (terminated/background app) notification-response handler.
/// Must be top-level + `@pragma('vm:entry-point')` so AOT keeps it.
@pragma('vm:entry-point')
void notificationTapBackground(NotificationResponse response) {
  if (response.actionId == kMedTakenActionId) {
    markMedicationsTakenFromNotification();
  }
}

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
      onDidReceiveNotificationResponse: _onNotificationResponse,
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
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

    final isMedication = channelId == 'medication';
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
          actions: isMedication
              ? <AndroidNotificationAction>[
                  const AndroidNotificationAction(
                    kMedTakenActionId,
                    'Genommen',
                    showsUserInterface: false,
                  ),
                ]
              : null,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: isMedication ? kMedTakenActionId : null,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  /// Foreground notification-response handler (app running).
  static void _onNotificationResponse(NotificationResponse response) {
    if (response.actionId == kMedTakenActionId) {
      markMedicationsTakenFromNotification();
    }
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
