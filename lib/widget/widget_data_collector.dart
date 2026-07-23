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
  /// Every read is wrapped via [_safe] so one failing read cannot crash the
  /// entire collection — the corresponding [WidgetSnapshot.empty()]/local
  /// default is used as fallback, exactly as before.
  ///
  /// All independent reads are kicked off up front (as not-yet-awaited
  /// futures) instead of one after another, so they execute concurrently on
  /// the DB's background isolate / native platform channels rather than
  /// paying for N sequential round trips. A handful of reads that used to be
  /// issued twice for two derived metrics (e.g. `getAllWeightLogs` for both
  /// `weightKg` and `weightHistory`) are now fetched once and shared between
  /// their consumers below.
  static Future<WidgetSnapshot> collect(
    R Function<R>(ProviderListenable<R> provider) read,
  ) async {
    final empty = WidgetSnapshot.empty();

    // ── Kick off every independent read concurrently ────────────────────────
    final stepsTodayF = _safe(HealthService.stepsToday, empty.steps);
    final heartRateF = _safe(HealthService.latestHeartRate, empty.heartRate);
    final activeMinutesF = _safe(HealthService.activeMinutesToday, 0);
    final caloriesBurnedF = _safe(HealthService.caloriesBurnedToday, 0);
    final stepsWeekAvgF = _safe(HealthService.stepsWeekAvg, 0);
    final stepsWeekF = _safe(HealthService.stepsWeek, null);

    final sleepLogs2F =
        _safe(() => read(healthDaoProvider).getRecentSleepLogs(2), null);
    final sleepWeekLogsF =
        _safe(() => read(healthDaoProvider).getRecentSleepLogs(7), null);
    final moodLogF = _safe(() => read(healthDaoProvider).getLatestMood(), null);
    final weightLogsF =
        _safe(() => read(healthDaoProvider).getAllWeightLogs(), null);
    final moodCalendarLogsF = _safe(() {
      final now = DateTime.now();
      return read(healthDaoProvider)
          .getMoodLogsAfter(DateTime(now.year, now.month));
    }, null);
    final moodWeekLogsF = _safe(() {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return read(healthDaoProvider)
          .getMoodLogsAfter(today.subtract(const Duration(days: 6)));
    }, null);

    final todaysTotalsF = _safe(() => read(todaysTotalsProvider.future), null);
    final waterMlTodayF =
        _safe(() => read(waterTodaySnapshotProvider.future), empty.waterMl);
    final lastMealF = _safe(() => read(lastMealProvider.future), null);
    final todaysMealEntriesF =
        _safe(() => read(todaysMealEntriesProvider.future), null);
    final supplementsTodayF =
        _safe(() => read(supplementDaoProvider).getTakenCountToday(), 0);

    final allTodosF =
        _safe(() => read(planningDaoProvider).getAllTodos(), null);
    final nextAppointmentF =
        _safe(() => read(planningDaoProvider).getNextAppointment(), null);
    final allHabitsF =
        _safe(() => read(planningDaoProvider).getAllHabits(), null);
    final habitLogsForDateF = _safe(
        () => read(planningDaoProvider).getHabitLogsForDate(DateTime.now()),
        null);
    final recentHabitLogsF =
        _safe(() => read(planningDaoProvider).getRecentHabitLogs(), null);

    final activeMedsF =
        _safe(() => read(medicationDaoProvider).getActiveMedications(), null);
    final medsTakenTodayF =
        _safe(() => read(medicationDaoProvider).getTakenCountToday(), 0);

    final healthScoreF = _safe(() => read(healthScoreProvider.future), null);

    final nextWorkoutF = _safe<String>(() async {
      final plan = await read(activePlanProvider.future);
      if (plan == null) return '';
      final days = await read(trainingDaoProvider).getDaysForPlan(plan.id);
      if (days.isEmpty) return '';
      final today = DateTime.now().weekday;
      final ordered = [...days]
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      final day = ordered.firstWhere((d) => d.dayOfWeek == today,
          orElse: () => ordered.first);
      return day.name;
    }, '');
    final recentSets7F =
        _safe(() => read(recentTrainingSetsProvider(7).future), null);
    final recentSets365F =
        _safe(() => read(recentTrainingSetsProvider(365).future), null);
    final sessionsAfter365F = _safe(
        () => read(trainingDaoProvider).getSessionsAfter(
            DateTime.now().subtract(const Duration(days: 365))),
        null);
    final muscleHeatmapF = _safe<int>(() async {
      final dao = read(trainingDaoProvider);
      final recentSets = await dao.getRecentSets(const Duration(days: 7));
      if (recentSets.isEmpty) return 0;
      final exercises = await dao.getAllExercisesOnce();
      final exerciseById = {for (final e in exercises) e.id: e};
      final groups = <String>{};
      for (final s in recentSets) {
        final ex = exerciseById[s.exerciseId];
        if (ex != null) groups.add(canonicalMuscleGroup(ex.muscleGroup));
      }
      return groups.length;
    }, 0);

    final monthTxsF = _safe(() {
      final now = DateTime.now();
      return read(budgetDaoProvider)
          .getTransactionsForMonth(now.year, now.month);
    }, null);
    final categoryExpensesF = _safe(() {
      final now = DateTime.now();
      return read(categoryExpensesProvider((now.year, now.month)).future);
    }, null);
    final accountsF = _safe(() => read(accountsDaoProvider).getAll(), null);
    final recentTransactionsF = _safe(
        () => read(budgetDaoProvider).getRecentTransactions(limit: 1), null);
    final savingsGoalsF =
        _safe(() => read(budgetDaoProvider).getAllSavingsGoals(), null);
    final recurringF = _safe(
        () => read(budgetDaoProvider).getRecurringTransactions(), null);
    final trendBarsF = _safe(
        () => read(trendDataProvider(TrendPeriod.sixMonths).future), null);
    final budgetLimitRawF = _safe(() async {
      return read(sharedPreferencesProvider).getDouble('monthly_budget') ?? 0.0;
    }, 0.0);

    final writeStreakF = _safe(() => read(diaryStreakProvider.future), 0);
    final lastDiaryEntryF =
        _safe(() => read(diaryDaoProvider).getLastEntry(), null);
    final entriesThisMonthF = _safe(() {
      final now = DateTime.now();
      return read(diaryEntriesForMonthProvider((now.year, now.month)).future);
    }, null);
    final yearHeatmapF =
        _safe(() => read(datesWithDiaryEntriesProvider.future), null);

    final allTrackersF =
        _safe(() => read(abstinenceDaoProvider).getAllTrackers(), null);

    final lastIntakeF =
        _safe(() => read(substanceDaoProvider).getLastIntake(), null);
    final takenTodayF =
        _safe(() => read(substanceDaoProvider).getIntakeCountToday(), 0);

    final latestPeriodEntryF =
        _safe(() => read(periodDaoProvider).getLatestPeriodEntry(), null);

    final notesCountF =
        _safe(() => read(notesDaoProvider).getActiveNotes(), null);
    final lastNoteF =
        _safe(() => read(notesDaoProvider).getRecentNotes(1), null);
    final pinnedNoteF =
        _safe(() => read(notesDaoProvider).getPinnedNotes(), null);

    final placesCountF = _safe(() => read(mapMarkersDaoProvider).getAll(), null);
    final lastPhotoF =
        _safe(() => read(markerPhotosDaoProvider).getAll(), null);

    // ── Sync reads (no I/O — cheap, order doesn't matter) ───────────────────
    int stepsGoal = empty.stepsGoal;
    try {
      stepsGoal = read(stepsGoalProvider);
    } catch (_) {}
    int kcalGoal = empty.kcalGoal;
    try {
      kcalGoal = read(kcalGoalProvider);
    } catch (_) {}
    int waterGoalMl = empty.waterGoalMl;
    try {
      waterGoalMl = read(waterGoalMlProvider);
    } catch (_) {}
    int proteinGoal = empty.proteinGoal;
    try {
      proteinGoal = read(proteinGoalGProvider);
    } catch (_) {}
    Map<String, dynamic>? weatherCurrent;
    try {
      final prefs = read(sharedPreferencesProvider);
      final cache = prefs.getString('weather_cache');
      if (cache != null && cache.isNotEmpty) {
        final data = jsonDecode(cache) as Map<String, dynamic>?;
        weatherCurrent = data?['current'] as Map<String, dynamic>?;
      }
    } catch (_) {}
    int appFavorites = 0;
    try {
      final favs = read(appLauncherFavoritesProvider);
      appFavorites = favs.length;
    } catch (_) {}

    // ── Await + derive (same logic/order as before, just sourced from the
    // already-in-flight futures above instead of awaiting fresh each time) ──

    final stepsToday = await stepsTodayF;
    final heartRate = await heartRateF;
    final activeMinutes = await activeMinutesF;
    final caloriesBurned = await caloriesBurnedF;
    final stepsWeekAvg = await stepsWeekAvgF;

    double sleepHours = empty.sleepHours;
    try {
      final logs = _or(await sleepLogs2F);
      if (logs.isNotEmpty) {
        final latest =
            logs.reduce((a, b) => a.bedtime.isAfter(b.bedtime) ? a : b);
        final hours =
            latest.wakeTime.difference(latest.bedtime).inMinutes / 60.0;
        if (hours > 0) sleepHours = hours;
      }
    } catch (_) {}

    int mood = empty.mood;
    try {
      final moodLog = await moodLogF;
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

    final todaysTotals = await todaysTotalsF;
    final int kcalToday =
        todaysTotals != null ? todaysTotals.calories.round() : empty.kcal;
    final int proteinToday =
        todaysTotals != null ? todaysTotals.protein.round() : empty.protein;
    final int carbs = todaysTotals != null ? todaysTotals.carbs.round() : 0;
    final int fat = todaysTotals != null ? todaysTotals.fat.round() : 0;

    final waterMlToday = await waterMlTodayF;

    final allTodos = _or(await allTodosF);
    String? nextTodoTitle;
    try {
      final open = allTodos.where((t) => !t.done).toList();
      if (open.isNotEmpty) nextTodoTitle = open.first.title;
    } catch (_) {}
    final int openTodos = allTodos.where((t) => !t.done).length;
    final int overdueTodos = () {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      return allTodos
          .where((t) =>
              !t.done && t.dueDate != null && t.dueDate!.isBefore(today))
          .length;
    }();

    int healthScore = 0;
    try {
      final result = await healthScoreF;
      if (result != null) healthScore = result.gesamtScore;
    } catch (_) {}

    final weightLogs = _or(await weightLogsF);
    double weightKg = 0.0;
    try {
      if (weightLogs.isNotEmpty) {
        weightKg = weightLogs.first.weightKg; // ordered desc by logDate
      }
    } catch (_) {}
    String weightHistory = '';
    try {
      if (weightLogs.isNotEmpty) {
        final last7 =
            weightLogs.take(7).toList().reversed.map((l) => l.weightKg).toList();
        weightHistory = WidgetSnapshot.encodeSeries(last7);
      }
    } catch (_) {}

    String lastMeal = '';
    try {
      final meal = await lastMealF;
      if (meal != null) lastMeal = meal.name;
    } catch (_) {}

    final nextWorkout = await nextWorkoutF;

    final recentSets7 = _or(await recentSets7F);
    int weeklyVolume = 0;
    try {
      weeklyVolume = recentSets7.where((s) => !s.isWarmup).length;
    } catch (_) {}
    int weeklyWorkouts = 0;
    try {
      weeklyWorkouts = recentSets7.map((s) => s.sessionId).toSet().length;
    } catch (_) {}

    int personalRecords = 0;
    try {
      final sets = _or(await recentSets365F);
      personalRecords = sets
          .where((s) => (s.weightKg ?? 0) > 0)
          .map((s) => s.exerciseId)
          .toSet()
          .length;
    } catch (_) {}

    final sessionsAfter365 = _or(await sessionsAfter365F);
    int trainingStreak = 0;
    try {
      final sessionsSorted = [...sessionsAfter365]
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
    String lastWorkout = '';
    try {
      if (sessionsAfter365.isNotEmpty) {
        final sorted = [...sessionsAfter365]
          ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
        final notes = sorted.first.notes?.trim() ?? '';
        lastWorkout = notes.isEmpty
            ? sorted.first.startedAt.toIso8601String().substring(0, 10)
            : notes;
      }
    } catch (_) {}

    final muscleHeatmap = await muscleHeatmapF;

    String nextAppointment = '';
    try {
      final appt = await nextAppointmentF;
      if (appt != null) nextAppointment = appt.title;
    } catch (_) {}

    final allHabits = _or(await allHabitsF);
    int habitsDone = 0;
    int habitsTotal = 0;
    try {
      final todayLogs = _or(await habitLogsForDateF);
      habitsTotal = allHabits.length;
      final doneIds =
          todayLogs.where((l) => l.done).map((l) => l.habitId).toSet();
      habitsDone = doneIds.length;
    } catch (_) {}

    final recentHabitLogs = _or(await recentHabitLogsF);
    int bestHabitStreak = 0;
    try {
      for (final habit in allHabits) {
        final habitLogs = recentHabitLogs
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
    String habitWeekSeries = '';
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final perDay = <num>[];
      for (var i = 6; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        perDay.add(recentHabitLogs
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

    int medsTotal = 0;
    try {
      final meds = _or(await activeMedsF);
      medsTotal = meds
          .where(
              (m) => m.timings.trim().isNotEmpty && m.timings.trim() != '[]')
          .length;
    } catch (_) {}
    int medsDone = 0;
    try {
      medsDone = await medsTakenTodayF;
    } catch (_) {}

    double balanceMonth = 0.0;
    double incomeMonth = 0.0;
    double expenseMonth = 0.0;
    try {
      final txs = _or(await monthTxsF);
      incomeMonth =
          txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
      expenseMonth = txs
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      balanceMonth = incomeMonth - expenseMonth;
    } catch (_) {}
    final double budgetSpent = expenseMonth;

    double budgetLimit = 0.0;
    try {
      budgetLimit = await budgetLimitRawF;
    } catch (_) {}

    final categoryExpenses = _or(await categoryExpensesF);
    String topCategory = '';
    try {
      if (categoryExpenses.isNotEmpty) {
        topCategory = categoryExpenses.first.category.name;
      }
    } catch (_) {}
    String categorySplit = '';
    try {
      if (categoryExpenses.isNotEmpty) {
        categorySplit = WidgetSnapshot.encodeSeries(
            categoryExpenses.take(5).map((c) => c.amount).toList());
      }
    } catch (_) {}

    String accountsOverview = '';
    try {
      final accounts = _or(await accountsF);
      if (accounts.isNotEmpty) {
        final total = accounts.fold(0.0, (s, a) => s + a.balance);
        accountsOverview = '${total.toStringAsFixed(2)} €';
      }
    } catch (_) {}

    String recentTransaction = '';
    try {
      final txs = _or(await recentTransactionsF);
      if (txs.isNotEmpty) {
        recentTransaction = txs.first.description;
      }
    } catch (_) {}

    String savingsGoal = '';
    try {
      final goals = _or(await savingsGoalsF);
      if (goals.isNotEmpty) savingsGoal = goals.first.name;
    } catch (_) {}

    int recurringDue = 0;
    try {
      final recurring = _or(await recurringF);
      recurringDue = recurring.length;
    } catch (_) {}

    final trendBars = _or(await trendBarsF);
    String monthTrend = '';
    try {
      if (trendBars.length >= 2) {
        final cur = trendBars.last.income - trendBars.last.expenses;
        final prev = trendBars[trendBars.length - 2].income -
            trendBars[trendBars.length - 2].expenses;
        final delta = cur - prev;
        final arrow = delta >= 0 ? '▲' : '▼';
        monthTrend =
            '$arrow ${delta >= 0 ? '+' : ''}${delta.toStringAsFixed(0)} €';
      }
    } catch (_) {}
    String monthTrendSeries = '';
    try {
      if (trendBars.isNotEmpty) {
        monthTrendSeries = WidgetSnapshot.encodeSeries(
            trendBars.map((b) => (b.income - b.expenses).round()).toList());
      }
    } catch (_) {}

    int writeStreak = 0;
    try {
      writeStreak = await writeStreakF;
    } catch (_) {}

    String lastEntry = '';
    try {
      final entry = await lastDiaryEntryF;
      if (entry != null) lastEntry = entry.note.trim();
    } catch (_) {}

    int entriesThisMonth = 0;
    try {
      final entries = _or(await entriesThisMonthF);
      entriesThisMonth = entries.length;
    } catch (_) {}

    int yearHeatmap = 0;
    try {
      yearHeatmap = (await yearHeatmapF)?.length ?? 0;
    } catch (_) {}

    int moodCalendar = 0;
    try {
      final logs = _or(await moodCalendarLogsF);
      if (logs.isNotEmpty) {
        final avg = logs.fold(0, (s, l) => s + l.moodScore) / logs.length;
        moodCalendar = avg.round();
      }
    } catch (_) {}

    final allTrackers = _or(await allTrackersF);

    String abstinenceTitle = '';
    String abstinenceDuration = '';
    try {
      final active = allTrackers.where((t) => t.isActive).toList();
      if (active.isNotEmpty) {
        final best = active.reduce((a, b) =>
            _daysSince(a.startDate) >= _daysSince(b.startDate) ? a : b);
        abstinenceTitle = best.name;
        final days = _daysSince(best.startDate);
        abstinenceDuration = '$days ${days == 1 ? 'Tag' : 'Tage'}';
      }
    } catch (_) {}

    double moneySaved = 0.0;
    try {
      for (final t in allTrackers) {
        if (t.isActive == true && t.costPerDay != null) {
          moneySaved += (t.costPerDay as double) * _daysSince(t.startDate);
        }
      }
    } catch (_) {}

    int longestStreak = 0;
    try {
      if (allTrackers.isNotEmpty) {
        for (final t in allTrackers) {
          final days = _daysSince(t.startDate);
          if (days > longestStreak) longestStreak = days;
        }
      }
    } catch (_) {}

    final int allCounters = allTrackers.length;

    String counters = '';
    try {
      if (allTrackers.isNotEmpty) {
        final labels = allTrackers
            .take(5)
            .map((t) => '${t.name} ${_daysSince(t.startDate)}')
            .toList();
        counters = WidgetSnapshot.encodeLabels(labels);
      }
    } catch (_) {}

    String lastIntake = '';
    try {
      final last = await lastIntakeF;
      if (last != null) lastIntake = last.substanceName;
    } catch (_) {}

    int takenToday = 0;
    try {
      takenToday = await takenTodayF;
    } catch (_) {}

    final latestPeriodEntry = await latestPeriodEntryF;

    int cycleDay = 0;
    try {
      if (latestPeriodEntry != null) {
        cycleDay = _daysSince(latestPeriodEntry.startDate) + 1;
      }
    } catch (_) {}

    // getCalculationForEntry depends on latestPeriodEntry's id, so it can
    // only be fetched once that's known — still fetched once here and shared
    // between periodPhase and nextPeriodDays instead of being queried twice.
    dynamic periodCalc;
    if (latestPeriodEntry != null) {
      try {
        periodCalc = await read(periodDaoProvider)
            .getCalculationForEntry(latestPeriodEntry.id);
      } catch (_) {}
    }

    String periodPhase = '';
    try {
      if (latestPeriodEntry != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final start = DateTime(latestPeriodEntry.startDate.year,
            latestPeriodEntry.startDate.month, latestPeriodEntry.startDate.day);
        final end = latestPeriodEntry.endDate;
        final inPeriod = !today.isBefore(start) &&
            (end == null
                ? today.difference(start).inDays < 7
                : !today.isAfter(DateTime(end.year, end.month, end.day)));
        if (inPeriod) {
          periodPhase = 'Menstruation';
        } else {
          final calc = periodCalc;
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

    int nextPeriodDays = 0;
    try {
      if (latestPeriodEntry != null) {
        final calc = periodCalc;
        final predicted = calc?.nextPeriodPredicted;
        if (predicted != null) {
          final now = DateTime.now();
          final today = DateTime(now.year, now.month, now.day);
          final target =
              DateTime(predicted.year, predicted.month, predicted.day);
          final diff = target.difference(today).inDays;
          if (diff >= 0) nextPeriodDays = diff;
        }
      }
    } catch (_) {}

    int notesCount = 0;
    try {
      final notes = _or(await notesCountF);
      notesCount = notes.length;
    } catch (_) {}

    String lastNote = '';
    try {
      final notes = _or(await lastNoteF);
      if (notes.isNotEmpty) {
        lastNote = notes.first.title.trim().isEmpty
            ? notes.first.content.trim()
            : notes.first.title.trim();
      }
    } catch (_) {}

    String pinnedNote = '';
    try {
      final pins = _or(await pinnedNoteF);
      if (pins.isNotEmpty) {
        pinnedNote = pins.first.title.trim().isEmpty
            ? pins.first.content.trim()
            : pins.first.title.trim();
      }
    } catch (_) {}

    int placesCount = 0;
    try {
      final markers = _or(await placesCountF);
      placesCount = markers.length;
    } catch (_) {}

    String lastPhoto = '';
    try {
      final photos = _or(await lastPhotoF);
      if (photos.isNotEmpty) {
        final d = photos.first.takenAt;
        lastPhoto =
            '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';
      }
    } catch (_) {}

    final int mapPreview = placesCount;

    // ── clockDate (FALLBACK: keine Quelle; live clock renders in widget, not snapshot) ────
    const String clockDate = ''; // FALLBACK: keine Quelle

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

    // ── quickActions (FALLBACK: keine Quelle; statische Liste, kein Snapshot-Wert) ──
    const String quickActions = ''; // FALLBACK: keine Quelle

    int supplementsToday = 0;
    try {
      supplementsToday = await supplementsTodayF;
    } catch (_) {}

    final todaysMealEntries = _or(await todaysMealEntriesF);
    int mealsToday = 0;
    try {
      mealsToday = todaysMealEntries.map((e) => e.mealType).toSet().length;
    } catch (_) {}
    String mealsTodayList = '';
    try {
      final names = <String>[];
      for (final e in todaysMealEntries) {
        final n = e.mealType.trim();
        if (n.isNotEmpty && !names.contains(n)) names.add(n);
      }
      if (names.isNotEmpty) {
        mealsTodayList = WidgetSnapshot.encodeLabels(names.take(5).toList());
      }
    } catch (_) {}

    // ── restTimer (FALLBACK: transient, nie gespeichert) ─────────────────────
    const String restTimer = ''; // FALLBACK: keine Quelle

    String stepsWeekSeries = '';
    try {
      final week = _or(await stepsWeekF);
      if (week.isNotEmpty) stepsWeekSeries = WidgetSnapshot.encodeSeries(week);
    } catch (_) {}

    String moodWeekSeries = '';
    try {
      final logs = _or(await moodWeekLogsF);
      if (logs.isNotEmpty) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
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

    String sleepWeekSeries = '';
    try {
      final logs = _or(await sleepWeekLogsF);
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

  /// Runs [fn], returning [fallback] if it throws. Used to launch every read
  /// as an independent future up front (concurrently) while preserving the
  /// original "one failing read can never crash the whole collection" rule.
  static Future<T> _safe<T>(Future<T> Function() fn, T fallback) async {
    try {
      return await fn();
    } catch (_) {
      return fallback;
    }
  }

  /// Null → empty-list coalesce with the element type inferred from [xs],
  /// so callers never need to name a concrete row type.
  static List<T> _or<T>(List<T>? xs) => xs ?? const [];

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
