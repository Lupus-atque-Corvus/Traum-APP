import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/providers/database_provider.dart';
import '../core/providers/preferences_provider.dart';
import '../features/budget/budget_providers.dart';
import '../features/diary/diary_provider.dart';
import '../features/graffiti_map/graffiti_map_provider.dart'
    show mapMarkersDaoProvider, markerPhotosDaoProvider;
import '../features/health/health_score_provider.dart';
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
    // ── Phase 1 ──────────────────────────────────────────────────────────────
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
    // ── Phase 2 — health ──────────────────────────────────────────────────────
    int healthScore = 0,
    double weightKg = 0.0,
    int activeMinutes = 0,
    // ── Phase 2 — nutrition ───────────────────────────────────────────────────
    int carbs = 0,
    int fat = 0,
    String lastMeal = '',
    // ── training ─────────────────────────────────────────────────────────────
    String nextWorkout = '',
    int weeklyVolume = 0,
    int trainingStreak = 0,
    // ── Phase 2 — planning ────────────────────────────────────────────────────
    int openTodos = 0,
    String nextAppointment = '',
    int habitsDone = 0,
    int habitsTotal = 0,
    int medsDone = 0,
    int medsTotal = 0,
    // ── budget ───────────────────────────────────────────────────────────────
    double balanceMonth = 0.0,
    double income = 0.0,
    double expense = 0.0,
    double budgetSpent = 0.0,
    double budgetLimit = 0.0,
    String topCategory = '',
    // ── diary ─────────────────────────────────────────────────────────────────
    int writeStreak = 0,
    String lastEntry = '',
    int entriesThisMonth = 0,
    // ── abstinence ───────────────────────────────────────────────────────────
    String abstinenceTitle = '',
    String abstinenceDuration = '',
    double moneySaved = 0.0,
    // ── substances ───────────────────────────────────────────────────────────
    String lastIntake = '',
    int takenToday = 0,
    // ── period ───────────────────────────────────────────────────────────────
    int cycleDay = 0,
    String periodPhase = '',
    int nextPeriodDays = 0,
    // ── notes ─────────────────────────────────────────────────────────────────
    int notesCount = 0,
    String lastNote = '',
    // ── map ───────────────────────────────────────────────────────────────────
    int placesCount = 0,
    String lastPhoto = '',
  }) {
    return WidgetSnapshot(
      // Phase 1
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
      // Phase 2 — health
      healthScore: healthScore,
      weightKg: weightKg,
      activeMinutes: activeMinutes,
      // Phase 2 — nutrition
      carbs: carbs,
      fat: fat,
      lastMeal: lastMeal,
      // training
      nextWorkout: nextWorkout,
      weeklyVolume: weeklyVolume,
      trainingStreak: trainingStreak,
      // Phase 2 — planning
      openTodos: openTodos,
      nextAppointment: nextAppointment,
      habitsDone: habitsDone,
      habitsTotal: habitsTotal,
      medsDone: medsDone,
      medsTotal: medsTotal,
      // budget
      balanceMonth: balanceMonth,
      income: income,
      expense: expense,
      budgetSpent: budgetSpent,
      budgetLimit: budgetLimit,
      topCategory: topCategory,
      // diary
      writeStreak: writeStreak,
      lastEntry: lastEntry,
      entriesThisMonth: entriesThisMonth,
      // abstinence
      abstinenceTitle: abstinenceTitle,
      abstinenceDuration: abstinenceDuration,
      moneySaved: moneySaved,
      // substances
      lastIntake: lastIntake,
      takenToday: takenToday,
      // period
      cycleDay: cycleDay,
      periodPhase: periodPhase,
      nextPeriodDays: nextPeriodDays,
      // notes
      notesCount: notesCount,
      lastNote: lastNote,
      // map
      placesCount: placesCount,
      lastPhoto: lastPhoto,
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

    // ── steps (FALLBACK: keine Quelle) ────────────────────────────────────────
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

    // ── heartRate (FALLBACK: keine Quelle; widget zeigt '—') ──────────────────
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

    // ── todaysTotals (REAL: todaysTotalsProvider) — read once, reused for kcal/protein/carbs/fat ─
    // Same source as _CaloriesRingContent / _RemainingCaloriesContent / _MacrosContent in nutrition_widgets.dart
    MacroSummary? todaysTotals;
    try {
      todaysTotals = await read(todaysTotalsProvider.future);
    } catch (_) {}

    // ── kcalToday (REAL: todaysTotalsProvider → calories) ────────────────────
    // Same source as _CaloriesRingContent / _RemainingCaloriesContent in nutrition_widgets.dart
    final int kcalToday =
        todaysTotals != null ? todaysTotals.calories.round() : empty.kcal;

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
    final int proteinToday =
        todaysTotals != null ? todaysTotals.protein.round() : empty.protein;

    // ── proteinGoal (REAL: preferences_provider.dart – proteinGoalGProvider) ──
    int proteinGoal = empty.proteinGoal;
    try {
      proteinGoal = read(proteinGoalGProvider);
    } catch (_) {}

    // ── allTodos (REAL: planningDaoProvider.getAllTodos()) — read once, reused for nextTodoTitle and openTodos ─
    // Same source as _OpenTodosContent in planning_widgets.dart
    final allTodos = await () async {
      try {
        return await read(planningDaoProvider).getAllTodos();
      } catch (_) {
        return <dynamic>[];
      }
    }();

    // ── nextTodoTitle (REAL: planningDaoProvider.getAllTodos() → first open) ───
    // Same source as _OpenTodosContent in planning_widgets.dart
    String? nextTodoTitle;
    {
      final open = allTodos.where((t) => !t.done).toList();
      if (open.isNotEmpty) {
        nextTodoTitle = open.first.title;
      }
    }

    // ── healthScore (REAL: healthScoreProvider → gesamtScore) ────────────────
    // Same source as _HealthScoreContent in health_widgets.dart
    int healthScore = 0;
    try {
      final result = await read(healthScoreProvider.future);
      healthScore = result.gesamtScore;
    } catch (_) {}

    // ── weightKg (REAL: healthDaoProvider.getAllWeightLogs() → latest) ────────
    // Same source as _WeightTrendContent in health_widgets.dart
    double weightKg = 0.0;
    try {
      final logs = await read(healthDaoProvider).getAllWeightLogs();
      if (logs.isNotEmpty) {
        weightKg = logs.first.weightKg; // ordered desc by logDate
      }
    } catch (_) {}

    // ── activeMinutes (FALLBACK: keine Quelle; widget zeigt '—') ─────────────
    const int activeMinutes = 0;

    // ── carbs (REAL: todaysTotalsProvider → carbs) ────────────────────────────
    // Same source as _MacrosContent in nutrition_widgets.dart
    final int carbs = todaysTotals != null ? todaysTotals.carbs.round() : 0;

    // ── fat (REAL: todaysTotalsProvider → fat) ────────────────────────────────
    // Same source as _MacrosContent in nutrition_widgets.dart
    final int fat = todaysTotals != null ? todaysTotals.fat.round() : 0;

    // ── lastMeal (REAL: lastMealProvider → name) ──────────────────────────────
    // Same source as _LastMealContent in nutrition_widgets.dart
    String lastMeal = '';
    try {
      final meal = await read(lastMealProvider.future);
      if (meal != null) lastMeal = meal.name;
    } catch (_) {}

    // ── nextWorkout (REAL: activePlanProvider + getDaysForPlan → day name) ────
    // Same logic as _NextWorkoutContent in training_widgets.dart
    String nextWorkout = '';
    try {
      final plan = await read(activePlanProvider.future);
      if (plan != null) {
        final days =
            await read(trainingDaoProvider).getDaysForPlan(plan.id);
        if (days.isNotEmpty) {
          final today = DateTime.now().weekday;
          final ordered = [...days]
            ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
          final day = ordered.firstWhere(
            (d) => d.dayOfWeek == today,
            orElse: () => ordered.first,
          );
          nextWorkout = day.name;
        }
      }
    } catch (_) {}

    // ── weeklyVolume (REAL: recentTrainingSetsProvider(7) → working sets) ─────
    // Same logic as _WeeklyVolumeContent in training_widgets.dart
    int weeklyVolume = 0;
    try {
      final sets = await read(recentTrainingSetsProvider(7).future);
      weeklyVolume = sets.where((s) => !s.isWarmup).length;
    } catch (_) {}

    // ── trainingStreak (REAL: trainingDaoProvider.getSessionsAfter(365d)) ─────
    // Same logic as _TrainingStreakContent in training_widgets.dart
    int trainingStreak = 0;
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 365));
      final sessions =
          await read(trainingDaoProvider).getSessionsAfter(cutoff);
      final sessionsSorted = [...sessions]
        ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
      final weekStarts = <DateTime>{};
      for (final s in sessionsSorted) {
        weekStarts.add(_weekStart(s.startedAt));
      }
      int streak = 0;
      var cursor = _weekStart(DateTime.now());
      if (!weekStarts.contains(cursor)) {
        cursor = cursor.subtract(const Duration(days: 7));
      }
      while (weekStarts.contains(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 7));
      }
      trainingStreak = streak;
    } catch (_) {}

    // ── openTodos (REAL: planningDaoProvider.getAllTodos() → open count) ──────
    // Same logic as _OpenTodosContent in planning_widgets.dart (already read for nextTodoTitle)
    final int openTodos = allTodos.where((t) => !t.done).length;

    // ── nextAppointment (REAL: planningDaoProvider.getNextAppointment()) ──────
    // Same source as _NextAppointmentCountdownContent in planning_widgets.dart
    String nextAppointment = '';
    try {
      final appt = await read(planningDaoProvider).getNextAppointment();
      if (appt != null) nextAppointment = appt.title;
    } catch (_) {}

    // ── habitsDone / habitsTotal (REAL: planningDaoProvider) ──────────────────
    // Same logic as _HabitsTodayContent in planning_widgets.dart
    int habitsDone = 0;
    int habitsTotal = 0;
    try {
      final habits = await read(planningDaoProvider).getAllHabits();
      final todayLogs =
          await read(planningDaoProvider).getHabitLogsForDate(DateTime.now());
      habitsTotal = habits.length;
      final doneIds =
          todayLogs.where((l) => l.done).map((l) => l.habitId).toSet();
      habitsDone = doneIds.length;
    } catch (_) {}

    // ── medsDone / medsTotal (REAL: medicationDaoProvider.getActiveMedications()) ──
    // Same logic as _MedicationsTodayContent in planning_widgets.dart
    // medsDone: FALLBACK: keine Quelle (no taken-today log read in the tile)
    int medsDone = 0; // FALLBACK: keine Quelle
    int medsTotal = 0;
    try {
      final meds = await read(medicationDaoProvider).getActiveMedications();
      medsTotal = meds
          .where(
              (m) => m.timings.trim().isNotEmpty && m.timings.trim() != '[]')
          .length;
    } catch (_) {}

    // ── balanceMonth / income / expense (REAL: budgetDaoProvider.getTransactionsForMonth) ──
    // Same logic as _BalanceMonthContent / _IncomeExpenseContent in budget_widgets.dart
    double balanceMonth = 0.0;
    double incomeMonth = 0.0;
    double expenseMonth = 0.0;
    try {
      final now = DateTime.now();
      final txs = await read(budgetDaoProvider)
          .getTransactionsForMonth(now.year, now.month);
      incomeMonth = txs
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      expenseMonth = txs
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      balanceMonth = incomeMonth - expenseMonth;
    } catch (_) {}

    // ── budgetSpent / budgetLimit (REAL: budgetDaoProvider + SharedPreferences) ─
    // Same logic as _BudgetProgressContent in budget_widgets.dart
    // budgetSpent reuses expenseMonth (same filter: type == 'expense', same month)
    final double budgetSpent = expenseMonth;
    double budgetLimit = 0.0;
    try {
      budgetLimit =
          read(sharedPreferencesProvider).getDouble('monthly_budget') ?? 0.0;
    } catch (_) {}

    // ── topCategory (REAL: budgetDaoProvider → category expenses sorted desc) ─
    // Same logic as _TopCategoryContent in budget_widgets.dart
    String topCategory = '';
    try {
      final now = DateTime.now();
      final cats =
          await read(categoryExpensesProvider((now.year, now.month)).future);
      if (cats.isNotEmpty) {
        topCategory = cats.first.category.name;
      }
    } catch (_) {}

    // ── writeStreak (REAL: diaryStreakProvider) ───────────────────────────────
    // Same source as _WriteStreakContent in diary_widgets.dart
    int writeStreak = 0;
    try {
      writeStreak = await read(diaryStreakProvider.future);
    } catch (_) {}

    // ── lastEntry (REAL: diaryDaoProvider.getLastEntry() → note) ─────────────
    // Same source as _LastEntryContent in diary_widgets.dart
    String lastEntry = '';
    try {
      final entry = await read(diaryDaoProvider).getLastEntry();
      if (entry != null) lastEntry = entry.note.trim();
    } catch (_) {}

    // ── entriesThisMonth (REAL: diaryEntriesForMonthProvider) ────────────────
    // Same source as _EntriesThisMonthContent in diary_widgets.dart
    int entriesThisMonth = 0;
    try {
      final now = DateTime.now();
      final entries = await read(
          diaryEntriesForMonthProvider((now.year, now.month)).future);
      entriesThisMonth = entries.length;
    } catch (_) {}

    // ── abstinenceTitle / abstinenceDuration (REAL: abstinenceDaoProvider) ────
    // Same logic as _CurrentStreakContent / _AllCountersContent in misc_widgets.dart
    String abstinenceTitle = '';
    String abstinenceDuration = '';
    try {
      final trackers =
          await read(abstinenceDaoProvider).getAllTrackers();
      final active = trackers.where((t) => t.isActive).toList();
      if (active.isNotEmpty) {
        // Longest currently-running streak (same logic as _CurrentStreakContent)
        final best = active.reduce(
            (a, b) => _daysSince(a.startDate) >= _daysSince(b.startDate) ? a : b);
        abstinenceTitle = best.name;
        final days = _daysSince(best.startDate);
        abstinenceDuration = '$days ${days == 1 ? 'Tag' : 'Tage'}';
      }
    } catch (_) {}

    // ── moneySaved (FALLBACK: keine Quelle; widget zeigt '—') ────────────────
    const double moneySaved = 0.0;

    // ── lastIntake (FALLBACK: keine Quelle; kein Intake-Log persistiert) ─────
    const String lastIntake = '';

    // ── takenToday (FALLBACK: keine Quelle; kein Intake-Log persistiert) ─────
    const int takenToday = 0;

    // ── cycleDay (REAL: periodDaoProvider.getLatestPeriodEntry()) ────────────
    // Same logic as _CycleDayContent in misc_widgets.dart
    int cycleDay = 0;
    try {
      final latest = await read(periodDaoProvider).getLatestPeriodEntry();
      if (latest != null) {
        cycleDay = _daysSince(latest.startDate) + 1;
      }
    } catch (_) {}

    // ── periodPhase (FALLBACK: keine Quelle; Kachel zeigt keinen phase-Text) ─
    const String periodPhase = '';

    // ── nextPeriodDays (REAL: periodDaoProvider.getCalculationForEntry()) ─────
    // Same logic as _NextPeriodContent in misc_widgets.dart
    int nextPeriodDays = 0;
    try {
      final dao = read(periodDaoProvider);
      final latest = await dao.getLatestPeriodEntry();
      if (latest != null) {
        final calc = await dao.getCalculationForEntry(latest.id);
        final predicted = calc?.nextPeriodPredicted;
        if (predicted != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final target = DateTime(
              predicted.year, predicted.month, predicted.day);
          final diff = target.difference(today).inDays;
          if (diff >= 0) nextPeriodDays = diff;
        }
      }
    } catch (_) {}

    // ── notesCount (REAL: notesDaoProvider.getActiveNotes()) ─────────────────
    // Same source as _NotesCountContent in misc_widgets.dart
    int notesCount = 0;
    try {
      final notes = await read(notesDaoProvider).getActiveNotes();
      notesCount = notes.length;
    } catch (_) {}

    // ── lastNote (REAL: notesDaoProvider.getRecentNotes(1) → title) ──────────
    // Same source as _LastNoteContent in misc_widgets.dart
    String lastNote = '';
    try {
      final notes = await read(notesDaoProvider).getRecentNotes(1);
      if (notes.isNotEmpty) {
        lastNote = notes.first.title.trim().isEmpty
            ? notes.first.content.trim()
            : notes.first.title.trim();
      }
    } catch (_) {}

    // ── placesCount (REAL: mapMarkersDaoProvider.getAll()) ───────────────────
    // Same source as _PlacesCountContent in misc_widgets.dart
    int placesCount = 0;
    try {
      final markers = await read(mapMarkersDaoProvider).getAll();
      placesCount = markers.length;
    } catch (_) {}

    // ── lastPhoto (REAL: markerPhotosDaoProvider.getAll() → latest date) ─────
    // Same source as _LastPhotoContent in misc_widgets.dart
    String lastPhoto = '';
    try {
      final photos = await read(markerPhotosDaoProvider).getAll();
      if (photos.isNotEmpty) {
        final d = photos.first.takenAt;
        lastPhoto =
            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
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
      healthScore: healthScore,
      weightKg: weightKg,
      activeMinutes: activeMinutes,
      carbs: carbs,
      fat: fat,
      lastMeal: lastMeal,
      nextWorkout: nextWorkout,
      weeklyVolume: weeklyVolume,
      trainingStreak: trainingStreak,
      openTodos: openTodos,
      nextAppointment: nextAppointment,
      habitsDone: habitsDone,
      habitsTotal: habitsTotal,
      medsDone: medsDone,
      medsTotal: medsTotal,
      balanceMonth: balanceMonth,
      income: incomeMonth,
      expense: expenseMonth,
      budgetSpent: budgetSpent,
      budgetLimit: budgetLimit,
      topCategory: topCategory,
      writeStreak: writeStreak,
      lastEntry: lastEntry,
      entriesThisMonth: entriesThisMonth,
      abstinenceTitle: abstinenceTitle,
      abstinenceDuration: abstinenceDuration,
      moneySaved: moneySaved,
      lastIntake: lastIntake,
      takenToday: takenToday,
      cycleDay: cycleDay,
      periodPhase: periodPhase,
      nextPeriodDays: nextPeriodDays,
      notesCount: notesCount,
      lastNote: lastNote,
      placesCount: placesCount,
      lastPhoto: lastPhoto,
    );
  }

  // ---------------------------------------------------------------------------
  // Private helpers
  // ---------------------------------------------------------------------------

  static DateTime _weekStart(DateTime d) {
    final day = DateTime(d.year, d.month, d.day);
    return day.subtract(Duration(days: day.weekday - 1));
  }

  static int _daysSince(DateTime d) {
    final now = DateTime.now();
    final start = DateTime(d.year, d.month, d.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(start).inDays;
    return diff < 0 ? 0 : diff;
  }
}
