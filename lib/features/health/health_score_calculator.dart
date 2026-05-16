import 'health_score_result.dart';

class HealthScoreCalculator {
  static HealthScoreResult calculate({
    required int workoutsThisWeek,
    required int workoutGoalPerWeek,
    required double avgCaloriesLast7Days,
    required double calorieGoal,
    required double avgProteinLast7Days,
    required double proteinGoal,
    required double avgWaterLast7Days,
    required double waterGoalMl,
    required double avgSleepHoursLast7Days,
    required int supplementsTakenToday,
    required int supplementsTotal,
    required int medicationsTakenToday,
    required int medicationsTotal,
    required List<int> moodScoresLast7Days,
  }) {
    final trainingScore = _clamp(
      workoutGoalPerWeek == 0
          ? 50
          : (workoutsThisWeek / workoutGoalPerWeek * 100).round(),
      0,
      100,
    );

    final calScore = _nutritionScore(avgCaloriesLast7Days, calorieGoal);
    final protScore = proteinGoal == 0
        ? 50
        : _clamp((avgProteinLast7Days / proteinGoal * 100).round(), 0, 100);
    final waterScore = waterGoalMl == 0
        ? 50
        : _clamp((avgWaterLast7Days / waterGoalMl * 100).round(), 0, 100);
    final ernaehrungScore = ((calScore + protScore + waterScore) / 3).round();

    final regenScore = _sleepScore(avgSleepHoursLast7Days);

    final suppScore = supplementsTotal == 0
        ? 50
        : _clamp(
            (supplementsTakenToday / supplementsTotal * 100).round(), 0, 100);

    final medScore = medicationsTotal == 0
        ? 50
        : _clamp(
            (medicationsTakenToday / medicationsTotal * 100).round(), 0, 100);

    final moodScore = moodScoresLast7Days.isEmpty
        ? 50
        : _clamp(
            (moodScoresLast7Days.reduce((a, b) => a + b) /
                    moodScoresLast7Days.length *
                    20)
                .round(),
            0,
            100,
          );

    final total = (trainingScore * 0.20 +
            ernaehrungScore * 0.20 +
            regenScore * 0.20 +
            suppScore * 0.10 +
            medScore * 0.15 +
            moodScore * 0.15)
        .round();

    return HealthScoreResult(
      gesamtScore: total,
      faktoren: [
        FaktorScore(name: 'Training',        score: trainingScore,    gewichtung: 0.20),
        FaktorScore(name: 'Ernährung',       score: ernaehrungScore,  gewichtung: 0.20),
        FaktorScore(name: 'Regeneration',    score: regenScore,       gewichtung: 0.20),
        FaktorScore(name: 'Supplemente',     score: suppScore,        gewichtung: 0.10),
        FaktorScore(name: 'Medikamente',     score: medScore,         gewichtung: 0.15),
        FaktorScore(name: 'Stress & Mental', score: moodScore,        gewichtung: 0.15),
      ],
    );
  }

  static int _clamp(int v, int min, int max) => v.clamp(min, max);

  static int _nutritionScore(double actual, double goal) {
    if (goal == 0) return 50;
    final ratio = actual / goal;
    if (ratio >= 0.85 && ratio <= 1.15) return 100;
    if (ratio >= 0.70 && ratio <= 1.30) return 75;
    if (ratio >= 0.50 && ratio <= 1.50) return 50;
    return 25;
  }

  static int _sleepScore(double hours) {
    if (hours >= 7.0 && hours <= 9.0) return 100;
    if (hours >= 6.0 && hours <= 9.5) return 75;
    if (hours >= 5.0 && hours <= 10.0) return 50;
    if (hours > 0) return 25;
    return 50;
  }
}
