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

  DailyLog tlog(DateTime d, double t) => DailyLog(id: 0, logDate: d, bbt: t);

  test('confirms ovulation from a clean thermal shift in current cycle', () {
    final entries = [entry(1, DateTime(2026, 2, 26))];
    final logs = <DailyLog>[
      tlog(DateTime(2026, 3, 5), 36.40),
      tlog(DateTime(2026, 3, 6), 36.42),
      tlog(DateTime(2026, 3, 7), 36.41),
      tlog(DateTime(2026, 3, 8), 36.39),
      tlog(DateTime(2026, 3, 9), 36.43),
      tlog(DateTime(2026, 3, 10), 36.40),
      tlog(DateTime(2026, 3, 11), 36.70), // shift day 1
      tlog(DateTime(2026, 3, 12), 36.72), // shift day 2
      tlog(DateTime(2026, 3, 13), 36.71), // shift day 3 → confirmed
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, dailyLogs: logs, today: DateTime(2026, 3, 14));
    expect(a.ovulationConfirmed, isTrue);
    expect(a.ovulationDate, DateTime(2026, 3, 10));
  });

  test('no confirmation without a sustained shift', () {
    final entries = [entry(1, DateTime(2026, 2, 26))];
    final logs = [
      tlog(DateTime(2026, 3, 5), 36.40),
      tlog(DateTime(2026, 3, 6), 36.42),
      tlog(DateTime(2026, 3, 7), 36.41),
      tlog(DateTime(2026, 3, 8), 36.70), // single spike only
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, dailyLogs: logs, today: DateTime(2026, 3, 14));
    expect(a.ovulationConfirmed, isFalse);
  });

  test('classifies regular vs irregular by ACOG variability', () {
    final regular = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
      entry(3, DateTime(2026, 2, 26)),
    ];
    expect(
      CycleAnalyzer.analyze(entries: regular, today: DateTime(2026, 3, 1))
          .regularity,
      CycleRegularity.regular,
    );

    final irregular = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 21)), // 20
      entry(3, DateTime(2026, 3, 5)),  // 43
    ];
    expect(
      CycleAnalyzer.analyze(entries: irregular, today: DateTime(2026, 3, 6))
          .regularity,
      CycleRegularity.irregular,
    );
  });

  test('computes gynecological age from menarche', () {
    final a = CycleAnalyzer.analyze(
      entries: [entry(1, DateTime(2026, 1, 1))],
      menarcheDate: DateTime(2014, 1, 1),
      today: DateTime(2026, 1, 1),
    );
    expect(a.gynecologicalAgeYears, closeTo(12, 0.1));
  });

  test('flags consistently long cycles, softened in early gyn age', () {
    final longCycles = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 2, 9)),  // 39
      entry(3, DateTime(2026, 3, 21)), // 40
      entry(4, DateTime(2026, 4, 30)), // 40
    ];
    final flagged = CycleAnalyzer.analyze(
        entries: longCycles, today: DateTime(2026, 5, 1));
    expect(
      flagged.healthFlags.map((f) => f.type),
      contains(HealthFlagType.consistentlyLong),
    );

    final softened = CycleAnalyzer.analyze(
      entries: longCycles,
      menarcheDate: DateTime(2024, 6, 1),
      today: DateTime(2026, 5, 1),
    );
    expect(
      softened.healthFlags.map((f) => f.type),
      isNot(contains(HealthFlagType.consistentlyLong)),
    );
  });

  test('flags an overly long period', () {
    final entries = [
      entry(1, DateTime(2026, 2, 1), end: DateTime(2026, 2, 10)), // 10 days
      entry(2, DateTime(2026, 3, 1)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, today: DateTime(2026, 3, 2));
    expect(a.healthFlags.map((f) => f.type),
        contains(HealthFlagType.longPeriod));
  });

  test('computes current cycle day and phase', () {
    final entries = [
      entry(1, DateTime(2026, 1, 1)),
      entry(2, DateTime(2026, 1, 29)),
      entry(3, DateTime(2026, 2, 26), end: DateTime(2026, 3, 2)),
    ];
    final a = CycleAnalyzer.analyze(
        entries: entries, today: DateTime(2026, 3, 12));
    expect(a.currentCycleDay, 15);
    expect(a.currentPhase, CyclePhase.ovulation);

    final b = CycleAnalyzer.analyze(
        entries: entries, today: DateTime(2026, 2, 27));
    expect(b.currentCycleDay, 2);
    expect(b.currentPhase, CyclePhase.menstrual);
  });
}
