import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'cycle_calculator.dart';

class CycleHistoryScreen extends ConsumerWidget {
  const CycleHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allPeriodEntriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.cycleHistory,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          final l10n = AppLocalizations.of(context)!;
          if (entries.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history_rounded,
                    size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noHistory,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.logPeriodsToSeeStats,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }

          final sorted = [...entries]..sort((a, b) => a.startDate.compareTo(b.startDate));

          // Cycle lengths between consecutive periods
          final cycleLengths = <int>[];
          for (int i = 1; i < sorted.length; i++) {
            cycleLengths.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
          }

          final periodLengths = entries
              .where((e) => e.endDate != null)
              .map((e) => e.endDate!.difference(e.startDate).inDays)
              .toList();

          final avgCycle = cycleLengths.isNotEmpty
              ? (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length).round()
              : 28;
          final avgPeriod = periodLengths.isNotEmpty
              ? (periodLengths.reduce((a, b) => a + b) / periodLengths.length).round()
              : 5;
          final isIrregular = CycleCalculator.isIrregular(cycleLengths);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Stats summary
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  border: Border.all(
                    color: isIrregular
                        ? TraumColors.amberGold.withValues(alpha: 0.3)
                        : TraumColors.periodRose.withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  children: [
                    Row(children: [
                      Expanded(
                        child: _StatTile(
                          label: l10n.cycle_length,
                          value: l10n.avgCycleDays(avgCycle),
                          color: TraumColors.periodRose,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: l10n.period_length,
                          value: l10n.avgDurationDays(avgPeriod),
                          color: TraumColors.ovulationCyan,
                        ),
                      ),
                      Expanded(
                        child: _StatTile(
                          label: l10n.entriesLabel,
                          value: '${entries.length}',
                          color: TraumColors.lavender,
                        ),
                      ),
                    ]),
                    if (isIrregular) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: TraumColors.amberGoldDim,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(children: [
                          const Icon(Icons.warning_rounded,
                              color: TraumColors.amberGold, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              l10n.irregularCycle,
                              style: const TextStyle(
                                  color: TraumColors.amberGold,
                                  fontFamily: 'DMSans',
                                  fontSize: 12),
                            ),
                          ),
                        ]),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Cycle length bar chart
              if (cycleLengths.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(l10n.cycleLengths,
                          style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 14)),
                      const SizedBox(height: 12),
                      _CycleLengthChart(lengths: cycleLengths, avgLength: avgCycle),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Period list
              Text(l10n.periods,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 15)),
              const SizedBox(height: 8),
              ...entries.map((e) => _PeriodHistoryTile(
                    entry: e,
                    cycleLength: _getCycleLength(e, entries),
                  )),
            ],
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.periodRose)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  int? _getCycleLength(PeriodEntry entry, List<PeriodEntry> all) {
    final sorted = [...all]..sort((a, b) => a.startDate.compareTo(b.startDate));
    final idx = sorted.indexWhere((e) => e.id == entry.id);
    if (idx <= 0) return null;
    return sorted[idx].startDate.difference(sorted[idx - 1].startDate).inDays;
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11)),
    ]);
  }
}

class _CycleLengthChart extends StatelessWidget {
  final List<int> lengths;
  final int avgLength;

  const _CycleLengthChart({required this.lengths, required this.avgLength});

  @override
  Widget build(BuildContext context) {
    final maxVal = lengths.fold(0, (a, b) => a > b ? a : b).toDouble();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: lengths.take(12).map((len) {
        final height = maxVal > 0 ? (len / maxVal) * 80 : 4.0;
        final isAboveAvg = len > avgLength;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  height: height.clamp(4.0, 80.0),
                  decoration: BoxDecoration(
                    color: isAboveAvg
                        ? TraumColors.amberGold.withValues(alpha: 0.7)
                        : TraumColors.periodRose.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(height: 4),
                Text('$len',
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 9)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PeriodHistoryTile extends StatelessWidget {
  final PeriodEntry entry;
  final int? cycleLength;

  const _PeriodHistoryTile({required this.entry, this.cycleLength});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final duration = entry.endDate?.difference(entry.startDate).inDays;
    final flowLabels = ['', l10n.flowLight, l10n.flowMedium, l10n.flowStrong, l10n.flowVeryStrong];
    final intensity = entry.flowIntensity.clamp(1, 4);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Row(children: [
        Container(
          width: 4,
          height: 40,
          decoration: BoxDecoration(
            color: TraumColors.periodRose.withValues(alpha: 0.4 + intensity * 0.15),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${entry.startDate.day.toString().padLeft(2, '0')}.${entry.startDate.month.toString().padLeft(2, '0')}.${entry.startDate.year}'
              '${entry.endDate != null ? ' – ${entry.endDate!.day}.${entry.endDate!.month}.' : ''}',
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w500),
            ),
            Text(
              [
                if (duration != null) '$duration ${l10n.daysShort}',
                flowLabels[intensity],
                if (cycleLength != null) '${l10n.cycle}: $cycleLength ${l10n.tDayUnit}',
              ].join('  •  '),
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11),
            ),
          ]),
        ),
        if (duration != null)
          GradientProgressBar(
            value: (duration / 7).clamp(0.0, 1.0),
            height: 6,
            gradient: const LinearGradient(
                colors: [TraumColors.periodRose, TraumColors.roseRed]),
          ),
      ]),
    );
  }
}
