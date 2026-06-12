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
}
