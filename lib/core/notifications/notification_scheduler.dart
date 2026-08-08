import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/database_provider.dart';
import '../providers/preferences_provider.dart';
import 'notification_service.dart';

/// Rebuilds every scheduled local notification (Settings-driven daily/
/// periodic reminders + per-medication precise-time reminders) from the
/// current preferences and database state.
///
/// Single entry point for anything that should cause reminders to be
/// re-derived: a Settings notification toggle/time edit, or adding/
/// deleting/(de)activating a medication. Returns `false` when at least one
/// reminder category is enabled but the OS notification permission isn't
/// granted, so nothing was actually going to fire — callers should warn the
/// user visibly in that case instead of letting the toggle look like it
/// worked.
///
/// Takes a [ProviderContainer] rather than a [WidgetRef] so it can be called
/// from contexts that only have a sheet's own container (e.g. cross-tab add
/// flows that already use `ProviderScope.containerOf(ctx, listen: false)`
/// because the caller's original `ref` is unmounted by save time) as well as
/// from a live widget's `ref` via `ProviderScope.containerOf(context)`.
///
/// Reminder scheduling is an enhancement layered on top of a primary user
/// action (saving/deleting a medication, changing a Settings toggle) — it
/// must never be the reason that primary action appears to fail. Any
/// unexpected error (missing provider override, plugin unavailable, DB
/// error) is caught and logged rather than propagated; `true` is returned in
/// that case since we don't actually know whether permission is the issue,
/// and a bogus "notifications disabled" warning would be misleading.
Future<bool> rescheduleAllNotifications(ProviderContainer container) async {
  try {
    final repo = container.read(preferencesRepositoryProvider);
    final db = container.read(databaseProvider);

    DateTime? nextPeriodPredicted;
    final periodEnabled = container.read(isPeriodTrackingEnabledProvider);
    if (repo.notifPeriod && periodEnabled) {
      try {
        final latestEntry = await db.periodDao.getLatestPeriodEntry();
        if (latestEntry != null) {
          final calc =
              await db.periodDao.getCalculationForEntry(latestEntry.id);
          nextPeriodPredicted = calc?.nextPeriodPredicted;
        }
      } catch (_) {
        // Prediction unavailable (e.g. not enough tracked cycles yet) — the
        // period reminder is simply skipped this round, same as before.
      }
    }

    await NotificationService.rescheduleAll(
      {
        'notif_workout': repo.notifWorkout,
        'notif_workout_time': repo.notifWorkoutTime,
        'notif_habit': repo.notifHabit,
        'notif_habit_time': repo.notifHabitTime,
        'notif_todo': repo.notifTodo,
        'notif_todo_time': repo.notifTodoTime,
        'notif_water': repo.notifWater,
        'notif_water_interval': repo.notifWaterInterval,
        'notif_period': repo.notifPeriod,
        'notif_period_days': repo.notifPeriodDays,
        'notif_period_next_date': nextPeriodPredicted,
      },
      db: db,
    );

    // Medications/supplements don't have a category toggle (see
    // preferences_provider.dart) — any active one with at least one
    // configured time counts on its own toward whether the permission
    // check below is relevant.
    final hasMedicationReminder = (await db.medicationDao.getActiveMedications())
        .any((m) => m.timings != '[]');
    final hasSupplementReminder = (await db.supplementDao.getActiveSupplements())
        .any((s) => s.timings != '[]');

    final anyEnabled = hasMedicationReminder ||
        hasSupplementReminder ||
        repo.notifWorkout ||
        repo.notifHabit ||
        repo.notifTodo ||
        repo.notifWater ||
        repo.notifPeriod;
    if (!anyEnabled) return true;
    return await NotificationService.hasPermission();
  } catch (e, st) {
    debugPrint('[notifications] rescheduleAllNotifications failed: $e\n$st');
    return true;
  }
}
