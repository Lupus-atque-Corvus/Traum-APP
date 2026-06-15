enum CyclePhase { menstrual, follicular, fertile, ovulation, luteal, unknown }

enum CycleRegularity { regular, slightlyIrregular, irregular, unknown }

enum HealthFlagType {
  consistentlyLong,
  consistentlyShort,
  longPeriod,
  highVariability,
}

class HealthFlag {
  final HealthFlagType type;
  const HealthFlag(this.type);

  @override
  bool operator ==(Object other) =>
      other is HealthFlag && other.type == type;
  @override
  int get hashCode => type.hashCode;
}

class CycleAnalysis {
  final int? currentCycleDay;
  final CyclePhase currentPhase;
  final DateTime? nextPeriodPredicted;
  final DateTime? nextPeriodRangeStart;
  final DateTime? nextPeriodRangeEnd;
  final DateTime? ovulationDate;
  final bool ovulationConfirmed;
  final DateTime? fertileWindowStart;
  final DateTime? fertileWindowEnd;
  final double? avgCycleLength;
  final double? cycleLengthStdDev;
  final double? avgPeriodLength;
  final CycleRegularity regularity;
  final double? gynecologicalAgeYears;
  final List<HealthFlag> healthFlags;
  final int pregnancyProbabilityToday;

  const CycleAnalysis({
    this.currentCycleDay,
    this.currentPhase = CyclePhase.unknown,
    this.nextPeriodPredicted,
    this.nextPeriodRangeStart,
    this.nextPeriodRangeEnd,
    this.ovulationDate,
    this.ovulationConfirmed = false,
    this.fertileWindowStart,
    this.fertileWindowEnd,
    this.avgCycleLength,
    this.cycleLengthStdDev,
    this.avgPeriodLength,
    this.regularity = CycleRegularity.unknown,
    this.gynecologicalAgeYears,
    this.healthFlags = const [],
    this.pregnancyProbabilityToday = 0,
  });
}
