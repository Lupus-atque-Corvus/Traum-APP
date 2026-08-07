import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
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

  /// Fixed notification ids for the single, settings-driven daily reminders.
  /// Per-medication reminders (multiple times, multiple medications) use
  /// [medicationReminderId] instead and must not collide with these.
  static const int _medicationGenericId = 1;
  static const int _workoutId = 2;
  static const int _habitId = 3;
  static const int _supplementId = 4;
  static const int _waterId = 5;
  static const int _todoId = 6;
  static const int _periodId = 7;

  /// Deterministic, collision-free notification id for the [timeIndex]-th
  /// scheduled time of medication [medicationId].
  ///
  /// Previously these were scheduled as `100 + timeIndex` — a plain list
  /// index with no reference to which medication it belonged to. Two
  /// medications with reminders at the same time-of-day slot (e.g. both
  /// "morgens") collided on the same notification id, so the second
  /// medication's schedule silently overwrote the first's. Reserves 100
  /// slots per medication (`timeIndex` realistically never exceeds a
  /// handful of daily doses) starting well above the fixed ids above.
  static int medicationReminderId(int medicationId, int timeIndex) =>
      10000 + medicationId * 100 + timeIndex;

  /// Whether the OS currently grants notification permission. Reminders
  /// scheduled while this is false are silently dropped by the platform —
  /// callers should check this and warn the user visibly rather than let
  /// a toggle look like it worked when nothing will ever fire.
  static Future<bool> hasPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

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

  /// Rebuilds every scheduled local notification from scratch: the fixed
  /// settings-driven daily/periodic reminders in [prefs], plus a per-
  /// medication reminder for every active medication's stored intake times
  /// (read fresh from [db] — these must survive a Settings-triggered
  /// reschedule the same way they were originally added, and previously
  /// they didn't: [cancelAll] below wiped them and nothing put them back).
  ///
  /// [prefs] keys: `notif_medication`(+`_time`), `notif_supplement`(+`_time`),
  /// `notif_workout`(+`_time`), `notif_habit`(+`_time`), `notif_todo`(+`_time`),
  /// `notif_water`(+`_interval`, minutes), `notif_period`(+`_days`,
  /// `_next_date` as `DateTime?` — the predicted next period start, or null
  /// if unknown/period tracking disabled).
  static Future<void> rescheduleAll(
    Map<String, dynamic> prefs, {
    required TraumDatabase db,
  }) async {
    await cancelAll();

    if (prefs['notif_medication'] == true) {
      final time = (prefs['notif_medication_time'] as String?) ?? '08:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: _medicationGenericId,
        title: 'Medikamente',
        body: 'Zeit für deine Medikamente',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'medication',
      );
    }
    if (prefs['notif_supplement'] == true) {
      final time = (prefs['notif_supplement_time'] as String?) ?? '09:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: _supplementId,
        title: 'Supplements',
        body: 'Zeit für deine Supplements',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'supplement',
      );
    }
    if (prefs['notif_workout'] == true) {
      final time = (prefs['notif_workout_time'] as String?) ?? '18:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: _workoutId,
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
        id: _habitId,
        title: 'Gewohnheiten',
        body: 'Hast du deine Gewohnheiten für heute erledigt?',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'habit',
      );
    }
    if (prefs['notif_todo'] == true) {
      final time = (prefs['notif_todo_time'] as String?) ?? '07:00';
      final parts = time.split(':');
      await scheduleDailyAt(
        id: _todoId,
        title: 'Aufgaben',
        body: 'Schau nach deinen fälligen Aufgaben',
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
        channelId: 'todo',
      );
    }
    if (prefs['notif_water'] == true) {
      final intervalMinutes = (prefs['notif_water_interval'] as int?) ?? 90;
      // Inexact on purpose: a "drink water" nudge has no reason to demand
      // the SCHEDULE_EXACT_ALARM permission newer Android versions require
      // for exact repeating alarms — being off by a few minutes is fine.
      await _plugin.periodicallyShowWithDuration(
        _waterId,
        'Wasser',
        'Zeit für ein Glas Wasser',
        Duration(minutes: intervalMinutes),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'water',
            'water',
            importance: Importance.low,
            priority: Priority.low,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
    if (prefs['notif_period'] == true) {
      final nextPeriod = prefs['notif_period_next_date'] as DateTime?;
      final daysBefore = (prefs['notif_period_days'] as int?) ?? 3;
      if (nextPeriod != null) {
        final targetDay = nextPeriod.subtract(Duration(days: daysBefore));
        final now = tz.TZDateTime.now(tz.local);
        final scheduledDate = tz.TZDateTime(
          tz.local,
          targetDay.year,
          targetDay.month,
          targetDay.day,
          9,
        );
        // A one-off notification (no matchDateTimeComponents): the target
        // date shifts every cycle, unlike the other, genuinely daily
        // reminders above.
        if (scheduledDate.isAfter(now)) {
          await _plugin.zonedSchedule(
            _periodId,
            'Zyklus',
            'Deine Periode wird in etwa $daysBefore Tagen erwartet',
            scheduledDate,
            const NotificationDetails(
              android: AndroidNotificationDetails(
                'period',
                'period',
                importance: Importance.defaultImportance,
                priority: Priority.defaultPriority,
              ),
              iOS: DarwinNotificationDetails(),
            ),
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            uiLocalNotificationDateInterpretation:
                UILocalNotificationDateInterpretation.absoluteTime,
          );
        }
      }
    }

    final activeMedications = await db.medicationDao.getActiveMedications();
    for (final medication in activeMedications) {
      List<String> times;
      try {
        times = (jsonDecode(medication.timings) as List).cast<String>();
      } catch (_) {
        times = const [];
      }
      for (var i = 0; i < times.length; i++) {
        final parts = times[i].split(':');
        if (parts.length != 2) continue;
        final hour = int.tryParse(parts[0]);
        final minute = int.tryParse(parts[1]);
        if (hour == null || minute == null) continue;
        await scheduleDailyAt(
          id: medicationReminderId(medication.id, i),
          title: medication.name,
          body: 'Zeit für ${medication.name}',
          hour: hour,
          minute: minute,
          channelId: 'medication',
        );
      }
    }
  }
}
