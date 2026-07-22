import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart';

import '../core/providers/database_provider.dart';
import '../core/providers/preferences_provider.dart';
import '../data/services/health_service.dart';
import '../features/budget/budget_providers.dart';
import '../features/diary/diary_provider.dart';
import '../features/graffiti_map/graffiti_map_provider.dart'
    show mapMarkersDaoProvider, markerPhotosDaoProvider;
import '../features/health/health_score_provider.dart';
import '../features/nutrition/nutrition_providers.dart';
import '../features/training/muscle_groups.dart' show canonicalMuscleGroup;
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
    // ── Phase 3 — map ─────────────────────────────────────────────────────────
    int mapPreview = 0,
    // ── Phase 3 — general ─────────────────────────────────────────────────────
    String clockDate = '',
    String weatherTemp = '',
    String weatherForecast = '',
    int appFavorites = 0,
    String quickActions = '',
    // ── Phase 3 — health ──────────────────────────────────────────────────────
    int caloriesBurned = 0,
    int stepsWeekAvg = 0,
    // ── Phase 3 — nutrition ───────────────────────────────────────────────────
    int supplementsToday = 0,
    int mealsToday = 0,
    // ── Phase 3 — training ────────────────────────────────────────────────────
    int muscleHeatmap = 0,
    String lastWorkout = '',
    int weeklyWorkouts = 0,
    int personalRecords = 0,
    String restTimer = '',
    // ── Phase 3 — planning ────────────────────────────────────────────────────
    int overdueTodos = 0,
    int bestHabitStreak = 0,
    // ── Phase 3 — budget ──────────────────────────────────────────────────────
    String accountsOverview = '',
    String recentTransaction = '',
    String savingsGoal = '',
    int recurringDue = 0,
    String monthTrend = '',
    // ── Phase 3 — diary ───────────────────────────────────────────────────────
    int yearHeatmap = 0,
    int moodCalendar = 0,
    // ── Phase 3 — abstinence ──────────────────────────────────────────────────
    int longestStreak = 0,
    int allCounters = 0,
    // ── Phase 3 — notes ───────────────────────────────────────────────────────
    String pinnedNote = '',
    // ── v2 series (CSV / labels) ──────────────────────────────────────────────
    String stepsWeek = '',
    String sleepWeek = '',
    String weightHistory = '',
    String moodWeek = '',
    String macroSplit = '',
    String mealsTodayList = '',
    String volumeWeek = '',
    String todayAgenda = '',
    String habitWeek = '',
    String categorySplit = '',
    String monthTrendSeries = '',
    String counters = '',
    String quote = '',
    String countdownLabel = '',
    String countdownDays = '',
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
      // Phase 3 — map
      mapPreview: mapPreview,
      // Phase 3 — general
      clockDate: clockDate,
      weatherTemp: weatherTemp,
      weatherForecast: weatherForecast,
      appFavorites: appFavorites,
      quickActions: quickActions,
      // Phase 3 — health
      caloriesBurned: caloriesBurned,
      stepsWeekAvg: stepsWeekAvg,
      // Phase 3 — nutrition
      supplementsToday: supplementsToday,
      mealsToday: mealsToday,
      // Phase 3 — training
      muscleHeatmap: muscleHeatmap,
      lastWorkout: lastWorkout,
      weeklyWorkouts: weeklyWorkouts,
      personalRecords: personalRecords,
      restTimer: restTimer,
      // Phase 3 — planning
      overdueTodos: overdueTodos,
      bestHabitStreak: bestHabitStreak,
      // Phase 3 — budget
      accountsOverview: accountsOverview,
      recentTransaction: recentTransaction,
      savingsGoal: savingsGoal,
      recurringDue: recurringDue,
      monthTrend: monthTrend,
      // Phase 3 — diary
      yearHeatmap: yearHeatmap,
      moodCalendar: moodCalendar,
      // Phase 3 — abstinence
      longestStreak: longestStreak,
      allCounters: allCounters,
      // Phase 3 — notes
      pinnedNote: pinnedNote,
      // v2 series
      stepsWeek: stepsWeek,
      sleepWeek: sleepWeek,
      weightHistory: weightHistory,
      moodWeek: moodWeek,
      macroSplit: macroSplit,
      mealsTodayList: mealsTodayList,
      volumeWeek: volumeWeek,
      todayAgenda: todayAgenda,
      habitWeek: habitWeek,
      categorySplit: categorySplit,
      monthTrendSeries: monthTrendSeries,
      counters: counters,
      quote: quote,
      countdownLabel: countdownLabel,
      countdownDays: countdownDays,
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

    // ── steps (REAL: HealthService.stepsToday() via Health Connect/HealthKit) ─
    int stepsToday = empty.steps;
    try {
      stepsToday = await HealthService.stepsToday();
    } catch (_) {}

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

    // ── heartRate (REAL: HealthService.latestHeartRate() last 24h) ───────────
    int heartRate = empty.heartRate;
    try {
      heartRate = await HealthService.latestHeartRate();
    } catch (_) {}

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

    // ── activeMinutes (REAL: HealthService.activeMinutesToday()) ─────────────
    int activeMinutes = 0;
    try {
      activeMinutes = await HealthService.activeMinutesToday();
    } catch (_) {}

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

    // ── medsDone / medsTotal (REAL: medicationDaoProvider) ───────────────────
    // medsTotal: active meds with at least one scheduled time.
    // medsDone: getTakenCountToday() — taken-logs written by the "Heute" card.
    int medsDone = 0;
    int medsTotal = 0;
    try {
      final dao = read(medicationDaoProvider);
      final meds = await dao.getActiveMedications();
      medsTotal = meds
          .where(
              (m) => m.timings.trim().isNotEmpty && m.timings.trim() != '[]')
          .length;
      medsDone = await dao.getTakenCountToday();
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

    // ── allTrackers (REAL: abstinenceDaoProvider.getAllTrackers()) — read once, reused for
    //    abstinenceTitle, abstinenceDuration, longestStreak, allCounters ─────────────────
    // Same source as _CurrentStreakContent / _LongestStreakContent / _AllCountersContent
    // in misc_widgets.dart
    final allTrackers = await () async {
      try {
        return await read(abstinenceDaoProvider).getAllTrackers();
      } catch (_) {
        return <dynamic>[];
      }
    }();

    // ── abstinenceTitle / abstinenceDuration (REAL: allTrackers → active only) ─
    // Same logic as _CurrentStreakContent in misc_widgets.dart
    String abstinenceTitle = '';
    String abstinenceDuration = '';
    {
      final active = allTrackers.where((t) => t.isActive).toList();
      if (active.isNotEmpty) {
        // Longest currently-running streak (same logic as _CurrentStreakContent)
        final best = active.reduce(
            (a, b) => _daysSince(a.startDate) >= _daysSince(b.startDate) ? a : b);
        abstinenceTitle = best.name;
        final days = _daysSince(best.startDate);
        abstinenceDuration = '$days ${days == 1 ? 'Tag' : 'Tage'}';
      }
    }

    // ── moneySaved (REAL: Σ costPerDay × Tage über aktive Tracker) ───────────
    // Reuses allTrackers; costPerDay (v16) is null when the user left it blank.
    double moneySaved = 0.0;
    for (final t in allTrackers) {
      if (t.isActive == true && t.costPerDay != null) {
        moneySaved += (t.costPerDay as double) * _daysSince(t.startDate);
      }
    }

    // ── lastIntake (REAL: substanceDaoProvider.getLastIntake() → name) ───────
    String lastIntake = '';
    try {
      final last = await read(substanceDaoProvider).getLastIntake();
      if (last != null) lastIntake = last.substanceName;
    } catch (_) {}

    // ── takenToday (REAL: substanceDaoProvider.getIntakeCountToday()) ────────
    int takenToday = 0;
    try {
      takenToday = await read(substanceDaoProvider).getIntakeCountToday();
    } catch (_) {}

    // ── cycleDay (REAL: periodDaoProvider.getLatestPeriodEntry()) ────────────
    // Same logic as _CycleDayContent in misc_widgets.dart
    int cycleDay = 0;
    try {
      final latest = await read(periodDaoProvider).getLatestPeriodEntry();
      if (latest != null) {
        cycleDay = _daysSince(latest.startDate) + 1;
      }
    } catch (_) {}

    // ── periodPhase (REAL: abgeleitet aus PeriodEntry + CycleCalculation) ─────
    // Gleiche Logik wie _CycleStatusCard in period_screen.dart:
    // Menstruation (innerhalb Periode) → Ovulation → Fruchtbar → Luteal → Follikel.
    String periodPhase = '';
    try {
      final dao = read(periodDaoProvider);
      final latest = await dao.getLatestPeriodEntry();
      if (latest != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(
            latest.startDate.year, latest.startDate.month, latest.startDate.day);
        final end = latest.endDate;
        final inPeriod = !today.isBefore(start) &&
            (end == null
                ? today.difference(start).inDays < 7
                : !today.isAfter(DateTime(end.year, end.month, end.day)));
        if (inPeriod) {
          periodPhase = 'Menstruation';
        } else {
          final calc = await dao.getCalculationForEntry(latest.id);
          final ov = calc?.ovulationDate;
          final fs = calc?.fertileStart;
          final fe = calc?.fertileEnd;
          final ovDay =
              ov == null ? null : DateTime(ov.year, ov.month, ov.day);
          if (ovDay != null && today == ovDay) {
            periodPhase = 'Ovulation';
          } else if (fs != null &&
              fe != null &&
              !today.isBefore(DateTime(fs.year, fs.month, fs.day)) &&
              !today.isAfter(DateTime(fe.year, fe.month, fe.day))) {
            periodPhase = 'Fruchtbar';
          } else if (ovDay != null && today.isAfter(ovDay)) {
            periodPhase = 'Lutealphase';
          } else {
            periodPhase = 'Follikelphase';
          }
        }
      }
    } catch (_) {}

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

    // ── Phase 3 new fields ───────────────────────────────────────────────────

    // ── mapPreview (REAL: reuse placesCount — mapPreview shows marker count as surrogate) ──
    final int mapPreview = placesCount;

    // ── clockDate (FALLBACK: keine Quelle; live clock renders in widget, not snapshot) ────
    const String clockDate = ''; // FALLBACK: keine Quelle

    // ── weatherCache (REAL: SharedPreferences weather_cache) — parsed once,
    //    reused for weatherTemp + weatherForecast ───────────────────────────────
    // Same source as _WeatherContent in general_widgets.dart
    Map<String, dynamic>? weatherCurrent;
    try {
      final prefs = read(sharedPreferencesProvider);
      final cache = prefs.getString('weather_cache');
      if (cache != null && cache.isNotEmpty) {
        final data = jsonDecode(cache) as Map<String, dynamic>?;
        weatherCurrent = data?['current'] as Map<String, dynamic>?;
      }
    } catch (_) {}

    // ── weatherTemp (REAL: weather_cache → temperature_2m) ───────────────────
    String weatherTemp = '';
    {
      final temp = weatherCurrent?['temperature_2m'] as num?;
      if (temp != null) weatherTemp = '${temp.toStringAsFixed(0)}°C';
    }

    // ── weatherForecast (REAL: weather_cache → condition label) ──────────────
    String weatherForecast = '';
    {
      final code = (weatherCurrent?['weathercode'] as num?)?.toInt() ?? -1;
      if (code >= 0) {
        String cond(int c) {
          if (c == 0) return 'Klar';
          if (c <= 3) return 'Bewölkt';
          if (c <= 48) return 'Neblig';
          if (c <= 67) return 'Regen';
          if (c <= 77) return 'Schnee';
          if (c <= 82) return 'Schauer';
          return 'Gewitter';
        }
        weatherForecast = cond(code);
      }
    }

    // ── appFavorites (REAL: appLauncherFavoritesProvider → count) ────────────
    // Same source as _AppFavoritesContent in general_widgets.dart
    int appFavorites = 0;
    try {
      final favs = read(appLauncherFavoritesProvider);
      appFavorites = favs.length;
    } catch (_) {}

    // ── quickActions (FALLBACK: keine Quelle; statische Liste, kein Snapshot-Wert) ──
    const String quickActions = ''; // FALLBACK: keine Quelle

    // ── caloriesBurned (REAL: HealthService.caloriesBurnedToday()) ───────────
    int caloriesBurned = 0;
    try {
      caloriesBurned = await HealthService.caloriesBurnedToday();
    } catch (_) {}

    // ── stepsWeekAvg (REAL: HealthService.stepsWeekAvg() last 7 days) ────────
    int stepsWeekAvg = 0;
    try {
      stepsWeekAvg = await HealthService.stepsWeekAvg();
    } catch (_) {}

    // ── supplementsToday (REAL: supplementDaoProvider.getTakenCountToday()) ───
    // Same source as supplementsTakenTodayProvider in nutrition_providers.dart
    int supplementsToday = 0;
    try {
      supplementsToday = await read(supplementDaoProvider).getTakenCountToday();
    } catch (_) {}

    // ── mealsToday (REAL: todaysMealEntriesProvider → distinct mealType count) ─
    // Same source as todaysMealEntriesProvider in nutrition_providers.dart
    int mealsToday = 0;
    try {
      final entries = await read(todaysMealEntriesProvider.future);
      mealsToday = entries.map((e) => e.mealType).toSet().length;
    } catch (_) {}

    // ── muscleHeatmap (REAL: Anzahl trainierter Muskelgruppen der letzten 7 Tage) ──
    int muscleHeatmap = 0;
    try {
      final dao = read(trainingDaoProvider);
      final recentSets = await dao.getRecentSets(const Duration(days: 7));
      if (recentSets.isNotEmpty) {
        final exercises = await dao.getAllExercisesOnce();
        final exerciseById = {for (final e in exercises) e.id: e};
        final groups = <String>{};
        for (final s in recentSets) {
          final ex = exerciseById[s.exerciseId];
          if (ex != null) groups.add(canonicalMuscleGroup(ex.muscleGroup));
        }
        muscleHeatmap = groups.length;
      }
    } catch (_) {}

    // ── lastWorkout (REAL: _recentSessionsProvider → first session name) ──────
    // Same source as _LastWorkoutContent in training_widgets.dart
    String lastWorkout = '';
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 365));
      final sessions =
          await read(trainingDaoProvider).getSessionsAfter(cutoff);
      if (sessions.isNotEmpty) {
        final sorted = [...sessions]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        final notes = sorted.first.notes?.trim() ?? '';
        lastWorkout = notes.isEmpty
            ? sorted.first.startedAt.toIso8601String().substring(0, 10)
            : notes;
      }
    } catch (_) {}

    // ── weeklyWorkouts (REAL: recentTrainingSetsProvider(7) → distinct session count) ──
    // Same source as _WeeklyWorkoutsContent in training_widgets.dart
    int weeklyWorkouts = 0;
    try {
      final sets = await read(recentTrainingSetsProvider(7).future);
      final sessionIds = sets.map((s) => s.sessionId).toSet();
      weeklyWorkouts = sessionIds.length;
    } catch (_) {}

    // ── personalRecords (REAL: recentTrainingSetsProvider(365) → distinct exercises with weight) ──
    // Same source as _PersonalRecordsContent in training_widgets.dart (best weight per exercise).
    // Scalar = number of exercises that have at least one weighted working set on record.
    int personalRecords = 0;
    try {
      final sets = await read(recentTrainingSetsProvider(365).future);
      personalRecords = sets
          .where((s) => (s.weightKg ?? 0) > 0)
          .map((s) => s.exerciseId)
          .toSet()
          .length;
    } catch (_) {}

    // ── restTimer (FALLBACK: keine Quelle; Rest-Timer ist transient, nicht gespeichert) ──
    const String restTimer = ''; // FALLBACK: keine Quelle

    // ── overdueTodos (REAL: planningDaoProvider.getAllTodos() → overdue count) ──
    // Same logic as _OverdueTodosContent in planning_widgets.dart (allTodos already read)
    final int overdueTodos = () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return allTodos
          .where((t) => !t.done &&
              t.dueDate != null &&
              t.dueDate!.isBefore(today))
          .length;
    }();

    // ── bestHabitStreak (REAL: planningDaoProvider.getRecentHabitLogs() → max streak) ──
    // Same logic as _BestHabitStreakContent in planning_widgets.dart
    int bestHabitStreak = 0;
    try {
      final logs = await read(planningDaoProvider).getRecentHabitLogs();
      final habits = await read(planningDaoProvider).getAllHabits();
      for (final habit in habits) {
        final habitLogs = logs
            .where((l) => l.habitId == habit.id && l.done)
            .map((l) => DateTime(l.logDate.year, l.logDate.month, l.logDate.day))
            .toSet();
        int streak = 0;
        var cursor = DateTime(
            DateTime.now().year, DateTime.now().month, DateTime.now().day);
        while (habitLogs.contains(cursor)) {
          streak++;
          cursor = cursor.subtract(const Duration(days: 1));
        }
        if (streak > bestHabitStreak) bestHabitStreak = streak;
      }
    } catch (_) {}

    // ── accountsOverview (REAL: accountsDaoProvider.getAll() → total balance) ─
    // Same source as _AccountsOverviewContent in budget_widgets.dart
    String accountsOverview = '';
    try {
      final accounts = await read(accountsDaoProvider).getAll();
      if (accounts.isNotEmpty) {
        final total = accounts.fold(0.0, (s, a) => s + a.balance);
        accountsOverview = '${total.toStringAsFixed(2)} €';
      }
    } catch (_) {}

    // ── recentTransaction (REAL: budgetDaoProvider.getRecentTransactions(limit:1)) ──
    // Same source as _RecentTransactionsContent in budget_widgets.dart which uses
    // recentTransactionItemsProvider(3) → dao.getRecentTransactions(limit:3).
    // Cross-month source so it never returns blank at start of a new month.
    // Format matches the tile's top row: description (= item.name) if non-empty,
    // else category name — but category lookup requires a separate DAO call, so we
    // store the raw description (same as item.name). This is the scalar the widget
    // key holds; the tile renders it with amount in a second column.
    String recentTransaction = '';
    try {
      final txs = await read(budgetDaoProvider).getRecentTransactions(limit: 1);
      if (txs.isNotEmpty) {
        final tx = txs.first;
        recentTransaction = tx.description;
      }
    } catch (_) {}

    // ── savingsGoal (REAL: budgetDaoProvider.getAllSavingsGoals() → first active) ──
    // Same source as _SavingsGoalContent in budget_widgets.dart
    String savingsGoal = '';
    try {
      final goals = await read(budgetDaoProvider).getAllSavingsGoals();
      if (goals.isNotEmpty) savingsGoal = goals.first.name;
    } catch (_) {}

    // ── recurringDue (REAL: budgetDaoProvider.getRecurringTransactions() → count) ──
    // Same source as _RecurringDueContent in budget_widgets.dart
    int recurringDue = 0;
    try {
      final recurring =
          await read(budgetDaoProvider).getRecurringTransactions();
      recurringDue = recurring.length;
    } catch (_) {}

    // ── monthTrend (REAL: trendDataProvider(sixMonths) → delta last two months) ──
    // Same source as _MonthTrendContent in budget_widgets.dart (net = income - expenses).
    String monthTrend = '';
    try {
      final bars = await read(trendDataProvider(TrendPeriod.sixMonths).future);
      if (bars.length >= 2) {
        final cur = bars.last.income - bars.last.expenses;
        final prev = bars[bars.length - 2].income - bars[bars.length - 2].expenses;
        final delta = cur - prev;
        final arrow = delta >= 0 ? '▲' : '▼';
        monthTrend =
            '$arrow ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)} €';
      }
    } catch (_) {}

    // ── yearHeatmap (REAL: datesWithDiaryEntriesProvider → total distinct-date count) ──
    // Same source as _YearHeatmapContent in diary_widgets.dart, which watches
    // datesWithDiaryEntriesProvider and shows `dates.length` ("N Tage mit Eintrag").
    // getDatesWithEntries() returns ALL diary dates (no year cap), matching the tile.
    int yearHeatmap = 0;
    try {
      final dates = await read(datesWithDiaryEntriesProvider.future);
      yearHeatmap = dates.length;
    } catch (_) {}

    // ── moodCalendar (REAL: healthDaoProvider.getMoodLogsAfter(monthStart) → avg mood) ──
    // Same source as _MoodCalendarContent in diary_widgets.dart
    int moodCalendar = 0;
    try {
      final now = DateTime.now();
      final monthStart = DateTime(now.year, now.month);
      final logs = await read(healthDaoProvider).getMoodLogsAfter(monthStart);
      if (logs.isNotEmpty) {
        final avg = logs.fold(0, (s, l) => s + l.moodScore) / logs.length;
        moodCalendar = avg.round();
      }
    } catch (_) {}

    // ── longestStreak (REAL: allTrackers → longest currently-running streak) ──────
    // Same logic as _LongestStreakContent in misc_widgets.dart: picks the tracker
    // with the highest _daysSince(startDate) among ALL trackers (active + inactive).
    // Note: this is NOT a "max historical" value — it is the oldest startDate
    // still recorded (i.e. longest currently-running streak, never reset).
    int longestStreak = 0;
    if (allTrackers.isNotEmpty) {
      for (final t in allTrackers) {
        final days = _daysSince(t.startDate);
        if (days > longestStreak) longestStreak = days;
      }
    }

    // ── allCounters (REAL: allTrackers → total count, unfiltered) ────────────────
    // Same source as _AllCountersContent in misc_widgets.dart, which renders ALL
    // trackers without an isActive filter (trackers list is unfiltered).
    final int allCounters = allTrackers.length;

    // ── pinnedNote (REAL: notesDaoProvider.getPinnedNotes() → first title) ────
    // Same source as _PinnedNoteContent in misc_widgets.dart
    String pinnedNote = '';
    try {
      final pins = await read(notesDaoProvider).getPinnedNotes();
      if (pins.isNotEmpty) {
        pinnedNote = pins.first.title.trim().isEmpty
            ? pins.first.content.trim()
            : pins.first.title.trim();
      }
    } catch (_) {}

    // ── v2 series (REAL where a source exists, else FALLBACK '') ─────────────

    // stepsWeek (REAL: HealthService.stepsWeek() — 7-day daily series)
    String stepsWeekSeries = '';
    try {
      final week = await HealthService.stepsWeek();
      if (week.isNotEmpty) stepsWeekSeries = WidgetSnapshot.encodeSeries(week);
    } catch (_) {}

    // weightHistory (REAL: getAllWeightLogs() → last 7, oldest→newest)
    String weightHistory = '';
    try {
      final logs = await read(healthDaoProvider).getAllWeightLogs(); // desc by date
      if (logs.isNotEmpty) {
        final last7 =
            logs.take(7).toList().reversed.map((l) => l.weightKg).toList();
        weightHistory = WidgetSnapshot.encodeSeries(last7);
      }
    } catch (_) {}

    // moodWeek (REAL: getMoodLogsAfter(7d) → latest score per day, 0 if none)
    String moodWeekSeries = '';
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final since = today.subtract(const Duration(days: 6));
      final logs = await read(healthDaoProvider).getMoodLogsAfter(since);
      if (logs.isNotEmpty) {
        final perDay = <num>[];
        for (var i = 6; i >= 0; i--) {
          final day = today.subtract(Duration(days: i));
          final dayLogs = logs.where((l) =>
              l.logDate.year == day.year &&
              l.logDate.month == day.month &&
              l.logDate.day == day.day);
          perDay.add(dayLogs.isEmpty ? 0 : dayLogs.last.moodScore);
        }
        moodWeekSeries = WidgetSnapshot.encodeSeries(perDay);
      }
    } catch (_) {}

    // sleepWeek (REAL: getRecentSleepLogs(7) → hours per day, 0 if none)
    String sleepWeekSeries = '';
    try {
      final logs = await read(healthDaoProvider).getRecentSleepLogs(7);
      if (logs.isNotEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final perDay = <num>[];
        for (var i = 6; i >= 0; i--) {
          final day = today.subtract(Duration(days: i));
          final dayLogs = logs.where((l) =>
              l.bedtime.year == day.year &&
              l.bedtime.month == day.month &&
              l.bedtime.day == day.day);
          if (dayLogs.isEmpty) {
            perDay.add(0);
          } else {
            final l = dayLogs.first;
            final h = l.wakeTime.difference(l.bedtime).inMinutes / 60.0;
            perDay.add(h < 0 ? 0 : (h > 24 ? 24 : h));
          }
        }
        sleepWeekSeries = WidgetSnapshot.encodeSeries(perDay);
      }
    } catch (_) {}

    // macroSplit (REAL: todaysTotals → protein,carbs,fat)
    final String macroSplit = todaysTotals != null
        ? WidgetSnapshot.encodeSeries(<num>[
            todaysTotals.protein.round(),
            todaysTotals.carbs.round(),
            todaysTotals.fat.round(),
          ])
        : '';

    // mealsTodayList (REAL: todaysMealEntriesProvider → distinct meal types)
    String mealsTodayList = '';
    try {
      final entries = await read(todaysMealEntriesProvider.future);
      final names = <String>[];
      for (final e in entries) {
        final n = e.mealType.trim();
        if (n.isNotEmpty && !names.contains(n)) names.add(n);
      }
      if (names.isNotEmpty) {
        mealsTodayList = WidgetSnapshot.encodeLabels(names.take(5).toList());
      }
    } catch (_) {}

    // habitWeek (REAL: getRecentHabitLogs → done count per day, last 7)
    String habitWeekSeries = '';
    try {
      final logs = await read(planningDaoProvider).getRecentHabitLogs();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final perDay = <num>[];
      for (var i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        perDay.add(logs
            .where((l) =>
                l.done &&
                l.logDate.year == day.year &&
                l.logDate.month == day.month &&
                l.logDate.day == day.day)
            .length);
      }
      if (perDay.any((v) => v > 0)) {
        habitWeekSeries = WidgetSnapshot.encodeSeries(perDay);
      }
    } catch (_) {}

    // categorySplit (REAL: categoryExpensesProvider → top amounts)
    String categorySplit = '';
    try {
      final now = DateTime.now();
      final cats =
          await read(categoryExpensesProvider((now.year, now.month)).future);
      if (cats.isNotEmpty) {
        categorySplit = WidgetSnapshot.encodeSeries(
            cats.take(5).map((c) => c.amount).toList());
      }
    } catch (_) {}

    // monthTrendSeries (REAL: trendDataProvider(sixMonths) → net per month)
    String monthTrendSeries = '';
    try {
      final bars = await read(trendDataProvider(TrendPeriod.sixMonths).future);
      if (bars.isNotEmpty) {
        monthTrendSeries = WidgetSnapshot.encodeSeries(
            bars.map((b) => (b.income - b.expenses).round()).toList());
      }
    } catch (_) {}

    // counters (REAL: allTrackers → "name days" labels)
    String counters = '';
    if (allTrackers.isNotEmpty) {
      final labels = allTrackers
          .take(5)
          .map((t) => '${t.name} ${_daysSince(t.startDate)}')
          .toList();
      counters = WidgetSnapshot.encodeLabels(labels);
    }

    // quote (REAL: static rotating list, index by day of month)
    const quotes = <String>[
      'Jeder Tag zählt.',
      'Kleine Schritte, große Wirkung.',
      'Bleib dran — du schaffst das.',
      'Fortschritt statt Perfektion.',
      'Heute ist ein guter Tag.',
      'Disziplin schlägt Motivation.',
      'Erschaffe deinen Traum.',
    ];
    final quote = quotes[DateTime.now().day % quotes.length];

    // FALLBACK '' (keine geeignete Einzel-Quelle): volumeWeek, todayAgenda,
    // countdownLabel, countdownDays.

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
      // Phase 3
      mapPreview: mapPreview,
      clockDate: clockDate,
      weatherTemp: weatherTemp,
      weatherForecast: weatherForecast,
      appFavorites: appFavorites,
      quickActions: quickActions,
      caloriesBurned: caloriesBurned,
      stepsWeekAvg: stepsWeekAvg,
      supplementsToday: supplementsToday,
      mealsToday: mealsToday,
      muscleHeatmap: muscleHeatmap,
      lastWorkout: lastWorkout,
      weeklyWorkouts: weeklyWorkouts,
      personalRecords: personalRecords,
      restTimer: restTimer,
      overdueTodos: overdueTodos,
      bestHabitStreak: bestHabitStreak,
      accountsOverview: accountsOverview,
      recentTransaction: recentTransaction,
      savingsGoal: savingsGoal,
      recurringDue: recurringDue,
      monthTrend: monthTrend,
      yearHeatmap: yearHeatmap,
      moodCalendar: moodCalendar,
      longestStreak: longestStreak,
      allCounters: allCounters,
      pinnedNote: pinnedNote,
      // v2 series
      stepsWeek: stepsWeekSeries,
      sleepWeek: sleepWeekSeries,
      weightHistory: weightHistory,
      moodWeek: moodWeekSeries,
      macroSplit: macroSplit,
      mealsTodayList: mealsTodayList,
      habitWeek: habitWeekSeries,
      categorySplit: categorySplit,
      monthTrendSeries: monthTrendSeries,
      counters: counters,
      quote: quote,
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
