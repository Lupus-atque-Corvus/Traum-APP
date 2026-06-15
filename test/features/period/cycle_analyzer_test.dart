import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/period_tracking/cycle_analyzer.dart';
import 'package:traum/features/period_tracking/cycle_analysis.dart';

PeriodEntry entry(int id, DateTime start, {DateTime? end, int flow = 2}) =>
    PeriodEntry(id: id, startDate: start, endDate: end, flowIntensity: flow);

void main() {
  test('avgCycleLength weights recent cycles and computes stdDev', () {
    final entries = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
      entry(3, DateTime(2026, 2, 26)),
      entry(4, DateTime(2026, 3, 26)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, today: DateTime(2026, 4, 1));
    expect(a.avgCycleLength, closeTo(28, 0.01));
    expect(a.cycleLengthStdDev, closeTo(0, 0.01));
  });

  test('sparse data: zero/one cycle falls back to 28-day default', () {
    final a = CycleAnalyzer.analyze(
        entries: [entry(1, DateTime(2026, 1, 1))],
        today: DateTime(2026, 1, 10));
    expect(a.avgCycleLength, 28);
  });
}
