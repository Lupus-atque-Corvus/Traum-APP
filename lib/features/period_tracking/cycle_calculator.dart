// Wissenschaftliche Periodenberechnung
// Eisprung: Zykluslänge − 14 (Lutealphase konstant) — Fehring et al. 2006
// Fruchtbares Fenster: 5 Tage vor bis 1 Tag nach Eisprung — Wilcox et al. 1995, NEJM
// Unregelmäßig: Schwankung >7–9 Tage — ACOG
// Normal: 21–35 Tage Zyklus, 2–7 Tage Periode

class CycleResult {
  final DateTime? ovulationDate;
  final DateTime? fertileStart;
  final DateTime? fertileEnd;
  final DateTime? nextPeriodPredicted;
  final int pregnancyProbability;

  const CycleResult({
    this.ovulationDate,
    this.fertileStart,
    this.fertileEnd,
    this.nextPeriodPredicted,
    this.pregnancyProbability = 0,
  });
}

class CycleCalculator {
  static CycleResult calculate({
    required DateTime lastPeriodStart,
    required int avgCycleLength,
    required int avgPeriodLength,
  }) {
    if (avgCycleLength <= 0) {
      return const CycleResult();
    }

    // Lutealphase ist konstant ~14 Tage — Fehring et al. 2006
    final ovulationDate = lastPeriodStart.add(
      Duration(days: avgCycleLength - 14),
    );

    // Fruchtbares Fenster: 5 Tage vor bis 1 Tag nach Eisprung — Wilcox et al. 1995
    final fertileStart = ovulationDate.subtract(const Duration(days: 5));
    final fertileEnd = ovulationDate.add(const Duration(days: 1));

    final nextPeriodPredicted = lastPeriodStart.add(
      Duration(days: avgCycleLength),
    );

    // Schwangerschaftswahrscheinlichkeit basierend auf Zyklusphase
    final today = DateTime.now();
    int prob = 0;
    if (today.isAfter(fertileStart) && today.isBefore(fertileEnd)) {
      prob = 25;
      if (today == ovulationDate) prob = 30;
    }

    return CycleResult(
      ovulationDate: ovulationDate,
      fertileStart: fertileStart,
      fertileEnd: fertileEnd,
      nextPeriodPredicted: nextPeriodPredicted,
      pregnancyProbability: prob,
    );
  }

  static int daysUntilNextPeriod(DateTime predicted) {
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    final predDay = DateTime(predicted.year, predicted.month, predicted.day);
    return predDay.difference(today).inDays;
  }

  // Unregelmäßig wenn Schwankung >7 Tage — ACOG
  static bool isIrregular(List<int> cycleLengths) {
    if (cycleLengths.length < 2) return false;
    final min = cycleLengths.reduce((a, b) => a < b ? a : b);
    final max = cycleLengths.reduce((a, b) => a > b ? a : b);
    return (max - min) > 7;
  }
}
