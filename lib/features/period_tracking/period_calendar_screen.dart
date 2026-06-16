import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'cycle_analysis.dart';
import 'cycle_calculator.dart';
import 'daily_log_sheet.dart';

/// Returns the phase color for [day], or null if the day has no phase marker.
/// Priority: active period day (within any entry's start..end) → ovulation →
/// fertile window → predicted next-period range (lower opacity) → null.
Color? phaseColorForDay(
    DateTime day, CycleAnalysis analysis, List<PeriodEntry> entries) {
  final d = DateTime(day.year, day.month, day.day);
  bool inRange(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    final s = DateTime(a.year, a.month, a.day);
    final e = DateTime(b.year, b.month, b.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  // Active period days (logged): within any entry's start..(end ?? start)
  for (final e in entries) {
    final end = e.endDate ?? e.startDate;
    if (inRange(e.startDate, end)) return TraumColors.periodRose;
  }
  if (analysis.ovulationDate != null) {
    final ov = analysis.ovulationDate!;
    if (DateTime(ov.year, ov.month, ov.day) == d) return TraumColors.ovulationCyan;
  }
  if (inRange(analysis.fertileWindowStart, analysis.fertileWindowEnd)) {
    return TraumColors.fertileCyan;
  }
  if (inRange(analysis.nextPeriodRangeStart, analysis.nextPeriodRangeEnd)) {
    return TraumColors.periodRose.withValues(alpha: 0.4);
  }
  return null;
}

class PeriodCalendarScreen extends ConsumerStatefulWidget {
  const PeriodCalendarScreen({super.key});

  @override
  ConsumerState<PeriodCalendarScreen> createState() => _PeriodCalendarScreenState();
}

class _PeriodCalendarScreenState extends ConsumerState<PeriodCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  @override
  Widget build(BuildContext context) {
    final entriesAsync = ref.watch(allPeriodEntriesStreamProvider);

    final analysis = ref.watch(cycleAnalysisProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.periodCalendar,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: entriesAsync.when(
        data: (entries) {
          // Build cycle prediction (kept for _DayDetail backwards compatibility)
          CycleResult? cycleResult;
          int avgCycleLength = 28;

          if (entries.length >= 2) {
            final sorted = [...entries]..sort((a, b) => a.startDate.compareTo(b.startDate));
            final cycleLengths = <int>[];
            for (int i = 1; i < sorted.length; i++) {
              cycleLengths.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
            }
            avgCycleLength = (cycleLengths.reduce((a, b) => a + b) / cycleLengths.length)
                .round()
                .clamp(21, 35);
          }

          if (entries.isNotEmpty) {
            cycleResult = CycleCalculator.calculate(
              lastPeriodStart: entries.first.startDate,
              avgCycleLength: avgCycleLength,
              avgPeriodLength: 5,
            );
          }

          // Build set of period days (for _DayDetail)
          final periodDays = <DateTime>{};
          for (final entry in entries) {
            final end = entry.endDate ?? DateTime.now();
            var d = DateTime(entry.startDate.year, entry.startDate.month, entry.startDate.day);
            final endDay = DateTime(end.year, end.month, end.day);
            while (!d.isAfter(endDay)) {
              periodDays.add(d);
              d = d.add(const Duration(days: 1));
            }
          }

          // Fertile window days (for _DayDetail)
          final fertileDays = <DateTime>{};
          if (cycleResult?.fertileStart != null && cycleResult?.fertileEnd != null) {
            var d = DateTime(cycleResult!.fertileStart!.year, cycleResult.fertileStart!.month,
                cycleResult.fertileStart!.day);
            final end = DateTime(cycleResult.fertileEnd!.year, cycleResult.fertileEnd!.month,
                cycleResult.fertileEnd!.day);
            while (!d.isAfter(end)) {
              fertileDays.add(d);
              d = d.add(const Duration(days: 1));
            }
          }

          final ovulationDay = cycleResult?.ovulationDate != null
              ? DateTime(cycleResult!.ovulationDate!.year, cycleResult.ovulationDate!.month,
                  cycleResult.ovulationDate!.day)
              : null;

          return Column(
            children: [
              TableCalendar(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                onDaySelected: (selected, focused) async {
                  setState(() {
                    _selectedDay = selected;
                    _focusedDay = focused;
                  });
                  // Open DailyLogSheet for the selected day
                  final existing = await ref
                      .read(periodDaoProvider)
                      .getDailyLogForDate(selected);
                  if (!context.mounted) return;
                  await showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: TraumColors.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => DailyLogSheet(
                      date: selected,
                      existing: existing,
                      onSave: (companion) =>
                          ref.read(periodDaoProvider).upsertDailyLog(companion),
                    ),
                  );
                },
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                calendarStyle: CalendarStyle(
                  defaultTextStyle: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  weekendTextStyle: const TextStyle(
                      color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  outsideTextStyle: const TextStyle(
                      color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                  selectedDecoration: const BoxDecoration(
                      color: TraumColors.periodRose, shape: BoxShape.circle),
                  todayDecoration: BoxDecoration(
                      color: TraumColors.periodRose.withValues(alpha: 0.3),
                      shape: BoxShape.circle),
                  todayTextStyle: const TextStyle(
                      color: TraumColors.periodRose, fontFamily: 'DMSans'),
                ),
                headerStyle: const HeaderStyle(
                  titleTextStyle: TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600),
                  leftChevronIcon:
                      Icon(Icons.chevron_left_rounded, color: TraumColors.onBackgroundMuted),
                  rightChevronIcon:
                      Icon(Icons.chevron_right_rounded, color: TraumColors.onBackgroundMuted),
                  formatButtonVisible: false,
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (ctx, day, focusedDay) {
                    final phaseColor = phaseColorForDay(day, analysis, entries);
                    if (phaseColor == null) return null;

                    // Derive background and text colors from the phase color
                    Color bgColor;
                    Color textColor;
                    if (phaseColor == TraumColors.periodRose) {
                      bgColor = TraumColors.periodRose.withValues(alpha: 0.35);
                      textColor = TraumColors.periodRose;
                    } else if (phaseColor == TraumColors.ovulationCyan) {
                      bgColor = TraumColors.ovulationCyan.withValues(alpha: 0.35);
                      textColor = TraumColors.ovulationCyan;
                    } else if (phaseColor == TraumColors.fertileCyan) {
                      bgColor = TraumColors.fertileCyan.withValues(alpha: 0.25);
                      textColor = TraumColors.fertileCyan;
                    } else {
                      // predicted next period range (periodRose @ 0.4 alpha)
                      bgColor = phaseColor.withValues(alpha: 0.2);
                      textColor = TraumColors.periodRose.withValues(alpha: 0.7);
                    }

                    return Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
                      child: Center(
                        child: Text('${day.day}',
                            style: TextStyle(
                                color: textColor, fontFamily: 'DMSans', fontSize: 13)),
                      ),
                    );
                  },
                ),
              ),
              // Legend
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _LegendDot(color: TraumColors.periodRose, label: AppLocalizations.of(context)!.periodLegend),
                    const SizedBox(width: 20),
                    _LegendDot(color: TraumColors.fertileCyan, label: AppLocalizations.of(context)!.fertileLegend),
                    const SizedBox(width: 20),
                    _LegendDot(color: TraumColors.ovulationCyan, label: AppLocalizations.of(context)!.ovulationLegend),
                  ],
                ),
              ),
              if (_selectedDay != null) ...[
                const Divider(color: TraumColors.surfaceVariant),
                _DayDetail(
                  day: _selectedDay!,
                  periodDays: periodDays,
                  fertileDays: fertileDays,
                  ovulationDay: ovulationDay,
                  nextPeriod: cycleResult?.nextPeriodPredicted,
                ),
              ],
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
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 6),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
    ]);
  }
}

class _DayDetail extends StatelessWidget {
  final DateTime day;
  final Set<DateTime> periodDays;
  final Set<DateTime> fertileDays;
  final DateTime? ovulationDay;
  final DateTime? nextPeriod;

  const _DayDetail({
    required this.day,
    required this.periodDays,
    required this.fertileDays,
    required this.ovulationDay,
    required this.nextPeriod,
  });

  @override
  Widget build(BuildContext context) {
    final d = DateTime(day.year, day.month, day.day);
    final isPeriod = periodDays.contains(d);
    final isFertile = fertileDays.contains(d);
    final isOvul = ovulationDay != null && d == ovulationDay;
    final isNextPeriod = nextPeriod != null &&
        DateTime(nextPeriod!.year, nextPeriod!.month, nextPeriod!.day) == d;

    final l10n = AppLocalizations.of(context)!;
    final info = <String>[];
    if (isPeriod) info.add(l10n.periodBleed);
    if (isOvul) info.add(l10n.predictedOvulation);
    if (isFertile && !isOvul) info.add(l10n.fertileWindow2);
    if (isNextPeriod) info.add(l10n.predictedPeriodStart);
    if (info.isEmpty) info.add(l10n.noSpecialEvent);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${day.day.toString().padLeft(2, '0')}.${day.month.toString().padLeft(2, '0')}.${day.year}',
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 15),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: info
                  .map((i) => Text(i,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 13)))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
