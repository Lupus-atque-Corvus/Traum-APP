import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/database_provider.dart';
import '../core/providers/preferences_provider.dart';
import '../features/nutrition/nutrition_providers.dart';
import 'widget_snapshot.dart';

/// Collects all data needed for the homescreen widget snapshot.
///
/// [mapToSnapshot] is a PURE static function that maps raw values to a
/// [WidgetSnapshot] — fully testable without any I/O.
///
/// [collect] reads the real values via Riverpod providers and calls
/// [mapToSnapshot].
class WidgetDataCollector {
  WidgetDataCollector._();

  // ---------------------------------------------------------------------------
  // Pure mapping (unit-tested)
  // ---------------------------------------------------------------------------

  /// Maps raw metric values to a [WidgetSnapshot].
  /// [nextTodoTitle] may be null (no open todos) → stored as empty string.
  static WidgetSnapshot mapToSnapshot({
    required int stepsToday,
    required int stepsGoal,
    required double sleepHours,
    required int heartRate,
    required int mood,
    required int kcalToday,
    required int kcalGoal,
    required int waterMlToday,
    required int waterGoalMl,
    required int proteinToday,
    required int proteinGoal,
    required String? nextTodoTitle,
  }) {
    return WidgetSnapshot(
      steps: stepsToday,
      stepsGoal: stepsGoal,
      sleepHours: sleepHours,
      heartRate: heartRate,
      mood: mood,
      kcal: kcalToday,
      kcalGoal: kcalGoal,
      waterMl: waterMlToday,
      waterGoalMl: waterGoalMl,
      protein: proteinToday,
      proteinGoal: proteinGoal,
      nextTodo: nextTodoTitle ?? '',
    );
  }

  // ---------------------------------------------------------------------------
  // Real data collection via Riverpod
  // ---------------------------------------------------------------------------

  /// Reads all metrics from the real data layer and returns a [WidgetSnapshot].
  ///
  /// Accepts a [read] function so this method can be called from any context:
  /// - Foreground widget: pass `ref.read` (a [WidgetRef] or [Ref] tear-off)
  /// - Background isolate: pass `container.read` (a [ProviderContainer] tear-off)
  ///
  /// Each metric is wrapped in its own try/catch so one failing read cannot
  /// crash the entire collection; the corresponding [WidgetSnapshot.empty()]
  /// default is used as fallback.
  static Future<WidgetSnapshot> collect(
    R Function<R>(ProviderListenable<R> provider) read,
  ) async {
    final empty = WidgetSnapshot.empty();

    // ── steps (FALLBACK: no live step data source exists yet) ─────────────────
    final int stepsToday = empty.steps; // 0

    // ── stepsGoal (REAL: preferences_provider.dart – stepsGoalProvider) ───────
    int stepsGoal = empty.stepsGoal;
    try {
      stepsGoal = read(stepsGoalProvider);
    } catch (_) {}

    // ── sleepHours (REAL: healthDaoProvider.getRecentSleepLogs(2)) ────────────
    // Same logic as _SleepContent / _HealthSnapshotContent in health_widgets.dart
    double sleepHours = empty.sleepHours;
    try {
      final logs = await read(healthDaoProvider).getRecentSleepLogs(2);
      if (logs.isNotEmpty) {
        final latest =
            logs.reduce((a, b) => a.bedtime.isAfter(b.bedtime) ? a : b);
        final hours =
            latest.wakeTime.difference(latest.bedtime).inMinutes / 60.0;
        if (hours > 0) sleepHours = hours;
      }
    } catch (_) {}

    // ── heartRate (FALLBACK: no live heart-rate source; widget shows '—') ─────
    final int heartRate = empty.heartRate; // 0

    // ── mood (REAL: healthDaoProvider.getLatestMood()) ────────────────────────
    // Same logic as _MoodContent in health_widgets.dart
    int mood = empty.mood;
    try {
      final moodLog = await read(healthDaoProvider).getLatestMood();
      if (moodLog != null) {
        final now = DateTime.now();
        final isToday = moodLog.logDate.year == now.year &&
            moodLog.logDate.month == now.month &&
            moodLog.logDate.day == now.day;
        if (isToday) {
          mood = moodLog.moodScore.clamp(1, 5);
        }
      }
    } catch (_) {}

    // ── kcalToday (REAL: todaysTotalsProvider → calories) ────────────────────
    // Same source as _CaloriesRingContent / _RemainingCaloriesContent in nutrition_widgets.dart
    int kcalToday = empty.kcal;
    try {
      final totals = await read(todaysTotalsProvider.future);
      kcalToday = totals.calories.round();
    } catch (_) {}

    // ── kcalGoal (REAL: preferences_provider.dart – kcalGoalProvider) ─────────
    int kcalGoal = empty.kcalGoal;
    try {
      kcalGoal = read(kcalGoalProvider);
    } catch (_) {}

    // ── waterMlToday (REAL: waterTodaySnapshotProvider) ───────────────────────
    // Same source as _WaterContent in nutrition_widgets.dart
    int waterMlToday = empty.waterMl;
    try {
      waterMlToday = await read(waterTodaySnapshotProvider.future);
    } catch (_) {}

    // ── waterGoalMl (REAL: preferences_provider.dart – waterGoalMlProvider) ───
    int waterGoalMl = empty.waterGoalMl;
    try {
      waterGoalMl = read(waterGoalMlProvider);
    } catch (_) {}

    // ── proteinToday (REAL: todaysTotalsProvider → protein) ──────────────────
    // Same source as _MacrosContent in nutrition_widgets.dart
    int proteinToday = empty.protein;
    try {
      final totals = await read(todaysTotalsProvider.future);
      proteinToday = totals.protein.round();
    } catch (_) {}

    // ── proteinGoal (REAL: preferences_provider.dart – proteinGoalGProvider) ──
    int proteinGoal = empty.proteinGoal;
    try {
      proteinGoal = read(proteinGoalGProvider);
    } catch (_) {}

    // ── nextTodoTitle (REAL: planningDaoProvider.getAllTodos() → first open) ───
    // Same source as _OpenTodosContent in planning_widgets.dart
    String? nextTodoTitle;
    try {
      final todos = await read(planningDaoProvider).getAllTodos();
      final open = todos.where((t) => !t.done).toList();
      if (open.isNotEmpty) {
        nextTodoTitle = open.first.title;
      }
    } catch (_) {}

    return mapToSnapshot(
      stepsToday: stepsToday,
      stepsGoal: stepsGoal,
      sleepHours: sleepHours,
      heartRate: heartRate,
      mood: mood,
      kcalToday: kcalToday,
      kcalGoal: kcalGoal,
      waterMlToday: waterMlToday,
      waterGoalMl: waterGoalMl,
      proteinToday: proteinToday,
      proteinGoal: proteinGoal,
      nextTodoTitle: nextTodoTitle,
    );
  }
}
