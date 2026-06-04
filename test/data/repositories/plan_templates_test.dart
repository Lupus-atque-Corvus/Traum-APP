import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/repositories/plan_templates.dart';

void main() {
  test('PPL template has 3 days', () {
    expect(PlanTemplates.ppl.days.length, 3);
  });

  test('PPL Push Day contains Bankdruecken', () {
    final pushDay = PlanTemplates.ppl.days[0];
    expect(pushDay.exercises.any((e) => e.exerciseName == 'Bankdruecken'), isTrue);
  });

  test('all non-custom templates have at least one day', () {
    for (final t in PlanTemplates.all.where((t) => t.id != 'custom')) {
      expect(t.days, isNotEmpty, reason: '${t.name} has no days');
    }
  });

  test('custom template has zero days', () {
    expect(PlanTemplates.custom.days, isEmpty);
  });

  test('all template ids are unique', () {
    final ids = PlanTemplates.all.map((t) => t.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test('Plank and Laufen exercises have unit seconds', () {
    final allExercises = PlanTemplates.all
        .expand((t) => t.days)
        .expand((d) => d.exercises)
        .toList();
    final planks = allExercises.where((e) => e.exerciseName == 'Plank');
    final laufen = allExercises.where((e) => e.exerciseName == 'Laufen');
    for (final e in planks) {
      expect(e.unit, 'seconds', reason: 'Plank should be seconds');
    }
    for (final e in laufen) {
      expect(e.unit, 'seconds', reason: 'Laufen should be seconds');
    }
  });
}
