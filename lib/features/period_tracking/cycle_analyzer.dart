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
    // Wilcox 1995: 5 days before to 1 day after ovulation.
    final fertileStart = ovulation.subtract(const Duration(days: 5));
    final fertileEnd = ovulation.add(const Duration(days: 1));

    return CycleAnalysis(
      avgCycleLength: avgCycle,
      cycleLengthStdDev: stdDev,
      avgPeriodLength: avgPeriod,
      nextPeriodPredicted: nextPredicted,
      nextPeriodRangeStart: rangeStart,
      nextPeriodRangeEnd: rangeEnd,
      ovulationDate: ovulation,
      fertileWindowStart: fertileStart,
      fertileWindowEnd: fertileEnd,
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
}
