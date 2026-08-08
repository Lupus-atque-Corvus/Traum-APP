import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/health/health_score_calculator.dart';
import 'package:traum/features/health/health_score_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late TraumDatabase db;
  late ProviderContainer c;

  setUp(() async {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({'workout_goal_per_week': 1});
    final prefs = await SharedPreferences.getInstance();
    c = ProviderContainer(overrides: [
      databaseProvider.overrideWithValue(db),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ]);
  });

  tearDown(() {
    c.dispose();
    db.close();
  });

  test(
      'workoutsThisWeek is derived per calendar week, not per single day '
      '(regression: previously a single day\'s own session count was passed '
      'straight into a field compared against the weekly goal, making every '
      'day in the graph look like it under-achieved on training)', () async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    await db.trainingDao.insertSession(WorkoutSessionsCompanion.insert(
      startedAt: today.add(const Duration(hours: 9)),
    ));

    c.listen(healthScoreHistoryProvider, (_, _) {});
    final scores = await c.read(healthScoreHistoryProvider.future);
    expect(scores, hasLength(7));

    // Zero nutrition/sleep/mood data seeded, goal 1 workout/week (from
    // setUp) — everything else neutral, so the two calculator calls below
    // isolate exactly what the training factor contributes.
    final expectedWithSession = HealthScoreCalculator.calculate(
      workoutsThisWeek: 1,
      workoutGoalPerWeek: 1,
      avgCaloriesLast7Days: 0,
      calorieGoal: 2000,
      avgProteinLast7Days: 0,
      proteinGoal: 150,
      avgWaterLast7Days: 0,
      waterGoalMl: 2500,
      avgSleepHoursLast7Days: 0,
      supplementsTakenToday: 0,
      supplementsTotal: 0,
      medicationsTakenToday: 0,
      medicationsTotal: 0,
      moodScoresLast7Days: const [],
    ).gesamtScore;
    final expectedWithoutSession = HealthScoreCalculator.calculate(
      workoutsThisWeek: 0,
      workoutGoalPerWeek: 1,
      avgCaloriesLast7Days: 0,
      calorieGoal: 2000,
      avgProteinLast7Days: 0,
      proteinGoal: 150,
      avgWaterLast7Days: 0,
      waterGoalMl: 2500,
      avgSleepHoursLast7Days: 0,
      supplementsTakenToday: 0,
      supplementsTotal: 0,
      medicationsTakenToday: 0,
      medicationsTotal: 0,
      moodScoresLast7Days: const [],
    ).gesamtScore;

    // Today (last entry): the session already happened today, so — whether
    // today is a Monday or not — "this week, up to and including today"
    // contains exactly 1 session.
    expect(scores.last, expectedWithSession);
    // 6 days ago (first entry): the session is either later in the same
    // calendar week (hasn't happened yet as of that day) or in next
    // calendar week entirely — either way, 0 sessions counted for that
    // day's week-so-far.
    expect(scores.first, expectedWithoutSession);
  });
}
