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
}
