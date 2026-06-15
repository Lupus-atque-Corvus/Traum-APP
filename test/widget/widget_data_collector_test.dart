import 'package:flutter_test/flutter_test.dart';
import 'package:traum/widget/widget_data_collector.dart';
import 'package:traum/widget/widget_snapshot.dart';

void main() {
  test('mapToSnapshot übernimmt Rohwerte korrekt', () {
    final snap = WidgetDataCollector.mapToSnapshot(
      stepsToday: 4200, stepsGoal: 10000, sleepHours: 7.5, heartRate: 62, mood: 4,
      kcalToday: 1500, kcalGoal: 2200, waterMlToday: 1200, waterGoalMl: 2500,
      proteinToday: 90, proteinGoal: 150, nextTodoTitle: 'Einkaufen',
    );
    expect(snap.waterMl, 1200);
    expect(snap.steps, 4200);
    expect(snap.nextTodo, 'Einkaufen');
  });

  test('mapToSnapshot ersetzt fehlenden Todo durch leeren String', () {
    final snap = WidgetDataCollector.mapToSnapshot(
      stepsToday: 0, stepsGoal: 10000, sleepHours: 0, heartRate: 0, mood: 0,
      kcalToday: 0, kcalGoal: 2200, waterMlToday: 0, waterGoalMl: 2500,
      proteinToday: 0, proteinGoal: 150, nextTodoTitle: null,
    );
    expect(snap.nextTodo, '');
    expect(snap, isA<WidgetSnapshot>());
  });

  test('mapToSnapshot übernimmt Phase-2-Felder (benannte Defaults)', () {
    final snap = WidgetDataCollector.mapToSnapshot(
      stepsToday: 0, stepsGoal: 10000, sleepHours: 0, heartRate: 0, mood: 0,
      kcalToday: 0, kcalGoal: 2200, waterMlToday: 0, waterGoalMl: 2500,
      proteinToday: 0, proteinGoal: 150, nextTodoTitle: null,
      healthScore: 82, weightKg: 74.5, activeMinutes: 35,
      carbs: 180, fat: 60, lastMeal: 'Haferflocken',
      nextWorkout: 'Push A', weeklyVolume: 12000, trainingStreak: 4,
      openTodos: 3, nextAppointment: 'Zahnarzt 14:00',
      habitsDone: 2, habitsTotal: 5, medsDone: 1, medsTotal: 2,
      balanceMonth: 420.5, income: 2000, expense: 1579.5,
      budgetSpent: 800, budgetLimit: 1000, topCategory: 'Lebensmittel',
      writeStreak: 6, lastEntry: 'Guter Tag', entriesThisMonth: 12,
      abstinenceTitle: 'Alkohol', abstinenceDuration: '14 Tage', moneySaved: 120,
      lastIntake: 'Magnesium', takenToday: 2,
      cycleDay: 12, periodPhase: 'Follikelphase', nextPeriodDays: 16,
      notesCount: 23, lastNote: 'Einkaufsliste',
      placesCount: 8, lastPhoto: 'Hauptbahnhof',
    );
    expect(snap.healthScore, 82);
    expect(snap.weightKg, 74.5);
    expect(snap.nextWorkout, 'Push A');
    expect(snap.balanceMonth, 420.5);
    expect(snap.topCategory, 'Lebensmittel');
    expect(snap.cycleDay, 12);
    expect(snap.placesCount, 8);
  });

  test('mapToSnapshot übernimmt v2-Serien und toStringMap enthält die CSV-Strings', () {
    final snap = WidgetDataCollector.mapToSnapshot(
      stepsToday: 0, stepsGoal: 10000, sleepHours: 0, heartRate: 0, mood: 0,
      kcalToday: 0, kcalGoal: 2200, waterMlToday: 0, waterGoalMl: 2500,
      proteinToday: 0, proteinGoal: 150, nextTodoTitle: null,
      stepsWeek: '4200,5100,0',
      weightHistory: '75,74.5,74',
      macroSplit: '90,180,60',
      habitWeek: '1,0,1,1,0,1,1',
      categorySplit: '120,80,40',
      mealsTodayList: 'Haferflocken;Reis',
      counters: 'Alkohol 14;Nikotin 3',
      quote: 'Bleib dran.',
    );
    expect(snap.macroSplit, '90,180,60');
    expect(snap.mealsTodayList, 'Haferflocken;Reis');
    final map = snap.toStringMap();
    expect(map['health.stepsWeek'], '4200,5100,0');
    expect(map['health.weightHistory'], '75,74.5,74');
    expect(map['nutrition.macroSplit'], '90,180,60');
    expect(map['planning.habitWeek'], '1,0,1,1,0,1,1');
    expect(map['budget.categorySplit'], '120,80,40');
    expect(map['abstinence.counters'], 'Alkohol 14;Nikotin 3');
    expect(map['general.quote'], 'Bleib dran.');
    // fixed-goal constants always present
    expect(map['health.sleepGoalH'], '8');
    expect(map['period.cycleLenDays'], '28');
  });
}
