import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart' show openAppSettings;
import '../../core/components/components.dart';
import '../../core/notifications/notification_scheduler.dart';
import '../../core/notifications/reminder_time.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/models/substance_record.dart';
import '../../l10n/app_localizations.dart';
import '../nutrition/micro_nutrients.dart';

/// Editor for a medication's/supplement's list of [ReminderTime]s: add/edit/
/// remove a time-of-day, and per time-of-day toggle which weekdays it
/// applies on (defaults to every day — most medications/supplements are
/// taken daily, so that stays a single tap away, but not everyone takes
/// everything every day at the same time).
class _ReminderTimesEditor extends StatelessWidget {
  final List<ReminderTime> times;
  final Color accentColor;
  final void Function(List<ReminderTime>) onChanged;

  /// Minimum number of time entries that must remain — the remove button on
  /// an entry is hidden once [times] is down to this many. 0 (the default)
  /// allows clearing every time, meaning no reminder at all.
  final int minEntries;

  const _ReminderTimesEditor({
    required this.times,
    required this.accentColor,
    required this.onChanged,
    this.minEntries = 0,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final weekdayLabels = l10n.weekdaysShort.split(',');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Text(l10n.reminderTimes,
              style: TextStyle(color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 13)),
          const Spacer(),
          TextButton.icon(
            onPressed: () => _addTime(context),
            icon: Icon(Icons.add, size: 16, color: accentColor),
            label: Text(l10n.add,
                style: TextStyle(
                    color: accentColor, fontFamily: 'DMSans', fontSize: 12)),
          ),
        ]),
        ...times.asMap().entries.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    GestureDetector(
                      onTap: () => _editTime(context, e.key),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: TraumColors.surface,
                          borderRadius: BorderRadius.circular(TraumRadius.chip),
                          border: Border.all(
                              color: accentColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(e.value.time,
                            style: TextStyle(
                                color: accentColor,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600)),
                      ),
                    ),
                    if (times.length > minEntries)
                      IconButton(
                        tooltip: AppLocalizations.of(context)!.delete,
                        icon: const Icon(Icons.close,
                            size: 16, color: TraumColors.onBackgroundSubtle),
                        onPressed: () {
                          final next = List<ReminderTime>.of(times)..removeAt(e.key);
                          onChanged(next);
                        },
                      ),
                  ]),
                  Wrap(
                    spacing: 4,
                    children: List.generate(7, (i) {
                      final isoWeekday = i + 1;
                      final selected = e.value.days.contains(isoWeekday);
                      return GestureDetector(
                        onTap: () => _toggleDay(e.key, isoWeekday),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: selected
                                ? accentColor.withValues(alpha: 0.2)
                                : TraumColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(TraumRadius.chip),
                          ),
                          child: Text(weekdayLabels[i],
                              style: TextStyle(
                                  color: selected
                                      ? accentColor
                                      : TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600)),
                        ),
                      );
                    }),
                  ),
                ],
              ),
            )),
      ],
    );
  }

  void _toggleDay(int index, int isoWeekday) {
    final entry = times[index];
    final newDays = Set<int>.from(entry.days);
    if (newDays.contains(isoWeekday)) {
      if (newDays.length == 1) return; // keep at least one day selected
      newDays.remove(isoWeekday);
    } else {
      newDays.add(isoWeekday);
    }
    final next = List<ReminderTime>.of(times);
    next[index] = entry.copyWith(days: newDays);
    onChanged(next);
  }

  Future<void> _addTime(BuildContext context) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark()
            .copyWith(colorScheme: ColorScheme.dark(primary: accentColor)),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    onChanged([...times, ReminderTime.everyDay(formatted)]);
  }

  Future<void> _editTime(BuildContext context, int index) async {
    final parts = times[index].time.split(':');
    final picked = await showTimePicker(
      context: context,
      initialTime:
          TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1])),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark()
            .copyWith(colorScheme: ColorScheme.dark(primary: accentColor)),
        child: child!,
      ),
    );
    if (picked == null) return;
    final formatted =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
    final next = List<ReminderTime>.of(times);
    next[index] = times[index].copyWith(time: formatted);
    onChanged(next);
  }
}

/// Formats a list of [ReminderTime]s for display on a card, e.g.
/// "08:00, 20:00" when every entry applies every day, or
/// "08:00 (Mo, Mi, Fr), 20:00" once a time is restricted to specific days.
String _formatReminderTimes(BuildContext context, List<ReminderTime> times) {
  final weekdayLabels = AppLocalizations.of(context)!.weekdaysShort.split(',');
  return times.map((t) {
    if (t.isEveryDay) return t.time;
    final sortedDays = t.days.toList()..sort();
    final dayLabels = sortedDays.map((d) => weekdayLabels[d - 1]).join(', ');
    return '${t.time} ($dayLabels)';
  }).join(', ');
}

/// Re-derives every scheduled reminder (medication/supplement + all
/// Settings-driven ones) from current DB/prefs state after a medication or
/// supplement is added, edited, deleted, or (de)activated — see
/// [rescheduleAllNotifications]. Warns visibly via a SnackBar if reminders
/// are enabled but the OS notification permission is missing, instead of
/// letting the change look like it worked.
Future<void> _syncReminders(BuildContext context) async {
  final granted = await rescheduleAllNotifications(
    ProviderScope.containerOf(context, listen: false),
  );
  if (!granted && context.mounted) {
    final l10n = AppLocalizations.of(context)!;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(l10n.notifPermissionDeniedMessage),
        action: SnackBarAction(
          label: l10n.openSettings,
          onPressed: openAppSettings,
        ),
      ),
    );
  }
}

class MySubstancesTab extends ConsumerWidget {
  const MySubstancesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suppsAsync = ref.watch(supplementsStreamProvider);
    final medsAsync = ref.watch(allMedicationsStreamProvider);
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
          medsAsync.when(
            data: (meds) => logsAsync.when(
              data: (logs) => _TodayStatusCard(meds: meds, logs: logs),
              loading: () => const ShimmerLoader(width: double.infinity, height: 80),
              error: (e, _) => InlineError(e),
            ),
            loading: () => const ShimmerLoader(width: double.infinity, height: 80),
            error: (e, _) => InlineError(e),
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
                            onEdit: () => _showEditMedSheet(context, ref, med),
                            onDelete: () async {
                              await ref
                                  .read(medicationDaoProvider)
                                  .deleteMedication(med.id);
                              if (!context.mounted) return;
                              await _syncReminders(context);
                            },
                            onToggle: (active) async {
                              await ref
                                  .read(medicationDaoProvider)
                                  .setMedicationActive(med.id, active);
                              if (!context.mounted) return;
                              await _syncReminders(context);
                            },
                          )),
                      const SizedBox(height: 16),
                    ],
                    if (supps.isNotEmpty) ...[
                      SectionHeader(title: AppLocalizations.of(context)!.substanceSupplements),
                      const SizedBox(height: 8),
                      ...supps.map((s) => _SuppCard(
                            supp: s,
                            onEdit: () => _showEditSuppSheet(context, ref, s),
                            onDelete: () async {
                              await ref
                                  .read(supplementDaoProvider)
                                  .deleteSupplement(s.id);
                              if (!context.mounted) return;
                              await _syncReminders(context);
                            },
                            onToggle: (active) async {
                              await ref.read(supplementDaoProvider).updateSupplement(
                                    s.toCompanion(true).copyWith(isActive: Value(active)),
                                  );
                              if (!context.mounted) return;
                              await _syncReminders(context);
                            },
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
                label: AppLocalizations.of(context)!.substanceTypeMed,
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
                label: AppLocalizations.of(context)!.substanceTypeSupp,
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
              label: AppLocalizations.of(context)!.substanceLogIntake,
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

  void _showAddMedSheet(BuildContext context, WidgetRef ref) =>
      _showMedSheet(context, ref);

  void _showEditMedSheet(BuildContext context, WidgetRef ref, Medication med) =>
      _showMedSheet(context, ref, existing: med);

  void _showMedSheet(BuildContext context, WidgetRef ref, {Medication? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddMedSheet(
        existing: existing,
        onAdd: (companion) async {
          if (companion.id.present) {
            await ref.read(medicationDaoProvider).updateMedication(companion);
          } else {
            await ref.read(medicationDaoProvider).insertMedication(companion);
          }
          if (!ctx.mounted) return;
          await _syncReminders(ctx);
        },
      ),
    );
  }

  void _showAddSuppSheet(BuildContext context, WidgetRef ref) =>
      _showSuppSheet(context, ref);

  void _showEditSuppSheet(BuildContext context, WidgetRef ref, Supplement supp) =>
      _showSuppSheet(context, ref, existing: supp);

  void _showSuppSheet(BuildContext context, WidgetRef ref, {Supplement? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddSuppSheet(
        existing: existing,
        onAdd: (companion) async {
          if (companion.id.present) {
            await ref.read(supplementDaoProvider).updateSupplement(companion);
          } else {
            await ref.read(supplementDaoProvider).insertSupplement(companion);
          }
          if (!ctx.mounted) return;
          await _syncReminders(ctx);
        },
      ),
    );
  }
}

/// Öffnet den Medikament-Add-Sheet, vorbefüllt mit Name/Dosierung — für den
/// Cross-Tab-Einstieg aus der Substanz-Datenbank (siehe `substance_add_flow.dart`).
/// Top-level (nicht Member von [MySubstancesTab]), damit andere Dateien den
/// Sheet öffnen können, ohne eine `MySubstancesTab`-Instanz zu benötigen.
void showAddMedSheetFor(
  BuildContext context,
  WidgetRef ref, {
  String? initialName,
  String? initialDosage,
  void Function(BuildContext)? onAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
    builder: (ctx) => _AddMedSheet(
      initialName: initialName,
      initialDosage: initialDosage,
      onAdd: (companion) async {
        // Uses ctx's own ProviderScope, not the caller's `ref` — the caller
        // (substance_detail_sheet.dart) pops itself before opening this
        // sheet, so its `ref` is unmounted by the time the user hits Save.
        final container = ProviderScope.containerOf(ctx, listen: false);
        await container.read(medicationDaoProvider).insertMedication(companion);
        if (!ctx.mounted) return;
        await _syncReminders(ctx);
        // Pass the sheet's own (still-mounted) ctx — the caller's context
        // was already popped before this sheet opened.
        if (ctx.mounted) onAdded?.call(ctx);
      },
    ),
  );
}

/// Öffnet den Supplement-Add-Sheet, vorbefüllt mit Name/Kategorie — Pendant zu
/// [showAddMedSheetFor] für Supplemente.
void showAddSuppSheetFor(
  BuildContext context,
  WidgetRef ref, {
  String? initialName,
  String? initialCategory,
  String? initialAmount,
  String? initialUnit,
  void Function(BuildContext)? onAdded,
}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: TraumColors.surfaceElevated,
    shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
    builder: (ctx) => _AddSuppSheet(
      initialName: initialName,
      initialCategory: initialCategory,
      initialAmount: initialAmount,
      initialUnit: initialUnit,
      onAdd: (c) async {
        // Uses ctx's own ProviderScope, not the caller's `ref` — the caller
        // (substance_detail_sheet.dart) pops itself before opening this
        // sheet, so its `ref` is unmounted by the time the user hits Save.
        await ProviderScope.containerOf(ctx, listen: false)
            .read(supplementDaoProvider)
            .insertSupplement(c);
        // Pass the sheet's own (still-mounted) ctx — the caller's context
        // was already popped before this sheet opened.
        if (ctx.mounted) onAdded?.call(ctx);
      },
    ),
  );
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
          final todayWeekday = DateTime.now().weekday;
          final times = parseReminderTimes(med.timings)
              .where((t) => t.days.contains(todayWeekday))
              .toList();
          final takenCount = logs.where((l) => l.medicationId == med.id && l.taken).length;
          final takenList = List.generate(times.length, (i) => i < takenCount);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: MedicationDotRow(
              name: med.name,
              times: times.map((t) => t.time).toList(),
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
      WidgetRef ref, Medication med, List<ReminderTime> times, int target) async {
    final dao = ref.read(medicationDaoProvider);
    final takenLogs =
        logs.where((l) => l.medicationId == med.id && l.taken).toList();
    var count = takenLogs.length;
    final now = DateTime.now();
    while (count < target) {
      final timeStr = count < times.length ? times[count].time : '';
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
}

class _SuppCard extends StatelessWidget {
  final Supplement supp;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _SuppCard({
    required this.supp,
    required this.onEdit,
    required this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
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
          subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(
              '${supp.dosageAmount ?? '?'} ${supp.dosageUnit ?? ''}'.trim(),
              style: const TextStyle(color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans', fontSize: 12),
            ),
            if (parseReminderTimes(supp.timings).isNotEmpty)
              Text(_formatReminderTimes(context, parseReminderTimes(supp.timings)),
                  style: const TextStyle(color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans', fontSize: 11)),
          ]),
          trailing: Switch(
            value: supp.isActive,
            activeThumbColor: TraumColors.indigoBlue,
            onChanged: onToggle,
          ),
        ),
      ),
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: TraumColors.indigoBlue),
            title: Text(AppLocalizations.of(context)!.edit,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.pause_circle_outline_rounded, color: TraumColors.amberGold),
            title: Text(AppLocalizations.of(context)!.substanceDeactivate,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              onToggle?.call(!supp.isActive);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
            title: Text(AppLocalizations.of(context)!.substanceDelete,
                style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
            onTap: () async {
              final l10n = AppLocalizations.of(context)!;
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: TraumColors.surfaceElevated,
                  title: Text(l10n.substanceConfirmDeleteTitle,
                      style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
                  content: Text(l10n.substanceConfirmDeleteBody(supp.name),
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.substanceDelete)),
                  ],
                ),
              );
              if (confirmed == true) onDelete();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

class _MedCard extends StatelessWidget {
  final Medication med;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(bool)? onToggle;
  const _MedCard({
    required this.med,
    required this.onEdit,
    required this.onDelete,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final times = parseReminderTimes(med.timings);
    return GestureDetector(
      onLongPress: () => _showContextMenu(context),
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
              Text(_formatReminderTimes(context, times),
                  style: const TextStyle(color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans', fontSize: 11)),
          ]),
          trailing: Container(
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
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 12),
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: TraumColors.roseRed),
            title: Text(AppLocalizations.of(context)!.edit,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              onEdit();
            },
          ),
          ListTile(
            leading: const Icon(Icons.pause_circle_outline_rounded, color: TraumColors.amberGold),
            title: Text(AppLocalizations.of(context)!.substanceDeactivate,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              onToggle?.call(!med.isActive);
            },
          ),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
            title: Text(AppLocalizations.of(context)!.substanceDelete,
                style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
            onTap: () async {
              final l10n = AppLocalizations.of(context)!;
              Navigator.pop(context);
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: TraumColors.surfaceElevated,
                  title: Text(l10n.substanceConfirmDeleteTitle,
                      style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
                  content: Text(l10n.substanceConfirmDeleteBody(med.name),
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.substanceDelete)),
                  ],
                ),
              );
              if (confirmed == true) onDelete();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }
}

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
  final Supplement? existing;
  final String? initialName;
  final String? initialCategory;
  final String? initialAmount;
  final String? initialUnit;
  const _AddSuppSheet({
    required this.onAdd,
    this.existing,
    this.initialName,
    this.initialCategory,
    this.initialAmount,
    this.initialUnit,
  });
  @override
  State<_AddSuppSheet> createState() => _AddSuppSheetState();
}

class _AddSuppSheetState extends State<_AddSuppSheet> {
  late final _nameCtrl =
      TextEditingController(text: widget.existing?.name ?? widget.initialName ?? '');
  late final _amountCtrl = TextEditingController(
      text: widget.existing?.dosageAmount ?? widget.initialAmount ?? '');
  late String _category = _initialFrom(
      widget.existing?.category ?? widget.initialCategory, _categories, 'Vitamine');
  late String _unit =
      _initialFrom(widget.existing?.dosageUnit ?? widget.initialUnit, _units, 'mg');
  late String? _nutrientKey = widget.existing?.nutrientKey ??
      (widget.initialName != null ? suggestNutrientKey(widget.initialName!) : null);
  late final List<ReminderTime> _times = widget.existing != null
      ? parseReminderTimes(widget.existing!.timings)
      : <ReminderTime>[];
  bool _nutrientTouched = false; // true sobald der Nutzer manuell wählt
  bool _saving = false;
  List<SubstanceRecord> _suggestions = [];
  Timer? _debounce;

  static String _initialFrom(String? value, List<String> options, String fallback) =>
      value != null && options.contains(value) ? value : fallback;

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
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final q = _nameCtrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted || _nameCtrl.text.trim() != q) return;
      final repo = await ProviderScope.containerOf(context, listen: false)
          .read(substanceRepositoryProvider.future);
      final results = await repo.search(q, klasseFilter: SubstanceKlasse.supplement);
      if (mounted && _nameCtrl.text.trim() == q) {
        setState(() => _suggestions = results.take(5).toList());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
          Text(
              widget.existing != null
                  ? AppLocalizations.of(context)!.editSupplement
                  : AppLocalizations.of(context)!.addSupplement,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: AppLocalizations.of(context)!.substanceHintVitaminD3),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: Column(
                children: _suggestions.map((s) => ListTile(
                      dense: true,
                      title: Text(s.substance,
                          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
                      onTap: () {
                        _nameCtrl.text = s.substance;
                        if (s.kategorie != null && _categories.contains(s.kategorie)) {
                          setState(() => _category = s.kategorie!);
                        }
                        setState(() => _suggestions = []);
                      },
                    )).toList(),
              ),
            ),
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
          const SizedBox(height: 12),
          _ReminderTimesEditor(
            times: _times,
            accentColor: TraumColors.indigoBlue,
            onChanged: (next) => setState(() {
              _times
                ..clear()
                ..addAll(next);
            }),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving
                ? AppLocalizations.of(context)!.substanceSaving
                : AppLocalizations.of(context)!.save,
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
    final existing = widget.existing;
    final companion = existing != null
        ? existing.toCompanion(true).copyWith(
            name: Value(_nameCtrl.text.trim()),
            category: Value(_category),
            dosageAmount:
                Value(_amountCtrl.text.trim().isEmpty ? null : _amountCtrl.text.trim()),
            dosageUnit: Value(_unit),
            nutrientKey: Value(_nutrientKey),
            timings: Value(encodeReminderTimes(_times)),
          )
        : SupplementsCompanion.insert(
            name: _nameCtrl.text.trim(),
            category: Value(_category),
            dosageAmount:
                Value(_amountCtrl.text.trim().isEmpty ? null : _amountCtrl.text.trim()),
            dosageUnit: Value(_unit),
            nutrientKey: Value(_nutrientKey),
            timings: Value(encodeReminderTimes(_times)),
          );
    await widget.onAdd(companion);
    if (mounted) Navigator.pop(context);
  }
}

class _AddMedSheet extends StatefulWidget {
  final Future<void> Function(MedicationsCompanion) onAdd;
  final Medication? existing;
  final String? initialName;
  final String? initialDosage;
  const _AddMedSheet({
    required this.onAdd,
    this.existing,
    this.initialName,
    this.initialDosage,
  });
  @override
  State<_AddMedSheet> createState() => _AddMedSheetState();
}

class _AddMedSheetState extends State<_AddMedSheet> {
  late final _nameCtrl =
      TextEditingController(text: widget.existing?.name ?? widget.initialName ?? '');
  late final _dosageCtrl = TextEditingController(
      text: widget.existing?.dosage ?? widget.initialDosage ?? '');
  late String _form = widget.existing != null && _forms.contains(widget.existing!.form)
      ? widget.existing!.form!
      : 'Tablette';
  late final List<ReminderTime> _times = widget.existing != null
      ? parseReminderTimes(widget.existing!.timings)
      : [ReminderTime.everyDay('08:00')];
  bool _saving = false;
  List<SubstanceRecord> _suggestions = [];
  Timer? _debounce;

  static const _forms = ['Tablette', 'Kapsel', 'Tropfen', 'Injektion', 'Salbe', 'Spray', 'Sonstige'];

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onNameChanged);
  }

  void _onNameChanged() {
    final q = _nameCtrl.text.trim();
    _debounce?.cancel();
    if (q.length < 3) {
      if (_suggestions.isNotEmpty) setState(() => _suggestions = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 300), () async {
      if (!mounted || _nameCtrl.text.trim() != q) return;
      final repo = await ProviderScope.containerOf(context, listen: false)
          .read(substanceRepositoryProvider.future);
      final results = await repo.search(q, klasseFilter: SubstanceKlasse.medikament);
      if (mounted && _nameCtrl.text.trim() == q) {
        setState(() => _suggestions = results.take(5).toList());
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
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
          Text(
              widget.existing != null
                  ? AppLocalizations.of(context)!.editMedication
                  : AppLocalizations.of(context)!.addMedication,
              style: TextStyle(color: TraumColors.onBackground,
                  fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Name', _nameCtrl, hint: AppLocalizations.of(context)!.substanceHintIbuprofen),
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 4),
              decoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.card),
              ),
              child: Column(
                children: _suggestions.map((s) => ListTile(
                      dense: true,
                      title: Text(s.substance,
                          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
                      onTap: () {
                        _nameCtrl.text = s.substance;
                        final lang = Localizations.localeOf(context).languageCode;
                        final dosage = s.dosierung.erwachsene(lang);
                        if (dosage != null) _dosageCtrl.text = dosage;
                        setState(() => _suggestions = []);
                      },
                    )).toList(),
              ),
            ),
          const SizedBox(height: 12),
          _field('Dosierung', _dosageCtrl, hint: AppLocalizations.of(context)!.substanceHintDosageExample),
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
          _ReminderTimesEditor(
            times: _times,
            accentColor: TraumColors.roseRed,
            minEntries: 1,
            onChanged: (next) => setState(() {
              _times
                ..clear()
                ..addAll(next);
            }),
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: _saving
                ? AppLocalizations.of(context)!.substanceSaving
                : AppLocalizations.of(context)!.save,
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

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    final existing = widget.existing;
    final companion = existing != null
        ? existing.toCompanion(true).copyWith(
            name: Value(_nameCtrl.text.trim()),
            dosage: Value(_dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim()),
            form: Value(_form),
            timings: Value(encodeReminderTimes(_times)),
          )
        : MedicationsCompanion.insert(
            name: _nameCtrl.text.trim(),
            dosage: Value(_dosageCtrl.text.trim().isEmpty ? null : _dosageCtrl.text.trim()),
            form: Value(_form),
            timings: Value(encodeReminderTimes(_times)),
          );
    await widget.onAdd(companion);
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
            decoration: _dec(AppLocalizations.of(context)!.substanceLabelSubstance),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextField(
                controller: _dosageCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec(AppLocalizations.of(context)!.substanceLabelDosis),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _unitCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: _dec(AppLocalizations.of(context)!.unitLabel),
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
              label: _saving
                  ? AppLocalizations.of(context)!.substanceSaving
                  : AppLocalizations.of(context)!.substanceLogIntakeAction,
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
