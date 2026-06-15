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

  test('predicts next period and a range widening with variability', () {
    final regular = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
      entry(3, DateTime(2026, 2, 26)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: regular, today: DateTime(2026, 3, 1));
    expect(a.nextPeriodPredicted, DateTime(2026, 3, 26));
    final span = a.nextPeriodRangeEnd!
        .difference(a.nextPeriodRangeStart!)
        .inDays;
    expect(span, greaterThanOrEqualTo(2));

    final variable = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 23)), // 22
      entry(3, DateTime(2026, 2, 26)), // 34
    ];
    final b = CycleAnalyzer.analyze(
        entries: variable, today: DateTime(2026, 3, 1));
    final spanB = b.nextPeriodRangeEnd!
        .difference(b.nextPeriodRangeStart!)
        .inDays;
    expect(spanB, greaterThan(span));
  });

  test('estimates ovulation (cycle-luteal) and Wilcox fertile window', () {
    final entries = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
      entry(3, DateTime(2026, 2, 26)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, today: DateTime(2026, 3, 1));
    expect(a.ovulationDate, DateTime(2026, 3, 12));
    expect(a.ovulationConfirmed, isFalse);
    expect(a.fertileWindowStart, DateTime(2026, 3, 7));
    expect(a.fertileWindowEnd, DateTime(2026, 3, 13));
  });

  test('lutealPhaseOverride shifts ovulation', () {
    final entries = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries,
        lutealPhaseOverride: 12,
        today: DateTime(2026, 2, 1));
    expect(a.ovulationDate, DateTime(2026, 2, 14));
  });
}
