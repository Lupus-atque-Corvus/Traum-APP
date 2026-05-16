import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class MedicationScreen extends ConsumerWidget {
  const MedicationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final medsAsync = ref.watch(
      StreamProvider((ref) => ref.watch(medicationDaoProvider).watchAllMedications()),
    );
    final today = DateTime.now();
    final logsAsync = ref.watch(
      StreamProvider((ref) => ref.watch(medicationDaoProvider).watchLogsForDate(today)),
    );

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Medikamente',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          medsAsync.when(
            data: (meds) => logsAsync.when(
              data: (logs) => _TodayStatusCard(meds: meds, logs: logs),
              loading: () => const ShimmerLoader(width: double.infinity, height: 100),
              error: (_, __) => const SizedBox.shrink(),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 100),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          const SectionHeader(title: 'Alle Medikamente'),
          const SizedBox(height: 8),
          medsAsync.when(
            data: (meds) {
              if (meds.isEmpty) return const _EmptyState();
              return Column(
                children: meds.map((med) => _MedicationCard(
                  medication: med,
                  onDelete: () => ref.read(medicationDaoProvider).deleteMedication(med.id),
                )).toList(),
              );
            },
            loading: () => const ShimmerLoader(width: double.infinity, height: 200),
            error: (e, _) => Text('Fehler: $e',
                style: const TextStyle(color: TraumColors.roseRed)),
          ),
        ],
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddMedicationSheet(
        onAdd: (companion) async {
          await ref.read(medicationDaoProvider).insertMedication(companion);
          final timesJson = companion.timings.value;
          if (timesJson != '[]') {
            try {
              final times = (jsonDecode(timesJson) as List).cast<String>();
              for (int i = 0; i < times.length; i++) {
                final parts = times[i].split(':');
                await NotificationService.scheduleDailyAt(
                  id: 100 + i,
                  title: companion.name.value,
                  body: 'Zeit für ${companion.name.value}',
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                  channelId: 'medication',
                );
              }
            } catch (_) {}
          }
        },
      ),
    );
  }
}

class _TodayStatusCard extends StatelessWidget {
  final List<Medication> meds;
  final List<MedicationLog> logs;

  const _TodayStatusCard({required this.meds, required this.logs});

  @override
  Widget build(BuildContext context) {
    final activeMeds = meds.where((m) => m.isActive).toList();
    if (activeMeds.isEmpty) return const SizedBox.shrink();

    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Heute',
              style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          ...activeMeds.map((med) {
            final times = _parseTimes(med.timings);
            final takenCount = logs.where((l) => l.medicationId == med.id && l.taken).length;
            final takenList = List.generate(times.length, (i) => i < takenCount);
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: MedicationDotRow(name: med.name, times: times, taken: takenList),
            );
          }),
        ],
      ),
    );
  }

  List<String> _parseTimes(String timings) {
    try { return (jsonDecode(timings) as List).cast<String>(); } catch (_) { return []; }
  }
}

class _MedicationCard extends StatelessWidget {
  final Medication medication;
  final VoidCallback onDelete;

  const _MedicationCard({required this.medication, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final times = _parseTimes(medication.timings);

    return Dismissible(
      key: ValueKey(medication.id),
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: medication.isActive
                ? TraumColors.roseRed.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: TraumColors.roseRedDim, shape: BoxShape.circle),
            child: const Icon(Icons.medication_rounded, color: TraumColors.roseRed, size: 20),
          ),
          title: Text(medication.name,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (medication.dosage != null || medication.form != null)
                Text('${medication.dosage ?? ''} ${medication.form != null ? '· ${medication.form}' : ''}'.trim(),
                    style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
              if (times.isNotEmpty)
                Text('Erinnerungen: ${times.join(', ')}',
                    style: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 11)),
            ],
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: medication.isActive ? TraumColors.mintGreenDim : TraumColors.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              medication.isActive ? 'Aktiv' : 'Inaktiv',
              style: TextStyle(
                color: medication.isActive ? TraumColors.mintGreen : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _parseTimes(String timings) {
    try { return (jsonDecode(timings) as List).cast<String>(); } catch (_) { return []; }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.medication_rounded, size: 64,
                color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            const Text('Noch keine Medikamente',
                style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            const Text('Tippe auf + um ein Medikament hinzuzufügen',
                style: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _AddMedicationSheet extends StatefulWidget {
  final Future<void> Function(MedicationsCompanion) onAdd;
  const _AddMedicationSheet({required this.onAdd});

  @override
  State<_AddMedicationSheet> createState() => _AddMedicationSheetState();
}

class _AddMedicationSheetState extends State<_AddMedicationSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  String _form = 'Tablette';
  final List<String> _times = ['08:00'];
  bool _saving = false;

  static const _forms = ['Tablette', 'Kapsel', 'Tropfen', 'Injektion', 'Salbe', 'Spray', 'Sonstige'];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
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
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            const Text('Medikament hinzufügen',
                style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            _buildField('Name', _nameCtrl, hint: 'z.B. Aspirin'),
            const SizedBox(height: 12),
            _buildField('Dosierung', _dosageCtrl, hint: 'z.B. 100 mg'),
            const SizedBox(height: 12),
            const Text('Darreichungsform',
                style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _forms.map((f) {
                final selected = f == _form;
                return GestureDetector(
                  onTap: () => setState(() => _form = f),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: selected ? TraumColors.roseRedDim : TraumColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(TraumRadius.chip),
                      border: Border.all(color: selected ? TraumColors.roseRed : Colors.transparent),
                    ),
                    child: Text(f, style: TextStyle(
                        color: selected ? TraumColors.roseRed : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans', fontSize: 13)),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Erinnerungszeiten',
                  style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
              const Spacer(),
              TextButton.icon(
                onPressed: _addTime,
                icon: const Icon(Icons.add, size: 16, color: TraumColors.coralOrange),
                label: const Text('Hinzufügen',
                    style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans', fontSize: 12)),
              ),
            ]),
            ..._times.asMap().entries.map((e) => Row(children: [
              GestureDetector(
                onTap: () => _editTime(e.key),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                    border: Border.all(color: TraumColors.roseRed.withValues(alpha: 0.3)),
                  ),
                  child: Text(e.value, style: const TextStyle(
                      color: TraumColors.roseRed, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
                ),
              ),
              if (_times.length > 1)
                IconButton(
                  icon: const Icon(Icons.close, size: 16, color: TraumColors.onBackgroundSubtle),
                  onPressed: () => setState(() => _times.removeAt(e.key)),
                ),
            ])),
            const SizedBox(height: 20),
            GradientButton(label: _saving ? 'Speichern…' : 'Speichern', onPressed: _saving ? null : _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
            color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
            filled: true, fillColor: TraumColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times.add(
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}'));
    }
  }

  Future<void> _editTime(int index) async {
    final parts = _times[index].split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _times[index] =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
    }
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name ist ein Pflichtfeld')),
      );
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(MedicationsCompanion.insert(
      name: _nameCtrl.text.trim(),
      dosage: Value(_dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim()),
      form: Value(_form),
      timings: Value(jsonEncode(_times)),
    ));
    if (mounted) Navigator.pop(context);
  }
}
