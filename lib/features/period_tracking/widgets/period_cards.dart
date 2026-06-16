import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../../../l10n/app_localizations.dart';
import '../cycle_analysis.dart';

String _fmt(DateTime d) => '${d.day}.${d.month}.';

// ---------------------------------------------------------------------------
// PredictionCard
// ---------------------------------------------------------------------------

class PredictionCard extends StatelessWidget {
  final CycleAnalysis analysis;
  final DateTime today;

  const PredictionCard({
    super.key,
    required this.analysis,
    required this.today,
  });

  @override
  Widget build(BuildContext context) {
    if (analysis.nextPeriodPredicted == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    final todayNorm =
        DateTime(today.year, today.month, today.day);
    final daysUntil =
        analysis.nextPeriodPredicted!.difference(todayNorm).inDays;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
            color: TraumColors.periodRose.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bold headline: "Period in X days"
          Text(
            l10n.nextPeriodIn(daysUntil),
            style: const TextStyle(
              color: TraumColors.periodRose,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),

          // Predicted range
          if (analysis.nextPeriodRangeStart != null &&
              analysis.nextPeriodRangeEnd != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.predictedRange(
                _fmt(analysis.nextPeriodRangeStart!),
                _fmt(analysis.nextPeriodRangeEnd!),
              ),
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Fertile window row
          if (analysis.fertileWindowStart != null &&
              analysis.fertileWindowEnd != null)
            _InfoRow(
              label: l10n.fertileWindowLabel,
              value:
                  '${_fmt(analysis.fertileWindowStart!)}–${_fmt(analysis.fertileWindowEnd!)}',
              color: TraumColors.fertileCyan,
            ),

          // Ovulation row
          if (analysis.ovulationDate != null)
            _InfoRow(
              label: analysis.ovulationConfirmed
                  ? l10n.ovulationConfirmedLabel
                  : l10n.ovulationEstimatedLabel,
              value: _fmt(analysis.ovulationDate!),
              color: TraumColors.ovulationCyan,
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// TodayCard
// ---------------------------------------------------------------------------

class TodayCard extends StatelessWidget {
  final List<PeriodSymptom> todaySymptoms;
  final DailyLog? log;

  const TodayCard({
    super.key,
    required this.todaySymptoms,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasMood = log?.mood != null;
    final hasBbt = log?.bbt != null;
    final isEmpty = todaySymptoms.isEmpty && !hasMood && !hasBbt;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.loggedToday,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          if (isEmpty)
            Text(
              l10n.nothingLoggedToday,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ...todaySymptoms.map((s) => _Chip(label: s.symptom)),
                if (hasMood) _Chip(label: '🙂 ${log!.mood}'),
                if (hasBbt)
                  _Chip(label: '🌡 ${log!.bbt!.toStringAsFixed(2)}°'),
              ],
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// CycleAnalysisCard
// ---------------------------------------------------------------------------

class CycleAnalysisCard extends StatelessWidget {
  final CycleAnalysis analysis;

  const CycleAnalysisCard({super.key, required this.analysis});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final String regularityLabel;
    final Color regularityColor;
    switch (analysis.regularity) {
      case CycleRegularity.regular:
        regularityLabel = l10n.regularityRegular;
        regularityColor = TraumColors.ovulationCyan;
      case CycleRegularity.slightlyIrregular:
        regularityLabel = l10n.regularitySlightly;
        regularityColor = TraumColors.amberGold;
      case CycleRegularity.irregular:
        regularityLabel = l10n.regularityIrregular;
        regularityColor = TraumColors.roseRed;
      case CycleRegularity.unknown:
        regularityLabel = l10n.regularityUnknown;
        regularityColor = TraumColors.onBackgroundMuted;
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Heading + regularity badge
          Row(
            children: [
              Text(
                l10n.cycleAnalysisTitle,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                  color: regularityColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  regularityLabel,
                  style: TextStyle(
                    color: regularityColor,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Variability
          Text(
            l10n.variabilityDays(
                analysis.cycleLengthStdDev?.round() ?? 0),
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),

          // Gyn age
          if (analysis.gynecologicalAgeYears != null) ...[
            const SizedBox(height: 4),
            Text(
              l10n.gynAgeYears(analysis.gynecologicalAgeYears!.round()),
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// HealthFlagsCard
// ---------------------------------------------------------------------------

class HealthFlagsCard extends StatelessWidget {
  final List<HealthFlag> flags;

  const HealthFlagsCard({super.key, required this.flags});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
            color: TraumColors.amberGold.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (flags.isEmpty)
            Row(
              children: [
                const Icon(Icons.check_circle_outline_rounded,
                    color: TraumColors.ovulationCyan, size: 16),
                const SizedBox(width: 6),
                Text(
                  l10n.healthAllNormal,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontSize: 13,
                  ),
                ),
              ],
            )
          else
            ...flags.map((flag) {
              final String text;
              switch (flag.type) {
                case HealthFlagType.consistentlyLong:
                  text = l10n.healthFlagConsistentlyLong;
                case HealthFlagType.consistentlyShort:
                  text = l10n.healthFlagConsistentlyShort;
                case HealthFlagType.longPeriod:
                  text = l10n.healthFlagLongPeriod;
                case HealthFlagType.highVariability:
                  text = l10n.healthFlagHighVariability;
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.warning_amber_rounded,
                        color: TraumColors.amberGold, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        text,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),

          // Disclaimer always shown
          const SizedBox(height: 8),
          Text(
            l10n.periodMedicalDisclaimer,
            style: const TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private helpers
// ---------------------------------------------------------------------------

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoRow({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;

  const _Chip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: TraumColors.periodRose.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: TraumColors.periodRose.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TraumColors.periodRose,
          fontFamily: 'DMSans',
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
