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
import '../../data/models/substance_info.dart';
import '../../l10n/app_localizations.dart';
import '../nutrition/micro_nutrients.dart';

class MySubstancesTab extends ConsumerWidget {
  const MySubstancesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppsAsync = ref.watch(supplementsStreamProvider);
    final medsAsync = ref.watch(allMedicationsStreamProvider);
    final alertsAsync = ref.watch(interactionAlertsProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logsAsync = ref.watch(medicationLogsForDateProvider(today));

    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.coralOrange,
        onPressed: () => _showAddTypeSelector(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          alertsAsync.when(
            data: (alerts) => alerts.isEmpty
                ? const SizedBox.shrink()
                : _InteractionBanner(alerts: alerts),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          medsAsync.when(
            data: (meds) => logsAsync.when(
              data: (logs) => _TodayStatusCard(meds: meds, logs: logs),
              loading: () => const ShimmerLoader(width: double.infinity, height: 80),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 80),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 16),
          suppsAsync.when(
            data: (supps) => medsAsync.when(
              data: (meds) {
                if (supps.isEmpty && meds.isEmpty) {
                  return const _EmptyState();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (meds.isNotEmpty) ...[
                      SectionHeader(title: AppLocalizations.of(context)!.substanceMedications),
                      const SizedBox(height: 8),
                      ...meds.map((med) => _MedCard(
                            med: med,
                            onDelete: () => ref.read(medicationDaoProvider).deleteMedication(med.id),
                            onToggle: (active) => ref
                                .read(medicationDaoProvider)
                                .setMedicationActive(med.id, active),
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (supps.isNotEmpty) ...[
                      SectionHeader(title: AppLocalizations.of(context)!.substanceSupplements),
                      const SizedBox(height: 8),
                      ...supps.map((s) => _SuppCard(
                            supp: s,
                            onDelete: () => ref.read(supplementDaoProvider).deleteSupplement(s.id),
                            onToggle: (active) =>
                                ref.read(supplementDaoProvider).updateSupplement(
                                  SupplementsCompanion(
                                    id: Value(s.id),
                                    name: Value(s.name),
                                    isActive: Value(active),
                                  ),
                                ),
                          )),
                    ],
                  ],
                );
              },
              loading: () => const ShimmerLoader(width: double.infinity, height: 200),
              error: (e, _) => Text('$e'),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 200),
            error: (e, _) => Text('$e'),
          ),
        ],
      ),
    );
  }

  void _showAddTypeSelector(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 20),
          Text(AppLocalizations.of(context)!.whatToAdd,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 20),
          Row(children: [
            Expanded(
              child: _TypeButton(
                icon: Icons.medication_rounded,
                label: 'Medikament',
                color: TraumColors.roseRed,
                dimColor: TraumColors.roseRedDim,
                onTap: () {
                  Navigator.pop(context);
                  _showAddMedSheet(context, ref);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _TypeButton(
                icon: Icons.science_rounded,
                label: 'Supplement',
                color: TraumColors.indigoBlue,
                dimColor: TraumColors.indigoBlueDim,
                onTap: () {
                  Navigator.pop(context);
                  _showAddSuppSheet(context, ref);
                },
              ),
            ),
          ]),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: _TypeButton(
              icon: Icons.event_available_rounded,
              label: 'Konsum erfassen',
              color: TraumColors.coralOrange,
              dimColor: TraumColors.coralDim,
              onTap: () {
                Navigator.pop(context);
                _showAddIntakeSheet(context, ref);
              },
            ),
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAddIntakeSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => _AddIntakeSheet(
        onAdd: (c) => ref.read(substanceDaoProvider).insertIntake(c),
      ),
    );
  }

  void _showAddMedSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddMedSheet(
        onAdd: (companion) async {
          final l10n = AppLocalizations.of(ctx)!;
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
                  body: l10n.timeForMedication(companion.name.value),
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

  void _showAddSuppSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => _AddSuppSheet(
        onAdd: (c) => ref.read(supplementDaoProvider).insertSupplement(c),
      ),
    );
  }
}

class _InteractionBanner extends StatelessWidget {
  final List<InteractionAlert> alerts;
  const _InteractionBanner({required this.alerts});

  @override
  Widget build(BuildContext context) {
    final hasM = alerts.any((a) => a.severity == 'major');
    final color = hasM ? TraumColors.roseRed : TraumColors.coralOrange;
    return GestureDetector(
      onTap: () => _showAlerts(context),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.warning_rounded, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${alerts.length} Interaktion${alerts.length == 1 ? '' : 'en'} erkannt — Tippe für Details',
              style: TextStyle(color: color, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: color, size: 18),
        ]),
      ),
    );
  }

  void _showAlerts(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.interactions,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 16),
          ...alerts.map((a) {
            final color = a.severity == 'major' ? TraumColors.roseRed : TraumColors.coralOrange;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(TraumRadius.chip),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Icon(Icons.warning_rounded, size: 14, color: color),
                  const SizedBox(width: 6),
                  Text('${a.substanceAName} + ${a.substanceBName}',
                      style: TextStyle(color: color, fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700, fontSize: 13)),
                  const Spacer(),
                  Text(a.severity.toUpperCase(),
                      style: TextStyle(color: color, fontFamily: 'DMSans',
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 4),
                Text(a.description,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans', fontSize: 12, height: 1.4)),
              ]),
            );
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _TodayStatusCard extends ConsumerWidget {
  final List<Medication> meds;
  final List<MedicationLog> logs;
  const _TodayStatusCard({required this.meds, required this.logs});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMeds = meds.where((m) => m.isActive).toList();
    if (activeMeds.isEmpty) return const SizedBox.shrink();
    return TraumCard(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(AppLocalizations.of(context)!.today,
            style: TextStyle(color: TraumColors.onBackground,
                fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 16)),
        const SizedBox(height: 12),
        ...activeMeds.map((med) {
          final times = _parseTimes(med.timings);
          final takenCount = logs.where((l) => l.medicationId == med.id && l.taken).length;
          final takenList = List.generate(times.length, (i) => i < takenCount);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MedicationDotRow(
              name: med.name,
              times: times,
              taken: takenList,
              onTapDot: (i) {
                // Tap empty dot → fill up to i+1; tap filled dot → reduce to i.
                final target = i < takenCount ? i : i + 1;
                _setTakenCount(ref, med, times, target);
              },
            ),
          );
        }),
      ]),
    );
  }

  Future<void> _setTakenCount(
      WidgetRef ref, Medication med, List<String> times, int target) async {
    final dao = ref.read(medicationDaoProvider);
    final takenLogs =
        logs.where((l) => l.medicationId == med.id && l.taken).toList();
    var count = takenLogs.length;
    final now = DateTime.now();
    while (count < target) {
      final timeStr = count < times.length ? times[count] : '';
      var sched = DateTime(now.year, now.month, now.day);
      final parts = timeStr.split(':');
      if (parts.length == 2) {
        sched = DateTime(now.year, now.month, now.day,
            int.tryParse(parts[0]) ?? 0, int.tryParse(parts[1]) ?? 0);
      }
      await dao.insertLog(MedicationLogsCompanion.insert(
        medicationId: med.id,
        scheduledAt: sched,
        takenAt: Value(now),
        taken: Value(true),
      ));
      count++;
    }
    while (count > target && takenLogs.isNotEmpty) {
      final last = takenLogs.removeLast();
      await dao.deleteLog(last.id);
      count--;
    }
  }

  List<String> _parseTimes(String t) {
    try { return (jsonDecode(t) as List).cast<String>(); } catch (_) { return []; }
  }
}

class _SuppCard extends StatelessWidget {
  final Supplement supp;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _SuppCard({required this.supp, required this.onDelete, this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('supp_${supp.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: supp.isActive
                ? TraumColors.indigoBlue.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: _icon(Icons.science_rounded, TraumColors.indigoBlueDim, TraumColors.indigoBlue),
          title: Text(supp.name,
              style: const TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          subtitle: Text(
            '${supp.dosageAmount ?? '?'} ${supp.dosageUnit ?? ''}'.trim(),
            style: const TextStyle(color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans', fontSize: 12),
          ),
          trailing: Switch(
            value: supp.isActive,
            activeThumbColor: TraumColors.indigoBlue,
            onChanged: onToggle,
          ),
        ),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _MedCard({required this.med, required this.onDelete, this.onToggle});

  @override
  Widget build(BuildContext context) {
    final times = _parseTimes(med.timings);
    return Dismissible(
      key: ValueKey('med_${med.id}'),
      direction: DismissDirection.endToStart,
      background: _deleteBg(),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: med.isActive
                ? TraumColors.roseRed.withValues(alpha: 0.3)
                : TraumColors.surfaceVariant,
          ),
        ),
        child: ListTile(
          leading: _icon(Icons.medication_rounded, TraumColors.roseRedDim, TraumColors.roseRed),
          title: Text(med.name,
              style: const TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (med.dosage != null || med.form != null)
              Text('${med.dosage ?? ''} ${med.form != null ? '· ${med.form}' : ''}'.trim(),
                  style: const TextStyle(color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 12)),
            if (times.isNotEmpty)
              Text(times.join(', '),
                  style: const TextStyle(color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans', fontSize: 11)),
          ]),
          trailing: GestureDetector(
            onTap: onToggle == null ? null : () => onToggle!(!med.isActive),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: med.isActive ? TraumColors.mintGreenDim : TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                med.isActive ? 'Aktiv' : 'Inaktiv',
                style: TextStyle(
                  color: med.isActive ? TraumColors.mintGreen : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<String> _parseTimes(String t) {
    try { return (jsonDecode(t) as List).cast<String>(); } catch (_) { return []; }
  }
}

Widget _deleteBg() => Container(
      alignment: Alignment.centerRight,
      padding: const EdgeInsets.only(right: 20),
      decoration: BoxDecoration(
        color: TraumColors.roseRed.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
    );

Widget _icon(IconData icon, Color bg, Color fg) => Container(
      width: 40, height: 40,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, color: fg, size: 20),
    );

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color dimColor;
  final VoidCallback onTap;
  const _TypeButton({required this.icon, required this.label,
      required this.color, required this.dimColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: dimColor,
            borderRadius: BorderRadius.circular(TraumRadius.card),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(color: color,
                fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13)),
          ]),
        ),
      );
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 60),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.medication_liquid_rounded, size: 64,
                color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.noSubstancesYet,
                style: TextStyle(color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 16)),
            const SizedBox(height: 8),
            Text(AppLocalizations.of(context)!.addSubstanceHint,
                style: TextStyle(color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans', fontSize: 13),
                textAlign: TextAlign.center),
          ]),
        ),
      );
}

// ─── Add sheets (copied + adapted from existing screens) ───────────────────

class _AddSuppSheet extends StatefulWidget {
  final Future<void> Function(SupplementsCompanion) onAdd;
  const _AddSuppSheet({required this.onAdd});
  @override
  State<_AddSuppSheet> createState() => _AddSuppSheetState();
}

class _AddSuppSheetState extends State<_AddSuppSheet> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  String _category = 'Vitamine';
  String _unit = 'mg';
  String? _nutrientKey; // null = "keiner"
  bool _nutrientTouched = false; // true sobald der Nutzer manuell wählt
  bool _saving = false;

  static const _categories = [
    'Vitamine', 'Mineralien', 'Aminosäuren', 'Protein', 'Omega-3',
    'Adaptogene', 'Pre-Workout', 'Darmgesundheit', 'Kreatin', 'Sonstige'
  ];
  static const _units = ['mg', 'g', 'µg', 'IU', 'ml', 'Kapsel(n)', 'Tablette(n)', 'Messbecher'];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(() {
      if (_nutrientTouched) return;
      final suggested = suggestNutrientKey(_nameCtrl.text);
      if (suggested != _nutrientKey) {
        setState(() => _nutrientKey = suggested);
      }
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addSupplement,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: 'z.B. Vitamin D3'),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.category, style: TextStyle(color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButton<String>(
            value: _category,
            dropdownColor: TraumColors.surfaceElevated,
            isExpanded: true,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            underline: Container(height: 1, color: TraumColors.surfaceVariant),
            items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
            onChanged: (v) => setState(() => _category = v!),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: _field('Menge', _amountCtrl, hint: '1000', keyboardType: TextInputType.number)),
            const SizedBox(width: 12),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(AppLocalizations.of(context)!.unitLabel, style: TextStyle(color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13)),
              const SizedBox(height: 6),
              DropdownButton<String>(
                value: _unit,
                dropdownColor: TraumColors.surfaceElevated,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                underline: Container(height: 1, color: TraumColors.surfaceVariant),
                items: _units.map((u) => DropdownMenuItem(value: u, child: Text(u))).toList(),
                onChanged: (v) => setState(() => _unit = v!),
              ),
            ]),
          ]),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.nutrientForNutrition,
              style: TextStyle(color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          DropdownButton<String?>(
            value: _nutrientKey,
            dropdownColor: TraumColors.surfaceElevated,
            isExpanded: true,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            underline: Container(height: 1, color: TraumColors.surfaceVariant),
            hint: Text(AppLocalizations.of(context)!.none,
                style: TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans')),
            items: [
              DropdownMenuItem<String?>(value: null, child: Text(AppLocalizations.of(context)!.none)),
              ...kNutrientCatalog.map((n) =>
                  DropdownMenuItem<String?>(value: n.key, child: Text(n.label))),
            ],
            onChanged: (v) => setState(() {
              _nutrientKey = v;
              _nutrientTouched = true;
            }),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving ? 'Speichern…' : 'Speichern',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, TextInputType? keyboardType}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans', fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        keyboardType: keyboardType,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true, fillColor: TraumColors.surface,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card),
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(SupplementsCompanion.insert(
      name: _nameCtrl.text.trim(),
      category: Value(_category),
      dosageAmount: Value(_amountCtrl.text.trim().isEmpty ? null : _amountCtrl.text.trim()),
      dosageUnit: Value(_unit),
      nutrientKey: Value(_nutrientKey),
    ));
    if (mounted) Navigator.pop(context);
  }
}

class _AddMedSheet extends StatefulWidget {
  final Future<void> Function(MedicationsCompanion) onAdd;
  const _AddMedSheet({required this.onAdd});
  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
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
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addMedication,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: 'z.B. Ibuprofen 400mg'),
          const SizedBox(height: 12),
          _field('Dosierung', _dosageCtrl, hint: 'z.B. 400 mg'),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.form, style: TextStyle(color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _forms.map((f) {
              final sel = f == _form;
              return GestureDetector(
                onTap: () => setState(() => _form = f),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: sel ? TraumColors.roseRedDim : TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(TraumRadius.chip),
                    border: Border.all(color: sel ? TraumColors.roseRed : Colors.transparent),
                  ),
                  child: Text(f, style: TextStyle(
                      color: sel ? TraumColors.roseRed : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans', fontSize: 13)),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Text(AppLocalizations.of(context)!.reminderTimes,
                style: TextStyle(color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontSize: 13)),
            const Spacer(),
            TextButton.icon(
              onPressed: _addTime,
              icon: const Icon(Icons.add, size: 16, color: TraumColors.coralOrange),
              label: Text(AppLocalizations.of(context)!.add,
                  style: TextStyle(color: TraumColors.coralOrange,
                      fontFamily: 'DMSans', fontSize: 12)),
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
                    color: TraumColors.roseRed, fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600)),
              ),
            ),
            if (_times.length > 1)
              IconButton(
                icon: const Icon(Icons.close, size: 16,
                    color: TraumColors.onBackgroundSubtle),
                onPressed: () => setState(() => _times.removeAt(e.key)),
              ),
          ])),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving ? 'Speichern…' : 'Speichern',
            onPressed: _saving ? null : _save,
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint}) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: const TextStyle(color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans', fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans'),
            filled: true, fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ]);

  Future<void> _addTime() async {
    final picked = await showTimePicker(
      context: context, initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
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
        data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(primary: TraumColors.roseRed)),
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
          SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
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

// ─── Konsum-Erfassung (Substanz-Einnahme-Log) ───────────────────────────────
class _AddIntakeSheet extends StatefulWidget {
  final Future<void> Function(SubstanceIntakeLogsCompanion) onAdd;
  const _AddIntakeSheet({required this.onAdd});

  @override
  State<_AddIntakeSheet> createState() => _AddIntakeSheetState();
}

class _AddIntakeSheetState extends State<_AddIntakeSheet> {
  final _nameCtrl = TextEditingController();
  final _dosageCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  DateTime _takenAt = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _dosageCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec(String label) => InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(
            color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        filled: true,
        fillColor: TraumColors.surface,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.card),
            borderSide: BorderSide.none),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      );

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                    color: TraumColors.onBackgroundSubtle,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.logConsumption,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _nameCtrl,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: _dec('Substanz'),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _dosageCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec('Dosis'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec('Einheit'),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context)!.timePoint,
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans', fontSize: 13)),
            trailing: Text(
              '${_takenAt.day.toString().padLeft(2, '0')}.${_takenAt.month.toString().padLeft(2, '0')} ${_takenAt.hour.toString().padLeft(2, '0')}:${_takenAt.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w600),
            ),
            onTap: _pickTime,
          ),
          const SizedBox(height: 12),
          GradientButton(
              label: _saving ? 'Speichern…' : 'Erfassen',
              onPressed: _saving ? null : _save),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _pickTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _takenAt,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
            colorScheme:
                const ColorScheme.dark(primary: TraumColors.coralOrange)),
        child: child!,
      ),
    );
    if (date == null) return;
    if (!mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_takenAt),
    );
    setState(() => _takenAt = DateTime(
        date.year, date.month, date.day, time?.hour ?? 0, time?.minute ?? 0));
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterSubstance)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(SubstanceIntakeLogsCompanion.insert(
      substanceName: _nameCtrl.text.trim(),
      dosage: Value(
          _dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim()),
      unit: Value(_unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim()),
      takenAt: _takenAt,
    ));
    if (mounted) Navigator.pop(context);
  }
}
