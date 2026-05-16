import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import 'cycle_calculator.dart';

class PeriodScreen extends ConsumerWidget {
  const PeriodScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(allPeriodEntriesStreamProvider);
    final symptomsAsync = ref.watch(allPeriodSymptomsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Zyklus',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_rounded, color: TraumColors.periodRose),
            tooltip: 'Kalender',
            onPressed: () => context.go('/period/calendar'),
          ),
          IconButton(
            icon: const Icon(Icons.history_rounded, color: TraumColors.onBackgroundMuted),
            tooltip: 'Historie',
            onPressed: () => context.go('/period/history'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.periodRose,
        onPressed: () => _showLogPeriodSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: entriesAsync.when(
        data: (entries) => symptomsAsync.when(
          data: (symptoms) => _PeriodBody(
            entries: entries,
            symptoms: symptoms,
            onDeleteEntry: (id) => ref.read(periodDaoProvider).deletePeriodEntry(id),
            onEndPeriod: (entry) => ref.read(periodDaoProvider).updatePeriodEntry(
                  PeriodEntriesCompanion(
                    id: Value(entry.id),
                    startDate: Value(entry.startDate),
                    endDate: Value(DateTime.now()),
                    flowIntensity: Value(entry.flowIntensity),
                    note: Value(entry.note),
                  ),
                ),
            onAddSymptom: () => _showAddSymptomSheet(context, ref),
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: TraumColors.periodRose)),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.periodRose)),
        error: (e, _) => Center(
            child: Text('Fehler: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showLogPeriodSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _LogPeriodSheet(
        onAdd: (c) => ref.read(periodDaoProvider).insertPeriodEntry(c),
      ),
    );
  }

  void _showAddSymptomSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddSymptomSheet(
        onAdd: (c) => ref.read(periodDaoProvider).insertSymptom(c),
      ),
    );
  }
}

class _PeriodBody extends StatelessWidget {
  final List<PeriodEntry> entries;
  final List<PeriodSymptom> symptoms;
  final void Function(int) onDeleteEntry;
  final Future<void> Function(PeriodEntry) onEndPeriod;
  final VoidCallback onAddSymptom;

  const _PeriodBody({
    required this.entries,
    required this.symptoms,
    required this.onDeleteEntry,
    required this.onEndPeriod,
    required this.onAddSymptom,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate cycle stats from entries
    CycleResult? cycleResult;
    int avgCycleLength = 28;
    int avgPeriodLength = 5;

    if (entries.isNotEmpty) {
      // Average period length
      final withEnd = entries.where((e) => e.endDate != null).toList();
      if (withEnd.isNotEmpty) {
        avgPeriodLength =
            (withEnd.map((e) => e.endDate!.difference(e.startDate).inDays).reduce((a, b) => a + b) /
                    withEnd.length)
                .round()
                .clamp(1, 10);
      }

      // Average cycle length from consecutive entries
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

      cycleResult = CycleCalculator.calculate(
        lastPeriodStart: entries.first.startDate,
        avgCycleLength: avgCycleLength,
        avgPeriodLength: avgPeriodLength,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (cycleResult != null) ...[
          _CycleStatusCard(result: cycleResult, avgCycleLength: avgCycleLength),
          const SizedBox(height: 16),
        ],
        // Symptoms section
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Symptome heute',
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          TextButton.icon(
            onPressed: onAddSymptom,
            icon: const Icon(Icons.add, size: 16, color: TraumColors.periodRose),
            label: const Text('Hinzufügen',
                style: TextStyle(color: TraumColors.periodRose, fontFamily: 'DMSans', fontSize: 12)),
          ),
        ]),
        const SizedBox(height: 8),
        _TodaySymptoms(symptoms: symptoms),
        const SizedBox(height: 16),
        // Period entries
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Periode-Einträge',
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ]),
        const SizedBox(height: 8),
        if (entries.isEmpty)
          Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.water_drop_rounded,
                  size: 48,
                  color: TraumColors.periodRose.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              const Text('Noch keine Einträge',
                  style: TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              const Text('Tippe auf + um die Periode zu starten',
                  style: TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
            ]),
          )
        else
          ...entries.take(5).map((e) => _PeriodEntryCard(
                entry: e,
                onDelete: () => onDeleteEntry(e.id),
                onEnd: () => onEndPeriod(e),
              )),
      ],
    );
  }
}

class _CycleStatusCard extends StatelessWidget {
  final CycleResult result;
  final int avgCycleLength;

  const _CycleStatusCard({required this.result, required this.avgCycleLength});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    bool isFertile = false;
    bool isOvulation = false;
    if (result.fertileStart != null && result.fertileEnd != null) {
      isFertile = today.isAfter(result.fertileStart!.subtract(const Duration(days: 1))) &&
          today.isBefore(result.fertileEnd!.add(const Duration(days: 1)));
    }
    if (result.ovulationDate != null) {
      final ovDay = DateTime(
          result.ovulationDate!.year, result.ovulationDate!.month, result.ovulationDate!.day);
      isOvulation = ovDay == today;
    }

    String phase = 'Follikelphase';
    Color phaseColor = TraumColors.periodRose;
    if (isOvulation) {
      phase = 'Eisprung';
      phaseColor = TraumColors.ovulationCyan;
    } else if (isFertile) {
      phase = 'Fruchtbares Fenster';
      phaseColor = TraumColors.fertileCyan;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(color: phaseColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: phaseColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(phase,
                  style: TextStyle(
                      color: phaseColor,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12)),
            ),
            const Spacer(),
            Text('Ø $avgCycleLength Tage',
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
          ]),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _InfoTile(
              label: 'Nächste Periode',
              value: result.nextPeriodPredicted != null
                  ? '${result.nextPeriodPredicted!.day}.${result.nextPeriodPredicted!.month}.'
                  : '–',
              color: TraumColors.periodRose,
            )),
            Expanded(child: _InfoTile(
              label: 'Eisprung',
              value: result.ovulationDate != null
                  ? '${result.ovulationDate!.day}.${result.ovulationDate!.month}.'
                  : '–',
              color: TraumColors.ovulationCyan,
            )),
            Expanded(child: _InfoTile(
              label: 'Fruchtbar',
              value: (result.fertileStart != null && result.fertileEnd != null)
                  ? '${result.fertileStart!.day}.–${result.fertileEnd!.day}.${result.fertileEnd!.month}.'
                  : '–',
              color: TraumColors.fertileCyan,
            )),
          ]),
          if (result.pregnancyProbability > 0) ...[
            const SizedBox(height: 10),
            Text('Schwangerschaftswahrscheinlichkeit heute: ${result.pregnancyProbability}%',
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11)),
          ],
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _InfoTile({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Text(value,
          style: TextStyle(
              color: color,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 16)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 10),
          textAlign: TextAlign.center),
    ]);
  }
}

class _TodaySymptoms extends StatelessWidget {
  final List<PeriodSymptom> symptoms;

  const _TodaySymptoms({required this.symptoms});

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final todaySymptoms = symptoms.where((s) =>
        s.logDate.year == today.year &&
        s.logDate.month == today.month &&
        s.logDate.day == today.day).toList();

    if (todaySymptoms.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Text('Keine Symptome heute',
            style: TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: todaySymptoms.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: TraumColors.periodRose.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: TraumColors.periodRose.withValues(alpha: 0.3)),
        ),
        child: Text(s.symptom,
            style: const TextStyle(
                color: TraumColors.periodRose,
                fontFamily: 'DMSans',
                fontSize: 12,
                fontWeight: FontWeight.w500)),
      )).toList(),
    );
  }
}

class _PeriodEntryCard extends StatelessWidget {
  final PeriodEntry entry;
  final VoidCallback onDelete;
  final VoidCallback onEnd;

  const _PeriodEntryCard({
    required this.entry,
    required this.onDelete,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = entry.endDate == null;
    final duration = entry.endDate != null
        ? entry.endDate!.difference(entry.startDate).inDays
        : DateTime.now().difference(entry.startDate).inDays;

    final flowLabels = ['', 'Leicht', 'Mittel', 'Stark', 'Sehr stark'];
    final flowColors = [
      Colors.transparent,
      TraumColors.periodRose.withValues(alpha: 0.5),
      TraumColors.periodRose,
      TraumColors.roseRed,
      TraumColors.roseRed,
    ];
    final intensity = entry.flowIntensity.clamp(1, 4);

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: isActive
                ? TraumColors.periodRose.withValues(alpha: 0.4)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            Container(
              width: 8,
              height: 40,
              decoration: BoxDecoration(
                color: flowColors[intensity],
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  '${entry.startDate.day}.${entry.startDate.month}.${entry.startDate.year}'
                  '${entry.endDate != null ? ' – ${entry.endDate!.day}.${entry.endDate!.month}.${entry.endDate!.year}' : ' – heute'}',
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600),
                ),
                Text(
                  '$duration Tage  •  ${flowLabels[intensity]}',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12),
                ),
                if (entry.note != null)
                  Text(entry.note!,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 11)),
              ]),
            ),
            if (isActive)
              TextButton(
                onPressed: onEnd,
                style: TextButton.styleFrom(foregroundColor: TraumColors.periodRose),
                child: const Text('Beenden', style: TextStyle(fontFamily: 'DMSans', fontSize: 12)),
              ),
            if (isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: TraumColors.periodRose.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Aktiv',
                    style: TextStyle(
                        color: TraumColors.periodRose,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 10)),
              ),
          ]),
        ),
      ),
    );
  }
}

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
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: TraumColors.onBackgroundSubtle,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Periode starten',
                style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Startdatum',
                  style: TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
              trailing: Text(
                '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year}',
                style: const TextStyle(
                    color: TraumColors.periodRose,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _startDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime.now(),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme:
                            const ColorScheme.dark(primary: TraumColors.periodRose)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            const SizedBox(height: 8),
            const Text('Stärke',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(4, (i) {
                final intensity = i + 1;
                final labels = ['Leicht', 'Mittel', 'Stark', 'Sehr stark'];
                final selected = intensity == _flowIntensity;
                return GestureDetector(
                  onTap: () => setState(() => _flowIntensity = intensity),
                  child: Column(children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: selected
                            ? TraumColors.periodRose.withValues(alpha: 0.3)
                            : TraumColors.surfaceVariant,
                        border: Border.all(
                          color: selected ? TraumColors.periodRose : Colors.transparent,
                        ),
                      ),
                      child: Center(
                        child: Icon(Icons.water_drop_rounded,
                            color: selected ? TraumColors.periodRose : TraumColors.onBackgroundSubtle,
                            size: 20),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(labels[i],
                        style: TextStyle(
                            color: selected
                                ? TraumColors.periodRose
                                : TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 10)),
                  ]),
                );
              }),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: 'Notiz (optional)',
                labelStyle: const TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? 'Speichern…' : 'Periode starten',
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
      note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}

class _AddSymptomSheet extends StatefulWidget {
  final Future<void> Function(PeriodSymptomsCompanion) onAdd;
  const _AddSymptomSheet({required this.onAdd});

  @override
  State<_AddSymptomSheet> createState() => _AddSymptomSheetState();
}

class _AddSymptomSheetState extends State<_AddSymptomSheet> {
  final _customCtrl = TextEditingController();
  String? _selectedSymptom;
  int _intensity = 2;
  bool _saving = false;

  static const _presets = [
    'Krämpfe', 'Kopfschmerzen', 'Rückenschmerzen', 'Brust­spannen',
    'Blähungen', 'Übelkeit', 'Stimmungsschwankungen', 'Müdigkeit',
    'Akne', 'Schlafprobleme',
  ];

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
                  decoration: BoxDecoration(
                      color: TraumColors.onBackgroundSubtle,
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Symptom hinzufügen',
                style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _presets.map((s) {
                final selected = s == _selectedSymptom;
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedSymptom = selected ? null : s;
                    if (!selected) _customCtrl.clear();
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: selected
                          ? TraumColors.periodRose.withValues(alpha: 0.2)
                          : TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: selected ? TraumColors.periodRose : Colors.transparent,
                      ),
                    ),
                    child: Text(s,
                        style: TextStyle(
                            color: selected
                                ? TraumColors.periodRose
                                : TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _customCtrl,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: 'Oder eigenes Symptom',
                labelStyle: const TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              onChanged: (_) => setState(() => _selectedSymptom = null),
            ),
            const SizedBox(height: 12),
            const Text('Intensität',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            Slider(
              value: _intensity.toDouble(),
              min: 1, max: 3,
              divisions: 2,
              activeColor: TraumColors.periodRose,
              label: ['Leicht', 'Mittel', 'Stark'][_intensity - 1],
              onChanged: (v) => setState(() => _intensity = v.round()),
            ),
            const SizedBox(height: 12),
            GradientButton(
              label: _saving ? 'Speichern…' : 'Symptom speichern',
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final symptom = _selectedSymptom ?? _customCtrl.text.trim();
    if (symptom.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Bitte Symptom auswählen oder eingeben')));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(PeriodSymptomsCompanion.insert(
      logDate: DateTime.now(),
      symptom: symptom,
      intensity: Value(_intensity),
    ));
    if (mounted) Navigator.pop(context);
  }
}
