import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/period_tracking/cycle_analysis.dart';
import 'package:traum/features/period_tracking/period_calendar_screen.dart';

void main() {
  test('phaseColorForDay maps fertile window to a non-null color', () {
    final analysis = CycleAnalysis(
      fertileWindowStart: DateTime(2026, 6, 12),
      fertileWindowEnd: DateTime(2026, 6, 17),
      ovulationDate: DateTime(2026, 6, 16),
    );
    final color = phaseColorForDay(DateTime(2026, 6, 13), analysis, const []);
    expect(color, isNotNull);
  });

  test('phaseColorForDay returns null for a day with no phase', () {
    final analysis = CycleAnalysis(
      fertileWindowStart: DateTime(2026, 6, 12),
      fertileWindowEnd: DateTime(2026, 6, 17),
      ovulationDate: DateTime(2026, 6, 16),
    );
    final color = phaseColorForDay(DateTime(2026, 1, 1), analysis, const []);
    expect(color, isNull);
  });
}
