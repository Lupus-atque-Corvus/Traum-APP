import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import '../../core/components/components.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'cycle_enums.dart';

class DailyLogSheet extends StatefulWidget {
  final DateTime date;
  final DailyLog? existing;
  final Future<void> Function(DailyLogsCompanion) onSave;
  final List<PeriodSymptom> existingSymptoms;
  final Future<void> Function(String symptom, int intensity)? onAddSymptom;
  final Future<void> Function(int symptomId)? onRemoveSymptom;

  const DailyLogSheet({
    super.key,
    required this.date,
    required this.existing,
    required this.onSave,
    this.existingSymptoms = const [],
    this.onAddSymptom,
    this.onRemoveSymptom,
  });

  @override
  State<DailyLogSheet> createState() => _DailyLogSheetState();
}

class _DailyLogSheetState extends State<DailyLogSheet> {
  int? _mood;
  int? _energy;
  CervicalMucus? _mucus;
  SexEvent _sex = SexEvent.none;
  final _bbtCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _customSymptomCtrl = TextEditingController();
  bool _saving = false;
  late List<PeriodSymptom> _symptoms;
  int _intensity = 2;

  @override
  void initState() {
    super.initState();
    _symptoms = [...widget.existingSymptoms];
    final e = widget.existing;
    if (e != null) {
      _mood = e.mood;
      _energy = e.energy;
      _mucus = e.cervicalMucus == null ? null : CervicalMucus.values[e.cervicalMucus!];
      _sex = e.sexEvent == null ? SexEvent.none : SexEvent.values[e.sexEvent!];
      if (e.bbt != null) _bbtCtrl.text = e.bbt!.toStringAsFixed(2);
      if (e.note != null) _noteCtrl.text = e.note!;
    }
  }

  @override
  void dispose() {
    _bbtCtrl.dispose();
    _noteCtrl.dispose();
    _customSymptomCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final bbt = double.tryParse(_bbtCtrl.text.replaceAll(',', '.'));
    await widget.onSave(DailyLogsCompanion(
      logDate: Value(DateTime(widget.date.year, widget.date.month, widget.date.day)),
      mood: Value(_mood),
      energy: Value(_energy),
      bbt: Value(bbt),
      cervicalMucus: Value(_mucus?.index),
      sexEvent: Value(_sex == SexEvent.none ? null : _sex.index),
      note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
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
            // Drag handle
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
            const SizedBox(height: 12),

            // Title
            Text(
              l10n.logTodayTitle,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),

            // Symptom section (only shown when onAddSymptom is wired up)
            if (widget.onAddSymptom != null) ...[
              _SectionLabel(l10n.symptomsToday),
              const SizedBox(height: 6),
              // Existing symptoms as removable chips
              if (_symptoms.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _symptoms.map((s) {
                    return GestureDetector(
                      onTap: () async {
                        await widget.onRemoveSymptom?.call(s.id);
                        setState(() => _symptoms.removeWhere((x) => x.id == s.id));
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: TraumColors.periodRose.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: TraumColors.periodRose),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              s.symptom,
                              style: const TextStyle(
                                color: TraumColors.periodRose,
                                fontFamily: 'DMSans',
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded,
                                color: TraumColors.periodRose, size: 14),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              if (_symptoms.isNotEmpty) const SizedBox(height: 8),
              // Preset symptom chips
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  l10n.symptomCramps,
                  l10n.symptomHeadache,
                  l10n.symptomBackPain,
                  l10n.symptomBreastTension,
                  l10n.symptomBloating,
                  l10n.symptomNausea,
                  l10n.symptomMoodSwings,
                  l10n.symptomTiredness,
                  l10n.symptomAcne,
                  l10n.symptomSleepIssues,
                ].map((preset) {
                  return _Chip(
                    label: preset,
                    selected: false,
                    onTap: () async {
                      await widget.onAddSymptom!(preset, _intensity);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 8),
              // Custom symptom text field
              TextField(
                controller: _customSymptomCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: InputDecoration(
                  labelText: l10n.orCustomSymptom,
                  labelStyle: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans'),
                  filled: true,
                  fillColor: TraumColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.add_rounded,
                        color: TraumColors.periodRose),
                    onPressed: () async {
                      final text = _customSymptomCtrl.text.trim();
                      if (text.isEmpty) return;
                      await widget.onAddSymptom!(text, _intensity);
                      _customSymptomCtrl.clear();
                    },
                  ),
                ),
                onSubmitted: (text) async {
                  final trimmed = text.trim();
                  if (trimmed.isEmpty) return;
                  await widget.onAddSymptom!(trimmed, _intensity);
                  _customSymptomCtrl.clear();
                },
              ),
              const SizedBox(height: 8),
              // Intensity selector
              _SectionLabel(l10n.intensityLabel),
              Slider(
                value: _intensity.toDouble(),
                min: 1,
                max: 3,
                divisions: 2,
                activeColor: TraumColors.periodRose,
                label: [
                  l10n.intensityLight,
                  l10n.intensityMedium,
                  l10n.intensityStrong,
                ][_intensity - 1],
                onChanged: (v) => setState(() => _intensity = v.round()),
              ),
              const SizedBox(height: 4),
            ],

            // Mood row
            _SectionLabel(l10n.moodLabel),
            const SizedBox(height: 6),
            _DotRow(
              count: 5,
              selected: _mood,
              keyPrefix: 'mood',
              onTap: (i) => setState(() => _mood = i),
            ),
            const SizedBox(height: 12),

            // Energy row
            _SectionLabel(l10n.energyLabel),
            const SizedBox(height: 6),
            _DotRow(
              count: 5,
              selected: _energy,
              keyPrefix: 'energy',
              onTap: (i) => setState(() => _energy = i),
            ),
            const SizedBox(height: 12),

            // BBT
            TextField(
              controller: _bbtCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: l10n.bbtInputLabel,
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),

            // Cervical Mucus chips
            _SectionLabel(l10n.cervicalMucusLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: CervicalMucus.values.map((m) {
                final selected = _mucus == m;
                return _Chip(
                  label: _mucusLabel(l10n, m),
                  selected: selected,
                  onTap: () => setState(() => _mucus = selected ? null : m),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Sex chips
            _SectionLabel(l10n.sexLabel),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SexEvent.values.map((s) {
                final selected = _sex == s;
                return _Chip(
                  label: _sexLabel(l10n, s),
                  selected: selected,
                  onTap: () => setState(() => _sex = s),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),

            // Note
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
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
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 16),

            // Save button
            GradientButton(
              key: const ValueKey('save_daily_log'),
              label: l10n.saveLog,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
        fontSize: 13,
      ),
    );
  }
}

class _DotRow extends StatelessWidget {
  final int count;
  final int? selected;
  final String keyPrefix;
  final void Function(int) onTap;

  const _DotRow({
    required this.count,
    required this.selected,
    required this.keyPrefix,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(count, (index) {
        final i = index + 1;
        final isSelected = selected == i;
        return GestureDetector(
          key: ValueKey('${keyPrefix}_$i'),
          onTap: () => onTap(i),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? TraumColors.periodRose.withValues(alpha: 0.3)
                  : TraumColors.surfaceVariant,
              border: Border.all(
                color: isSelected ? TraumColors.periodRose : Colors.transparent,
              ),
            ),
            child: Center(
              child: Text(
                '$i',
                style: TextStyle(
                  color: isSelected ? TraumColors.periodRose : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
        child: Text(
          label,
          style: TextStyle(
            color: selected ? TraumColors.periodRose : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

String _mucusLabel(AppLocalizations l10n, CervicalMucus m) {
  switch (m) {
    case CervicalMucus.dry:
      return l10n.mucusDry;
    case CervicalMucus.sticky:
      return l10n.mucusSticky;
    case CervicalMucus.creamy:
      return l10n.mucusCreamy;
    case CervicalMucus.watery:
      return l10n.mucusWatery;
    case CervicalMucus.eggWhite:
      return l10n.mucusEggWhite;
  }
}

String _sexLabel(AppLocalizations l10n, SexEvent s) {
  switch (s) {
    case SexEvent.none:
      return l10n.sexNone;
    case SexEvent.protected:
      return l10n.sexProtected;
    case SexEvent.unprotected:
      return l10n.sexUnprotected;
  }
}
