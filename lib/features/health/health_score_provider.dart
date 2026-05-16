import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
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

  final suppTotal = await db.supplementDao.getActiveCount();
  final medTotal = await db.medicationDao.getActiveCount();

  final now = DateTime.now();
  final scores = <int>[];

  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dayStart = DateTime(day.year, day.month, day.day);
    final dayEnd = dayStart.add(const Duration(days: 1));

    final sessions = await db.trainingDao.getSessionsAfter(dayStart);
    final daySessionCount = sessions
        .where((s) => s.startedAt.isBefore(dayEnd))
        .length;

    final nutLogs = await db.nutritionDao.getNutritionLogsAfter(dayStart);
    final dayNut = nutLogs.where((l) => l.logDate.isBefore(dayEnd)).toList();
    final dayWater = (await db.nutritionDao.getWaterLogsAfter(dayStart))
        .where((l) => l.logDate.isBefore(dayEnd))
        .toList();

    final sleepLogs = await db.healthDao.getSleepLogsAfter(dayStart);
    final daySleep = sleepLogs.where((l) => l.bedtime.isBefore(dayEnd)).toList();

    final moodLogs = await db.healthDao.getMoodLogsAfter(dayStart);
    final dayMood = moodLogs.where((l) => l.logDate.isBefore(dayEnd)).toList();

    final avgCal = dayNut.isEmpty ? 0.0 : dayNut.map((l) => l.kcal).reduce((a, b) => a + b);
    final avgProt = dayNut.isEmpty ? 0.0 : dayNut.map((l) => l.proteinG).reduce((a, b) => a + b);
    final avgWater = dayWater.isEmpty ? 0.0 : dayWater.map((l) => l.amountMl.toDouble()).reduce((a, b) => a + b);
    final avgSleep = daySleep.isEmpty
        ? 0.0
        : daySleep.map((l) => l.wakeTime.difference(l.bedtime).inMinutes / 60.0).reduce((a, b) => a + b) / daySleep.length;
    final moodScores = dayMood.map((l) => l.moodScore).toList();

    final result = HealthScoreCalculator.calculate(
      workoutsThisWeek: daySessionCount,
      workoutGoalPerWeek: workoutGoal,
      avgCaloriesLast7Days: avgCal,
      calorieGoal: calorieGoal,
      avgProteinLast7Days: avgProt,
      proteinGoal: proteinGoal,
      avgWaterLast7Days: avgWater,
      waterGoalMl: waterGoal,
      avgSleepHoursLast7Days: avgSleep,
      supplementsTakenToday: 0,
      supplementsTotal: suppTotal,
      medicationsTakenToday: 0,
      medicationsTotal: medTotal,
      moodScoresLast7Days: moodScores,
    );
    scores.add(result.gesamtScore);
  }

  return scores;
});
