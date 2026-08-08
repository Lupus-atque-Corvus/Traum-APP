import 'package:drift/drift.dart' show Value;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../data/database/traum_database.dart';
import 'reminder_time.dart';

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
      final times = parseReminderTimes(med.timings);
      if (times.isEmpty) continue;
      final takenCount =
          logs.where((l) => l.medicationId == med.id && l.taken).length;
      if (takenCount >= times.length) continue;
      final parts = times[takenCount].time.split(':');
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
  /// Per-medication/-supplement reminders use [medicationReminderId]/
  /// [supplementReminderId] instead and must not collide with these.
  /// (Ids 1 and 4 are intentionally retired, not reused — they were the old
  /// blanket "Medikamente"/"Supplements" reminders, replaced entirely by
  /// per-item reminders.)
  static const int _workoutId = 2;
  static const int _habitId = 3;
  static const int _waterId = 5;
  static const int _todoId = 6;
  static const int _periodId = 7;

  /// Deterministic, collision-free notification id for the [timeIndex]-th
  /// scheduled time of medication [medicationId]. [weekday] is 0 for an
  /// every-day reminder (single daily repeat), or an ISO weekday (1=Monday..
  /// 7=Sunday) when that time only applies on a subset of days — each
  /// selected weekday needs its own id since flutter_local_notifications
  /// schedules "every day at HH:mm" and "every Tuesday at HH:mm" as separate
  /// recurring alarms.
  ///
  /// Previously these were scheduled as `100 + timeIndex` — a plain list
  /// index with no reference to which medication it belonged to. Two
  /// medications with reminders at the same time-of-day slot (e.g. both
  /// "morgens") collided on the same notification id, so the second
  /// medication's schedule silently overwrote the first's. Reserves 1000
  /// ids per medication (10 per time slot, `timeIndex` realistically never
  /// exceeds a handful of daily doses) starting well above the fixed ids
  /// above.
  static int medicationReminderId(int medicationId, int timeIndex,
          [int weekday = 0]) =>
      10000 + medicationId * 1000 + timeIndex * 10 + weekday;

  /// Same scheme as [medicationReminderId], for supplements. A large,
  /// disjoint base offset keeps the two id ranges from ever colliding
  /// without needing to track both counters against each other.
  static int supplementReminderId(int supplementId, int timeIndex,
          [int weekday = 0]) =>
      10000000 + supplementId * 1000 + timeIndex * 10 + weekday;

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

  /// Like [scheduleDailyAt], but repeats weekly on a single [isoWeekday]
  /// (1=Monday..7=Sunday) instead of every day — for medications/supplements
  /// only taken on specific days of the week.
  static Future<void> scheduleWeeklyAt({
    required int id,
    required String title,
    required String body,
    required int isoWeekday,
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
    var daysUntilTarget = (isoWeekday - scheduledDate.weekday) % 7;
    if (daysUntilTarget < 0) daysUntilTarget += 7;
    scheduledDate = scheduledDate.add(Duration(days: daysUntilTarget));
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
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
      matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
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
  /// medication/-supplement reminder for every active medication's/
  /// supplement's stored intake times (read fresh from [db] — these must
  /// survive a Settings-triggered reschedule the same way they were
  /// originally added, and previously they didn't: [cancelAll] below wiped
  /// them and nothing put them back).
  ///
  /// [prefs] keys: `notif_workout`(+`_time`), `notif_habit`(+`_time`),
  /// `notif_todo`(+`_time`), `notif_water`(+`_interval`, minutes),
  /// `notif_period`(+`_days`, `_next_date` as `DateTime?` — the predicted
  /// next period start, or null if unknown/period tracking disabled). No
  /// `notif_medication`/`notif_supplement` keys — those are always rebuilt
  /// below from their own per-item intake times, regardless of any settings
  /// toggle.
  static Future<void> rescheduleAll(
    Map<String, dynamic> prefs, {
    required TraumDatabase db,
  }) async {
    await cancelAll();

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
      final times = parseReminderTimes(medication.timings);
      for (var i = 0; i < times.length; i++) {
        await _scheduleReminderTime(
          times[i],
          idFor: (weekday) => medicationReminderId(medication.id, i, weekday),
          title: medication.name,
          body: 'Zeit für ${medication.name}',
          channelId: 'medication',
        );
      }
    }

    final activeSupplements = await db.supplementDao.getActiveSupplements();
    for (final supplement in activeSupplements) {
      final times = parseReminderTimes(supplement.timings);
      for (var i = 0; i < times.length; i++) {
        await _scheduleReminderTime(
          times[i],
          idFor: (weekday) => supplementReminderId(supplement.id, i, weekday),
          title: supplement.name,
          body: 'Zeit für ${supplement.name}',
          channelId: 'supplement',
        );
      }
    }
  }

  /// Schedules a single [ReminderTime]: one daily repeat if it applies every
  /// day, or one weekly-on-that-day repeat per selected weekday otherwise.
  /// [idFor] maps a weekday (0 for "every day", else 1-7) to the id that
  /// specific occurrence should use — see [medicationReminderId].
  static Future<void> _scheduleReminderTime(
    ReminderTime reminder, {
    required int Function(int weekday) idFor,
    required String title,
    required String body,
    required String channelId,
  }) async {
    final parts = reminder.time.split(':');
    if (parts.length != 2) return;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return;

    if (reminder.isEveryDay) {
      await scheduleDailyAt(
        id: idFor(0),
        title: title,
        body: body,
        hour: hour,
        minute: minute,
        channelId: channelId,
      );
    } else {
      for (final weekday in reminder.days) {
        await scheduleWeeklyAt(
          id: idFor(weekday),
          title: title,
          body: body,
          isoWeekday: weekday,
          hour: hour,
          minute: minute,
          channelId: channelId,
        );
      }
    }
  }
}
