import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/theme/colors.dart';
import 'package:traum/features/health/health_score_calculator.dart';
import 'package:traum/features/health/health_score_result.dart';

/// Characterization tests for the health-score engine (pure logic).
/// Locks in factor bands, weighting and the label/helper functions
/// before dependency major-upgrades (Phase 4).
void main() {
  // Neutral baseline: every input zeroed so each factor resolves to 50.
  HealthScoreResult calc({
    int workoutsThisWeek = 0,
    int workoutGoalPerWeek = 0,
    double avgCaloriesLast7Days = 0,
    double calorieGoal = 0,
    double avgProteinLast7Days = 0,
    double proteinGoal = 0,
    double avgWaterLast7Days = 0,
    double waterGoalMl = 0,
    double avgSleepHoursLast7Days = 0,
    int supplementsTakenToday = 0,
    int supplementsTotal = 0,
    int medicationsTakenToday = 0,
    int medicationsTotal = 0,
    List<int> moodScoresLast7Days = const [],
  }) =>
      HealthScoreCalculator.calculate(
        workoutsThisWeek: workoutsThisWeek,
        workoutGoalPerWeek: workoutGoalPerWeek,
        avgCaloriesLast7Days: avgCaloriesLast7Days,
        calorieGoal: calorieGoal,
        avgProteinLast7Days: avgProteinLast7Days,
        proteinGoal: proteinGoal,
        avgWaterLast7Days: avgWaterLast7Days,
        waterGoalMl: waterGoalMl,
        avgSleepHoursLast7Days: avgSleepHoursLast7Days,
        supplementsTakenToday: supplementsTakenToday,
        supplementsTotal: supplementsTotal,
        medicationsTakenToday: medicationsTakenToday,
        medicationsTotal: medicationsTotal,
        moodScoresLast7Days: moodScoresLast7Days,
      );

  int factor(HealthScoreResult r, String name) =>
      r.faktoren.firstWhere((f) => f.name == name).score;

  group('HealthScoreCalculator baseline & extremes', () {
    test('all-neutral input scores every factor at 50 and total 50', () {
      final r = calc();
      expect(r.gesamtScore, 50);
      for (final f in r.faktoren) {
        expect(f.score, 50, reason: f.name);
      }
    });

    test('all-optimal input scores 100', () {
      final r = calc(
        workoutsThisWeek: 3,
        workoutGoalPerWeek: 3,
        avgCaloriesLast7Days: 2000,
        calorieGoal: 2000,
        avgProteinLast7Days: 150,
        proteinGoal: 150,
        avgWaterLast7Days: 2500,
        waterGoalMl: 2500,
        avgSleepHoursLast7Days: 8,
        supplementsTakenToday: 2,
        supplementsTotal: 2,
        medicationsTakenToday: 2,
        medicationsTotal: 2,
        moodScoresLast7Days: const [5, 5, 5],
      );
      expect(r.gesamtScore, 100);
    });
  });

  group('Training factor', () {
    test('goal 0 → neutral 50', () {
      expect(factor(calc(workoutGoalPerWeek: 0), 'Training'), 50);
    });
    test('proportional to goal', () {
      expect(factor(calc(workoutsThisWeek: 2, workoutGoalPerWeek: 4), 'Training'),
          50);
      expect(factor(calc(workoutsThisWeek: 1, workoutGoalPerWeek: 4), 'Training'),
          25);
    });
    test('clamps at 100 when goal exceeded', () {
      expect(factor(calc(workoutsThisWeek: 5, workoutGoalPerWeek: 4), 'Training'),
          100);
    });
  });

  group('Nutrition calorie bands (protein & water held at goal=100)', () {
    int ernaehrungFor(double calRatio) {
      const goal = 2000.0;
      return factor(
        calc(
          avgCaloriesLast7Days: goal * calRatio,
          calorieGoal: goal,
          avgProteinLast7Days: 150,
          proteinGoal: 150,
          avgWaterLast7Days: 2500,
          waterGoalMl: 2500,
        ),
        'Ernährung',
      );
    }

    test('ratio within ±15% → calorie 100 → Ernährung 100', () {
      expect(ernaehrungFor(1.0), 100);
    });
    test('ratio within ±30% → calorie 75 → Ernährung 92', () {
      expect(ernaehrungFor(0.75), 92); // (75 + 100 + 100)/3
    });
    test('ratio within ±50% → calorie 50 → Ernährung 83', () {
      expect(ernaehrungFor(0.60), 83); // (50 + 100 + 100)/3
    });
    test('ratio beyond ±50% → calorie 25 → Ernährung 75', () {
      expect(ernaehrungFor(0.40), 75); // (25 + 100 + 100)/3
    });
  });

  group('Protein & water are linear with their goal', () {
    test('half of protein goal → 50 (Ernährung 83 with cal+water at 100)', () {
      final e = factor(
        calc(
          avgCaloriesLast7Days: 2000,
          calorieGoal: 2000,
          avgProteinLast7Days: 75,
          proteinGoal: 150,
          avgWaterLast7Days: 2500,
          waterGoalMl: 2500,
        ),
        'Ernährung',
      );
      expect(e, 83); // (100 + 50 + 100)/3 = 83.3 → 83
    });
    test('goal 0 yields neutral 50 contribution', () {
      // Everything in nutrition zeroed → all three sub-scores 50.
      expect(factor(calc(), 'Ernährung'), 50);
    });
  });

  group('Sleep (Regeneration) bands', () {
    int regen(double h) => factor(calc(avgSleepHoursLast7Days: h), 'Regeneration');
    test('7–9h → 100', () => expect(regen(8), 100));
    test('6–9.5h → 75', () => expect(regen(6.5), 75));
    test('5–10h → 50', () => expect(regen(5.5), 50));
    test('>0 but poor → 25', () => expect(regen(3), 25));
    test('0 (no data) → neutral 50', () => expect(regen(0), 50));
  });

  group('Supplements & medications', () {
    test('total 0 → neutral 50', () {
      expect(factor(calc(supplementsTotal: 0), 'Supplemente'), 50);
      expect(factor(calc(medicationsTotal: 0), 'Medikamente'), 50);
    });
    test('all taken → 100', () {
      expect(
          factor(calc(supplementsTakenToday: 2, supplementsTotal: 2),
              'Supplemente'),
          100);
      expect(
          factor(calc(medicationsTakenToday: 4, medicationsTotal: 4),
              'Medikamente'),
          100);
    });
    test('partial is proportional', () {
      expect(
          factor(calc(medicationsTakenToday: 1, medicationsTotal: 4),
              'Medikamente'),
          25);
    });
  });

  group('Mood factor (avg × 20)', () {
    test('empty → neutral 50', () {
      expect(factor(calc(moodScoresLast7Days: const []), 'Stress & Mental'), 50);
    });
    test('average 5 → 100', () {
      expect(
          factor(calc(moodScoresLast7Days: const [5, 5, 5]), 'Stress & Mental'),
          100);
    });
    test('average 1 → 20', () {
      expect(
          factor(calc(moodScoresLast7Days: const [1, 1]), 'Stress & Mental'), 20);
    });
    test('single 3 → 60', () {
      expect(factor(calc(moodScoresLast7Days: const [3]), 'Stress & Mental'), 60);
    });
  });

  group('Total weighting & getters', () {
    test('weighted sum: Training 100, rest 50 → 60', () {
      final r = calc(workoutsThisWeek: 4, workoutGoalPerWeek: 4);
      // 100*0.20 + 50*0.80 = 60
      expect(r.gesamtScore, 60);
    });

    test('strongest and weakest factors', () {
      final r = calc(workoutsThisWeek: 4, workoutGoalPerWeek: 4); // Training 100
      expect(r.strongestFactor.name, 'Training');
      expect(r.weakestFactor.score, 50);
    });
  });

  // ─── Pure label / presentation helpers ───────────────────────────────────────
  group('scoreLabel thresholds (German fallback)', () {
    test('maps score ranges', () {
      expect(scoreLabel(90), 'Sehr gut');
      expect(scoreLabel(85), 'Sehr gut');
      expect(scoreLabel(70), 'Gut');
      expect(scoreLabel(55), 'Mittel');
      expect(scoreLabel(40), 'Verbesserungsbedarf');
      expect(scoreLabel(39), 'Kritisch');
    });
  });

  group('color helpers', () {
    test('scoreLabelColor thresholds', () {
      expect(scoreLabelColor(90), TraumColors.mintGreen);
      expect(scoreLabelColor(70), TraumColors.amberGold);
      expect(scoreLabelColor(55), TraumColors.coralOrange);
      expect(scoreLabelColor(30), TraumColors.roseRed);
    });
    test('faktorFarbe mirrors scoreLabelColor thresholds', () {
      expect(faktorFarbe(90), TraumColors.mintGreen);
      expect(faktorFarbe(54), TraumColors.roseRed);
    });
    test('faktorModulFarbe maps known names and defaults', () {
      expect(faktorModulFarbe('Training'), TraumColors.coralOrange);
      expect(faktorModulFarbe('Regeneration'), TraumColors.cyanBlue);
      expect(faktorModulFarbe('unknown'), TraumColors.coralOrange);
    });
  });

  group('text & icon helpers', () {
    test('faktorBewertung thresholds', () {
      expect(faktorBewertung(90), 'Optimal');
      expect(faktorBewertung(70), 'Gut');
      expect(faktorBewertung(55), 'Mittel');
      expect(faktorBewertung(20), 'Schwach');
    });
    test('motivationstext thresholds', () {
      expect(motivationstext(90), contains('Topform'));
      expect(motivationstext(75), contains('Gut unterwegs'));
      expect(motivationstext(60), contains('Solide'));
      expect(motivationstext(45), contains('Verbesserungspotenzial'));
      expect(motivationstext(30), contains('Aufmerksamkeit'));
    });
    test('faktorIcon known names and default', () {
      expect(faktorIcon('Training'), Icons.fitness_center_rounded);
      expect(faktorIcon('Stress & Mental'), Icons.psychology_outlined);
      expect(faktorIcon('unknown'), Icons.circle);
    });
    test('faktorHinweis known name and default', () {
      expect(faktorHinweis('Regeneration'), contains('Schlaf'));
      expect(faktorHinweis('unknown'), 'Schau dir die Details an.');
    });
  });
}
