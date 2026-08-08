import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../data/database/traum_database.dart';
import 'health_score_calculator.dart';
import 'health_score_result.dart';

final healthScoreProvider = FutureProvider.autoDispose<HealthScoreResult>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(preferencesRepositoryProvider);
  final now = DateTime.now();
  final sevenDaysAgo = now.subtract(const Duration(days: 7));
  final weekStart = now.subtract(Duration(days: now.weekday - 1));
  final weekStartDay = DateTime(weekStart.year, weekStart.month, weekStart.day);

  final sessions = await db.trainingDao.getSessionsAfter(weekStartDay);
  final workoutGoal = prefs.workoutGoalPerWeek;

  final nutritionLogs = await db.nutritionDao.getNutritionLogsAfter(sevenDaysAgo);
  final waterLogs = await db.nutritionDao.getWaterLogsAfter(sevenDaysAgo);
  final calorieGoal = prefs.kcalGoal.toDouble();
  final proteinGoal = prefs.proteinGoalG.toDouble();
  final waterGoal = prefs.waterGoalMl.toDouble();

  final avgCal = nutritionLogs.isEmpty
      ? 0.0
      : nutritionLogs.map((l) => l.kcal).reduce((a, b) => a + b) / 7;
  final avgProt = nutritionLogs.isEmpty
      ? 0.0
      : nutritionLogs.map((l) => l.proteinG).reduce((a, b) => a + b) / 7;
  final avgWater = waterLogs.isEmpty
      ? 0.0
      : waterLogs.map((l) => l.amountMl.toDouble()).reduce((a, b) => a + b) / 7;

  final sleepLogs = await db.healthDao.getSleepLogsAfter(sevenDaysAgo);
  final avgSleep = sleepLogs.isEmpty
      ? 0.0
      : sleepLogs
              .map((l) => l.wakeTime.difference(l.bedtime).inMinutes / 60.0)
              .reduce((a, b) => a + b) /
          sleepLogs.length;

  final suppTotal = await db.supplementDao.getActiveCount();
  final suppToday = await db.supplementDao.getTakenCountToday();

  final medTotal = await db.medicationDao.getActiveCount();
  final medToday = await db.medicationDao.getTakenCountToday();

  final moodLogs = await db.healthDao.getMoodLogsAfter(sevenDaysAgo);
  final moodScores = moodLogs.map((l) => l.moodScore).toList();

  return HealthScoreCalculator.calculate(
    workoutsThisWeek: sessions.length,
    workoutGoalPerWeek: workoutGoal,
    avgCaloriesLast7Days: avgCal,
    calorieGoal: calorieGoal,
    avgProteinLast7Days: avgProt,
    proteinGoal: proteinGoal,
    avgWaterLast7Days: avgWater,
    waterGoalMl: waterGoal,
    avgSleepHoursLast7Days: avgSleep,
    supplementsTakenToday: suppToday,
    supplementsTotal: suppTotal,
    medicationsTakenToday: medToday,
    medicationsTotal: medTotal,
    moodScoresLast7Days: moodScores,
  );
});

// Score history for the last 7 days (oldest first)
final healthScoreHistoryProvider = FutureProvider.autoDispose<List<int>>((ref) async {
  final db = ref.watch(databaseProvider);
  final prefs = ref.watch(preferencesRepositoryProvider);

  final calorieGoal = prefs.kcalGoal.toDouble();
  final proteinGoal = prefs.proteinGoalG.toDouble();
  final waterGoal = prefs.waterGoalMl.toDouble();
  final workoutGoal = prefs.workoutGoalPerWeek;

  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final historyStart = todayStart.subtract(const Duration(days: 6)); // 7 days incl. today
  // Sessions need to go back to the Monday of the week containing
  // historyStart, not just historyStart itself — "workouts this week" for
  // the oldest day in the graph still needs that whole week's sessions.
  final earliestMonday =
      historyStart.subtract(Duration(days: historyStart.weekday - 1));

  // One query per data source for the whole window instead of one per
  // data source PER DAY (was 5 x 7 = 35 sequential, overlapping-range
  // queries) — fetched in parallel, then bucketed by day in memory below.
  final results = await Future.wait([
    db.trainingDao.getSessionsAfter(earliestMonday),
    db.nutritionDao.getNutritionLogsAfter(historyStart),
    db.nutritionDao.getWaterLogsAfter(historyStart),
    db.healthDao.getSleepLogsAfter(historyStart),
    db.healthDao.getMoodLogsAfter(historyStart),
    db.supplementDao.getActiveCount(),
    db.medicationDao.getActiveCount(),
  ]);
  final sessions = results[0] as List<WorkoutSession>;
  final nutritionLogs = results[1] as List<NutritionLog>;
  final waterLogs = results[2] as List<WaterLog>;
  final sleepLogs = results[3] as List<SleepLog>;
  final moodLogs = results[4] as List<MoodLog>;
  final suppTotal = results[5] as int;
  final medTotal = results[6] as int;

  final scores = <int>[];

  for (int i = 6; i >= 0; i--) {
    final day = todayStart.subtract(Duration(days: i));
    final dayEnd = day.add(const Duration(days: 1));
    // Calendar week containing `day` (Monday-start), matching how
    // healthScoreProvider above defines "this week" for today — a single
    // day's session count compared against a *weekly* goal would make the
    // history graph read as permanently under-achieving on workouts.
    final weekStart = day.subtract(Duration(days: day.weekday - 1));

    final workoutsThisWeek = sessions
        .where((s) =>
            !s.startedAt.isBefore(weekStart) && s.startedAt.isBefore(dayEnd))
        .length;

    final dayNut = nutritionLogs
        .where((l) => !l.logDate.isBefore(day) && l.logDate.isBefore(dayEnd))
        .toList();
    final dayWater = waterLogs
        .where((l) => !l.logDate.isBefore(day) && l.logDate.isBefore(dayEnd))
        .toList();
    final daySleep = sleepLogs
        .where((l) => !l.bedtime.isBefore(day) && l.bedtime.isBefore(dayEnd))
        .toList();
    final dayMood = moodLogs
        .where((l) => !l.logDate.isBefore(day) && l.logDate.isBefore(dayEnd))
        .toList();

    final dayCal = dayNut.isEmpty ? 0.0 : dayNut.map((l) => l.kcal).reduce((a, b) => a + b);
    final dayProt = dayNut.isEmpty ? 0.0 : dayNut.map((l) => l.proteinG).reduce((a, b) => a + b);
    final dayWaterMl = dayWater.isEmpty ? 0.0 : dayWater.map((l) => l.amountMl.toDouble()).reduce((a, b) => a + b);
    final daySleepHours = daySleep.isEmpty
        ? 0.0
        : daySleep.map((l) => l.wakeTime.difference(l.bedtime).inMinutes / 60.0).reduce((a, b) => a + b) / daySleep.length;
    final dayMoodScores = dayMood.map((l) => l.moodScore).toList();

    final result = HealthScoreCalculator.calculate(
      workoutsThisWeek: workoutsThisWeek,
      workoutGoalPerWeek: workoutGoal,
      avgCaloriesLast7Days: dayCal,
      calorieGoal: calorieGoal,
      avgProteinLast7Days: dayProt,
      proteinGoal: proteinGoal,
      avgWaterLast7Days: dayWaterMl,
      waterGoalMl: waterGoal,
      avgSleepHoursLast7Days: daySleepHours,
      supplementsTakenToday: 0,
      supplementsTotal: suppTotal,
      medicationsTakenToday: 0,
      medicationsTotal: medTotal,
      moodScoresLast7Days: dayMoodScores,
    );
    scores.add(result.gesamtScore);
  }

  return scores;
});
