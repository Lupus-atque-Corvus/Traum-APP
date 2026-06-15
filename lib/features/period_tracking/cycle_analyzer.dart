import 'dart:math' as math;
import '../../data/database/traum_database.dart';
import 'cycle_analysis.dart';

/// Pure, study-grounded cycle analysis. No DB/UI dependencies.
///
/// Sources:
/// - Luteal phase ~constant ~14 d — Fehring et al. 2006
/// - Fertile window: 5 d before to 1 d after ovulation — Wilcox et al. 1995, NEJM
/// - Irregular if length range >7–9 d, or any cycle <21/>35 d — ACOG
/// - Thermal-shift ovulation detection — Sensiplan "3-over-6" rule
class CycleAnalyzer {
  static const int defaultCycleLength = 28;
  static const int defaultLutealPhase = 14;
  static const int minNormalCycle = 21;
  static const int maxNormalCycle = 35;
  static const int recentWindow = 12; // consider last N cycles

  static CycleAnalysis analyze({
    required List<PeriodEntry> entries,
    List<DailyLog> dailyLogs = const [],
    DateTime? menarcheDate,
    int? lutealPhaseOverride,
    DateTime? today,
  }) {
    final now = _dateOnly(today ?? DateTime.now());
    if (entries.isEmpty) {
      return const CycleAnalysis(avgCycleLength: defaultCycleLength * 1.0);
    }

    final sorted = [...entries]
      ..sort((a, b) => a.startDate.compareTo(b.startDate));

    final cycleLengths = _cycleLengths(sorted);
    final avgCycle = _weightedAverage(cycleLengths) ??
        defaultCycleLength.toDouble();
    final stdDev = _stdDev(cycleLengths, avgCycle);
    final avgPeriod = _avgPeriodLength(sorted);

    final lastStart = _dateOnly(sorted.last.startDate);
    final cycleRounded = avgCycle.round();
    final nextPredicted = lastStart.add(Duration(days: cycleRounded));

    // Honest uncertainty: ±1·stdDev, minimum ±1 day.
    final marginDays = math.max(1, (stdDev ?? 0).round());
    final rangeStart = nextPredicted.subtract(Duration(days: marginDays));
    final rangeEnd = nextPredicted.add(Duration(days: marginDays));

    final luteal = lutealPhaseOverride ?? defaultLutealPhase;
    // Estimated ovulation in the CURRENT cycle = lastStart + (cycle - luteal).
    final ovulation = lastStart.add(Duration(days: cycleRounded - luteal));

    // Try to confirm ovulation from BBT in the current cycle (since lastStart).
    final confirmed = _detectThermalShift(dailyLogs, lastStart);
    final ovulationConfirmed = confirmed != null;
    final ovulationFinal = confirmed ?? ovulation;
    final fertileStartFinal =
        ovulationFinal.subtract(const Duration(days: 5));
    final fertileEndFinal = ovulationFinal.add(const Duration(days: 1));

    final regularity = _classifyRegularity(cycleLengths);
    final gynAge = menarcheDate == null
        ? null
        : now.difference(_dateOnly(menarcheDate)).inDays / 365.25;

    final flags = _healthFlags(
      cycleLengths: cycleLengths,
      avgPeriod: avgPeriod,
      stdDev: stdDev ?? 0,
      gynAgeYears: gynAge,
    );

    final cycleDay = now.difference(lastStart).inDays + 1;

    final phase = _phaseFor(
      today: now,
      cycleStart: lastStart,
      avgPeriod: avgPeriod,
      ovulation: ovulationFinal,
      fertileStart: fertileStartFinal,
      fertileEnd: fertileEndFinal,
    );

    var pregnancyProb = 0;
    if (!now.isBefore(fertileStartFinal) && !now.isAfter(fertileEndFinal)) {
      pregnancyProb = now == ovulationFinal ? 30 : 25;
    }

    return CycleAnalysis(
      avgCycleLength: avgCycle,
      cycleLengthStdDev: stdDev,
      avgPeriodLength: avgPeriod,
      nextPeriodPredicted: nextPredicted,
      nextPeriodRangeStart: rangeStart,
      nextPeriodRangeEnd: rangeEnd,
      ovulationDate: ovulationFinal,
      ovulationConfirmed: ovulationConfirmed,
      fertileWindowStart: fertileStartFinal,
      fertileWindowEnd: fertileEndFinal,
      regularity: regularity,
      gynecologicalAgeYears: gynAge,
      healthFlags: flags,
      currentCycleDay: cycleDay >= 1 ? cycleDay : null,
      currentPhase: phase,
      pregnancyProbabilityToday: pregnancyProb,
    );
  }

  // ── helpers ──────────────────────────────────────────────
  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Days between consecutive period starts (most recent `recentWindow` kept).
  static List<int> _cycleLengths(List<PeriodEntry> sorted) {
    final lengths = <int>[];
    for (var i = 1; i < sorted.length; i++) {
      lengths.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
    }
    if (lengths.length > recentWindow) {
      return lengths.sublist(lengths.length - recentWindow);
    }
    return lengths;
  }

  /// Linear recency-weighted mean (most recent cycle highest weight).
  /// Returns null if there are no cycle lengths.
  static double? _weightedAverage(List<int> lengths) {
    if (lengths.isEmpty) return null;
    double weightedSum = 0;
    double weightTotal = 0;
    for (var i = 0; i < lengths.length; i++) {
      final w = (i + 1).toDouble(); // oldest=1 … newest=n
      weightedSum += lengths[i] * w;
      weightTotal += w;
    }
    return weightedSum / weightTotal;
  }

  static double? _stdDev(List<int> lengths, double mean) {
    if (lengths.length < 2) return 0;
    final variance = lengths
            .map((l) => math.pow(l - mean, 2).toDouble())
            .reduce((a, b) => a + b) /
        lengths.length;
    return math.sqrt(variance);
  }

  static double? _avgPeriodLength(List<PeriodEntry> sorted) {
    final durations = sorted
        .where((e) => e.endDate != null)
        .map((e) => e.endDate!.difference(e.startDate).inDays + 1)
        .toList();
    if (durations.isEmpty) return null;
    return durations.reduce((a, b) => a + b) / durations.length;
  }

  /// ACOG: range (max−min) >7 d → slightly irregular, >9 d → irregular.
  /// Any cycle <21 or >35 d also marks irregular.
  static CycleRegularity _classifyRegularity(List<int> lengths) {
    if (lengths.length < 2) return CycleRegularity.unknown;
    final min = lengths.reduce(math.min);
    final max = lengths.reduce(math.max);
    final range = max - min;
    final hasOutlier =
        lengths.any((l) => l < minNormalCycle || l > maxNormalCycle);
    if (range > 9 || hasOutlier) return CycleRegularity.irregular;
    if (range > 7) return CycleRegularity.slightlyIrregular;
    return CycleRegularity.regular;
  }

  /// Health flags. Softened (suppressed) when within the first 3 years post
  /// menarche, where irregularity/anovulation is expected.
  static List<HealthFlag> _healthFlags({
    required List<int> cycleLengths,
    required double? avgPeriod,
    required double stdDev,
    required double? gynAgeYears,
  }) {
    final earlyGynAge = gynAgeYears != null && gynAgeYears < 3;
    final flags = <HealthFlag>[];

    final recent =
        cycleLengths.length > 3 ? cycleLengths.sublist(cycleLengths.length - 3) : cycleLengths;
    final hasThree = recent.length >= 3;

    if (!earlyGynAge && hasThree && recent.every((l) => l > maxNormalCycle)) {
      flags.add(const HealthFlag(HealthFlagType.consistentlyLong));
    }
    if (!earlyGynAge && hasThree && recent.every((l) => l < minNormalCycle)) {
      flags.add(const HealthFlag(HealthFlagType.consistentlyShort));
    }
    if (avgPeriod != null && avgPeriod > 8) {
      flags.add(const HealthFlag(HealthFlagType.longPeriod));
    }
    if (!earlyGynAge && cycleLengths.length >= 3 && stdDev > 7) {
      flags.add(const HealthFlag(HealthFlagType.highVariability));
    }
    return flags;
  }

  static CyclePhase _phaseFor({
    required DateTime today,
    required DateTime cycleStart,
    required double? avgPeriod,
    required DateTime ovulation,
    required DateTime fertileStart,
    required DateTime fertileEnd,
  }) {
    final periodLen = (avgPeriod ?? 5).round();
    final menstrualEnd = cycleStart.add(Duration(days: periodLen - 1));
    if (!today.isBefore(cycleStart) && !today.isAfter(menstrualEnd)) {
      return CyclePhase.menstrual;
    }
    if (today == ovulation) return CyclePhase.ovulation;
    if (!today.isBefore(fertileStart) && !today.isAfter(fertileEnd)) {
      return CyclePhase.fertile;
    }
    if (today.isAfter(fertileEnd)) return CyclePhase.luteal;
    return CyclePhase.follicular;
  }

  /// Sensiplan "3-over-6": ovulation is confirmed when 3 consecutive BBT
  /// readings all exceed the highest of the preceding 6. Returns the ovulation
  /// date (day before the first of the 3 high temps) or null. Only considers
  /// readings on/after [cycleStart].
  static DateTime? _detectThermalShift(
      List<DailyLog> logs, DateTime cycleStart) {
    final temps = logs
        .where((l) => l.bbt != null && !l.logDate.isBefore(cycleStart))
        .toList()
      ..sort((a, b) => a.logDate.compareTo(b.logDate));
    if (temps.length < 9) return null; // need 6 baseline + 3 high
    for (var i = 6; i <= temps.length - 3; i++) {
      final baseline = temps
          .sublist(i - 6, i)
          .map((l) => l.bbt!)
          .reduce(math.max);
      final high1 = temps[i].bbt!;
      final high2 = temps[i + 1].bbt!;
      final high3 = temps[i + 2].bbt!;
      if (high1 > baseline && high2 > baseline && high3 > baseline) {
        // Ovulation = day before the first high temperature.
        return _dateOnly(temps[i].logDate).subtract(const Duration(days: 1));
      }
    }
    return null;
  }
}
