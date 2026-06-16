import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'cycle_analysis.dart';
import 'cycle_settings_sheet.dart';
import 'daily_log_sheet.dart';
import 'widgets/cycle_ring.dart';
import 'widgets/period_cards.dart';
import 'widgets/period_charts.dart';

// ---------------------------------------------------------------------------
// Top-level helpers
// ---------------------------------------------------------------------------

String _phaseLabel(AppLocalizations l10n, CyclePhase p) {
  switch (p) {
    case CyclePhase.menstrual:
      return l10n.phaseMenstrual;
    case CyclePhase.follicular:
      return l10n.phaseFollicular;
    case CyclePhase.fertile:
      return l10n.phaseFertile;
    case CyclePhase.ovulation:
      return l10n.phaseOvulation;
    case CyclePhase.luteal:
      return l10n.phaseLuteal;
    case CyclePhase.unknown:
      return l10n.phaseFollicular;
  }
}

Color _phaseColor(CyclePhase p) {
  switch (p) {
    case CyclePhase.menstrual:
      return TraumColors.periodRose;
    case CyclePhase.fertile:
      return TraumColors.fertileCyan;
    case CyclePhase.ovulation:
      return TraumColors.ovulationCyan;
    case CyclePhase.luteal:
      return TraumColors.lavender;
    case CyclePhase.follicular:
    case CyclePhase.unknown:
      return TraumColors.onBackgroundMuted;
  }
}

double _ringProgress(CycleAnalysis analysis) {
  return ((analysis.currentCycleDay ?? 1) / (analysis.avgCycleLength ?? 28))
      .clamp(0.0, 1.0);
}

List<int> _cycleLengths(List<PeriodEntry> entries) {
  if (entries.length < 2) return const [];
  final sorted = [...entries]..sort((a, b) => a.startDate.compareTo(b.startDate));
  final lengths = <int>[];
  for (int i = 1; i < sorted.length; i++) {
    lengths.add(sorted[i].startDate.difference(sorted[i - 1].startDate).inDays);
  }
  return lengths;
}

List<({DateTime date, double temp})> _bbtPoints(List<DailyLog> logs) {
  final pts = logs
      .where((l) => l.bbt != null)
      .map((l) => (date: l.logDate, temp: l.bbt!))
      .toList()
    ..sort((a, b) => a.date.compareTo(b.date));
  return pts;
}

bool _isToday(DateTime date) {
  final now = DateTime.now();
  return date.year == now.year && date.month == now.month && date.day == now.day;
}

// ---------------------------------------------------------------------------
// PeriodScreen
// ---------------------------------------------------------------------------

class PeriodScreen extends ConsumerWidget {
  const PeriodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final analysis = ref.watch(cycleAnalysisProvider);
    final profile = ref.watch(cycleProfileStreamProvider).valueOrNull;
    final entriesAsync = ref.watch(allPeriodEntriesStreamProvider);
    final symptomsAsync = ref.watch(allPeriodSymptomsStreamProvider);
    final dailyLogsAsync = ref.watch(allDailyLogsStreamProvider);

    final entries = entriesAsync.valueOrNull ?? const [];
    final symptoms = symptomsAsync.valueOrNull ?? const [];
    final dailyLogs = dailyLogsAsync.valueOrNull ?? const [];

    final todaySymptoms = symptoms.where((s) => _isToday(s.logDate)).toList();
    final todayLog = dailyLogs.cast<DailyLog?>().firstWhere(
          (l) => l != null && _isToday(l.logDate),
          orElse: () => null,
        );

    final isLoading = entriesAsync.isLoading ||
        symptomsAsync.isLoading ||
        dailyLogsAsync.isLoading;

    final hasEntries = entries.isNotEmpty;
    final cycleLengths = _cycleLengths(entries);
    final bbtPoints = _bbtPoints(dailyLogs);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(
          l10n.cycle,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded,
                color: TraumColors.periodRose),
            tooltip: l10n.calendarTooltip,
            onPressed: () => context.go('/period/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded,
                color: TraumColors.onBackgroundMuted),
            tooltip: l10n.historyTooltip,
            onPressed: () => context.go('/period/history'),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                color: TraumColors.onBackgroundMuted),
            tooltip: l10n.cycleSettingsTitle,
            onPressed: () =>
                _showCycleSettingsSheet(context, ref, profile),
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: TraumColors.periodRose))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── 1. Hero card ──────────────────────────────────────────
                _HeroCard(
                  analysis: analysis,
                  l10n: l10n,
                  onLogPeriod: () => _showLogPeriodSheet(context, ref),
                  onLogDaily: () => _showDailyLogSheet(context, ref, todayLog),
                ),
                const SizedBox(height: 12),

                // ── 2. Prediction card ────────────────────────────────────
                if (hasEntries) ...[
                  PredictionCard(analysis: analysis, today: DateTime.now()),
                  const SizedBox(height: 12),
                ],

                // ── 3. Today card ─────────────────────────────────────────
                TodayCard(todaySymptoms: todaySymptoms, log: todayLog),
                const SizedBox(height: 12),

                // ── 4. Cycle-length chart card ────────────────────────────
                if (hasEntries && cycleLengths.length >= 2) ...[
                  _TitledCard(
                    title: l10n.cycleLengthsTitle,
                    subtitle: l10n.cycleLengthsSubtitle(
                        analysis.avgCycleLength?.round() ?? 28),
                    child: CycleLengthChart(
                      lengths: cycleLengths,
                      avgLength: analysis.avgCycleLength?.round() ?? 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── 5. BBT card ───────────────────────────────────────────
                if (bbtPoints.length >= 2) ...[
                  _TitledCard(
                    title: l10n.bbtCurveTitle,
                    child: BbtChart(points: bbtPoints),
                  ),
                  const SizedBox(height: 12),
                ],

                // ── 6. Cycle analysis card ────────────────────────────────
                if (hasEntries) ...[
                  CycleAnalysisCard(analysis: analysis),
                  const SizedBox(height: 12),
                ],

                // ── 7. Symptom pattern card ───────────────────────────────
                if (symptoms.length >= 5) ...[
                  _SymptomPatternCard(symptoms: symptoms, l10n: l10n),
                  const SizedBox(height: 12),
                ],

                // ── 8. Health flags card ──────────────────────────────────
                if (hasEntries) ...[
                  HealthFlagsCard(flags: analysis.healthFlags),
                  const SizedBox(height: 12),
                ],

                // ── 9. Mehr card ──────────────────────────────────────────
                _MehrCard(l10n: l10n),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  void _showLogPeriodSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _LogPeriodSheet(
        onAdd: (c) => ref.read(periodDaoProvider).insertPeriodEntry(c),
      ),
    );
  }

  void _showDailyLogSheet(
      BuildContext context, WidgetRef ref, DailyLog? existing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => DailyLogSheet(
        date: DateTime.now(),
        existing: existing,
        onSave: (companion) =>
            ref.read(periodDaoProvider).upsertDailyLog(companion),
      ),
    );
  }

  void _showCycleSettingsSheet(
      BuildContext context, WidgetRef ref, CycleProfileData? profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => CycleSettingsSheet(
        menarcheDate: profile?.menarcheDate,
        lutealPhaseOverride: profile?.lutealPhaseOverride,
        onSave: (c) => ref.read(periodDaoProvider).updateCycleProfile(c),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _HeroCard
// ---------------------------------------------------------------------------

class _HeroCard extends StatelessWidget {
  final CycleAnalysis analysis;
  final AppLocalizations l10n;
  final VoidCallback onLogPeriod;
  final VoidCallback onLogDaily;

  const _HeroCard({
    required this.analysis,
    required this.l10n,
    required this.onLogPeriod,
    required this.onLogDaily,
  });

  @override
  Widget build(BuildContext context) {
    final phase = analysis.currentPhase;
    final phaseColor = _phaseColor(phase);
    final label = _phaseLabel(l10n, phase);
    final subtitle =
        phase == CyclePhase.ovulation ? l10n.phaseOvulation : null;

    return Container(
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Ring
          CycleRing(
            cycleDay: analysis.currentCycleDay,
            phaseLabel: label,
            progress: _ringProgress(analysis),
            centerSubtitle: subtitle,
          ),
          const SizedBox(height: 12),

          // Phase pill
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            decoration: BoxDecoration(
              color: phaseColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: phaseColor,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Quick-log row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _QuickLogButton(
                label: l10n.logPeriodShort,
                icon: Icons.water_drop_rounded,
                onTap: onLogPeriod,
              ),
              _QuickLogButton(
                label: l10n.logSymptomShort,
                icon: Icons.healing_rounded,
                onTap: onLogDaily,
              ),
              _QuickLogButton(
                label: l10n.logTempShort,
                icon: Icons.thermostat_rounded,
                onTap: onLogDaily,
              ),
              _QuickLogButton(
                label: l10n.logMore,
                icon: Icons.add_circle_outline_rounded,
                onTap: onLogDaily,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _QuickLogButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _QuickLogButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: TraumColors.periodRose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: TraumColors.periodRose, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: TraumColors.periodRose,
                fontFamily: 'DMSans',
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _TitledCard
// ---------------------------------------------------------------------------

class _TitledCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget child;

  const _TitledCard({
    required this.title,
    this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
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
            title,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _SymptomPatternCard
// ---------------------------------------------------------------------------

class _SymptomPatternCard extends StatelessWidget {
  final List<PeriodSymptom> symptoms;
  final AppLocalizations l10n;

  const _SymptomPatternCard({
    required this.symptoms,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (symptoms.length < 5) return const SizedBox.shrink();

    // Count frequency per symptom name
    final freq = <String, int>{};
    for (final s in symptoms) {
      freq[s.symptom] = (freq[s.symptom] ?? 0) + 1;
    }
    final sorted = freq.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.first;

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
            l10n.symptomPatternsTitle,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${top.key} · ${top.value}×',
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _MehrCard
// ---------------------------------------------------------------------------

class _MehrCard extends StatelessWidget {
  final AppLocalizations l10n;

  const _MehrCard({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Material(
        type: MaterialType.transparency,
        child: Column(
        children: [
          ListTile(
            leading: const Icon(Icons.calendar_month_rounded,
                color: TraumColors.periodRose),
            title: Text(
              l10n.calendarTooltip,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundMuted),
            onTap: () => context.go('/period/calendar'),
          ),
          Divider(
              height: 1,
              color: TraumColors.surfaceVariant.withValues(alpha: 0.5)),
          ListTile(
            leading: const Icon(Icons.history_rounded,
                color: TraumColors.onBackgroundMuted),
            title: Text(
              l10n.historyTooltip,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
            ),
            trailing: const Icon(Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundMuted),
            onTap: () => context.go('/period/history'),
          ),
        ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// _LogPeriodSheet (preserved from old screen)
// ---------------------------------------------------------------------------

class _LogPeriodSheet extends StatefulWidget {
  final Future<void> Function(PeriodEntriesCompanion) onAdd;
  const _LogPeriodSheet({required this.onAdd});

  @override
  State<_LogPeriodSheet> createState() => _LogPeriodSheetState();
}

class _LogPeriodSheetState extends State<_LogPeriodSheet> {
  DateTime _startDate = DateTime.now();
  int _flowIntensity = 2;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.startPeriod,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(
                l10n.startDate,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 13,
                ),
              ),
              trailing: Text(
                '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year}',
                style: const TextStyle(
                  color: TraumColors.periodRose,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(
                          primary: TraumColors.periodRose),
                    ),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 8),
            Text(
              l10n.flowIntensity,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final intensity = i + 1;
                final labels = [
                  l10n.flowLight,
                  l10n.flowMedium,
                  l10n.flowStrong,
                  l10n.flowVeryStrong,
                ];
                final selected = intensity == _flowIntensity;
                return GestureDetector(
                  onTap: () => setState(() => _flowIntensity = intensity),
                  child: Column(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: selected
                              ? TraumColors.periodRose.withValues(alpha: 0.3)
                              : TraumColors.surfaceVariant,
                          border: Border.all(
                            color: selected
                                ? TraumColors.periodRose
                                : Colors.transparent,
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.water_drop_rounded,
                            color: selected
                                ? TraumColors.periodRose
                                : TraumColors.onBackgroundSubtle,
                            size: 20,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        labels[i],
                        style: TextStyle(
                          color: selected
                              ? TraumColors.periodRose
                              : TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
              ),
              decoration: InputDecoration(
                labelText: l10n.noteOptional,
                labelStyle: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                ),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none,
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? l10n.savingPeriod : l10n.startPeriodButton,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await widget.onAdd(PeriodEntriesCompanion.insert(
      startDate: _startDate,
      flowIntensity: Value(_flowIntensity),
      note: Value(
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}
