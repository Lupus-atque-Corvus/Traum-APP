import 'package:flutter_test/flutter_test.dart';
import 'package:traum/widget/widget_keys.dart';
import 'package:traum/widget/widget_snapshot.dart';

void main() {
  test('toStringMap enthält alle namespaced Keys als String', () {
    const snap = WidgetSnapshot(
      steps: 4200, stepsGoal: 10000,
      sleepHours: 7.5, heartRate: 62, mood: 4,
      kcal: 1500, kcalGoal: 2200,
      waterMl: 1200, waterGoalMl: 2500,
      protein: 90, proteinGoal: 150,
      nextTodo: 'Einkaufen',
    );
    final m = snap.toStringMap();
    expect(m[WidgetKeys.steps], '4200');
    expect(m[WidgetKeys.stepsGoal], '10000');
    expect(m[WidgetKeys.sleepHours], '7.5');
    expect(m[WidgetKeys.waterMl], '1200');
    expect(m[WidgetKeys.nextTodo], 'Einkaufen');
    expect(m.values, everyElement(isA<String>()));
  });

  test('empty() liefert Platzhalter-Snapshot ohne Nullwerte', () {
    final m = WidgetSnapshot.empty().toStringMap();
    expect(m[WidgetKeys.steps], '0');
    expect(m[WidgetKeys.nextTodo], '');
  });
}
