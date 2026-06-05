import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import '../../core/navigation/nav_customization_sheet.dart';
import '../../core/providers/database_provider.dart';
import '../../core/services/calendar_sync_service.dart' show NativeCalendar;
import '../planning/calendar_picker_dialog.dart';
import 'feedback/feedback_bottom_sheet.dart';
import '../../core/navigation/routes.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/security/pin_service.dart';
import '../../core/services/launcher_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../l10n/app_localizations.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(
          l10n.settings,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          _LanguageSection(),
          _NavSection(),
          _CalendarSyncSection(),
          _UnitsSection(),
          _NotificationsSection(),
          _GoalsSection(),
          _CurrencySection(),
          _PeriodSection(),
          _SecuritySection(),
          if (Platform.isAndroid) _ExperimentalSection(),
          _LegalSection(),
          _SupportSection(),
          _AccountSection(),
          const SizedBox(height: 16),
          _VersionTile(),
        ],
      ),
    );
  }
}

// ─── Language ────────────────────────────────────────────────────────────────

class _LanguageSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final locale = ref.watch(localeProvider);
    final langName = locale?.languageCode == 'en' ? 'English 🇬🇧' : 'Deutsch 🇩🇪';

    return _Section(
      title: l10n.languageSection,
      child: ListTile(
        title: Text(l10n.appLanguage,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        subtitle: Text(langName,
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
        trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
        onTap: () => _showLanguageDialog(context, ref, locale),
      ),
    );
  }

  void _showLanguageDialog(BuildContext context, WidgetRef ref, Locale? current) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => SimpleDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.chooseLanguage,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        children: [
          SimpleDialogOption(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('de'));
              Navigator.pop(ctx);
            },
            child: Row(children: [
              const Text('🇩🇪  Deutsch',
                  style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
              const Spacer(),
              if (current?.languageCode != 'en')
                const Icon(Icons.check, color: TraumColors.cyanBlue, size: 18),
            ]),
          ),
          SimpleDialogOption(
            onPressed: () {
              ref.read(localeProvider.notifier).setLocale(const Locale('en'));
              Navigator.pop(ctx);
            },
            child: Row(children: [
              const Text('🇬🇧  English',
                  style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
              const Spacer(),
              if (current?.languageCode == 'en')
                const Icon(Icons.check, color: TraumColors.cyanBlue, size: 18),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Navigation ──────────────────────────────────────────────────────────────

class _NavSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.navigationSection,
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TraumColors.indigoBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.tune_rounded, color: TraumColors.indigoBlue, size: 18),
        ),
        title: Text(
          l10n.adjustNav,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        ),
        subtitle: Text(
          l10n.adjustNavSubtitle,
          style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
        onTap: () => showNavCustomizationSheet(context, ref),
      ),
    );
  }
}

// ─── Calendar Sync ───────────────────────────────────────────────────────────

class _CalendarSyncSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_CalendarSyncSection> createState() => _CalendarSyncSectionState();
}

class _CalendarSyncSectionState extends ConsumerState<_CalendarSyncSection> {
  List<NativeCalendar>? _availableCalendars;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadCalendars();
  }

  Future<void> _loadCalendars() async {
    setState(() => _loading = true);
    try {
      final cals = await ref
          .read(calendarSyncServiceProvider)
          .getAvailableCalendars();
      if (mounted) setState(() => _availableCalendars = cals);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openPicker() async {
    final calendars = _availableCalendars;
    if (calendars == null) return;
    final currentIds = ref.read(preferencesRepositoryProvider).selectedCalendarIds;
    final picked = await showCalendarPickerDialog(context, calendars, currentIds);
    if (picked != null && picked.isNotEmpty && mounted) {
      await ref.read(preferencesRepositoryProvider).setSelectedCalendarIds(picked);
      setState(() {}); // refresh subtitle
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedIds =
        ref.read(preferencesRepositoryProvider).selectedCalendarIds;
    final calendars = _availableCalendars;

    String subtitle;
    if (_loading) {
      subtitle = 'Lade Kalender…';
    } else if (selectedIds.isEmpty) {
      subtitle = 'Kein Kalender ausgewählt';
    } else if (calendars != null) {
      final names = selectedIds
          .map((id) => calendars.firstWhere(
                (c) => c.id == id,
                orElse: () => NativeCalendar(id: id, name: id),
              ).name)
          .join(', ');
      subtitle = names;
    } else {
      subtitle = '${selectedIds.length} Kalender ausgewählt';
    }

    return _Section(
      title: 'Kalender-Sync',
      child: ListTile(
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: TraumColors.lavender.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _loading
              ? const Padding(
                  padding: EdgeInsets.all(8),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TraumColors.lavender,
                  ),
                )
              : const Icon(Icons.calendar_month_rounded,
                  color: TraumColors.lavender, size: 18),
        ),
        title: const Text(
          'Synchronisierte Kalender',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontSize: 12,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: const Icon(Icons.chevron_right,
            color: TraumColors.onBackgroundMuted),
        onTap: _loading ? null : _openPicker,
      ),
    );
  }
}

// ─── Units ───────────────────────────────────────────────────────────────────

class _UnitsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final unit = ref.watch(unitSystemProvider);
    return _Section(
      title: l10n.units,
      child: Column(children: [
        SwitchListTile(
          title: Text(l10n.metricSwitch,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          subtitle: Text(l10n.metricSwitchSubtitle,
              style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
          value: unit == 'metric',
          activeThumbColor: TraumColors.coralOrange,
          onChanged: (v) =>
              ref.read(unitSystemProvider.notifier).set(v ? 'metric' : 'imperial'),
        ),
      ]),
    );
  }
}

// ─── Notifications ───────────────────────────────────────────────────────────

class _NotificationsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final repo = ref.read(preferencesRepositoryProvider);
    final medication = ref.watch(notifMedicationProvider);
    final supplement = ref.watch(notifSupplementProvider);
    final workout = ref.watch(notifWorkoutProvider);
    final water = ref.watch(notifWaterProvider);
    final habit = ref.watch(notifHabitProvider);
    final todo = ref.watch(notifTodoProvider);
    final period = ref.watch(notifPeriodProvider);
    final periodEnabled = ref.watch(isPeriodTrackingEnabledProvider);

    return _Section(
      title: l10n.notificationsSection,
      child: Column(children: [
        _NotifTile(
          title: l10n.notifMedication,
          value: medication,
          time: repo.notifMedicationTime,
          onChanged: (v) async {
            await ref.read(notifMedicationProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: () => _pickTime(context, ref, repo.notifMedicationTime,
              (t) async { await repo.setNotifMedicationTime(t); await _reschedule(ref); }),
        ),
        _NotifTile(
          title: l10n.notifSupplements,
          value: supplement,
          time: repo.notifSupplementTime,
          onChanged: (v) async {
            await ref.read(notifSupplementProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: () => _pickTime(context, ref, repo.notifSupplementTime,
              (t) async { await repo.setNotifSupplementTime(t); await _reschedule(ref); }),
        ),
        _NotifTile(
          title: l10n.notifTraining,
          value: workout,
          time: repo.notifWorkoutTime,
          onChanged: (v) async {
            await ref.read(notifWorkoutProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: () => _pickTime(context, ref, repo.notifWorkoutTime,
              (t) async { await repo.setNotifWorkoutTime(t); await _reschedule(ref); }),
        ),
        _NotifTile(
          title: l10n.notifWater,
          value: water,
          time: null,
          onChanged: (v) async {
            await ref.read(notifWaterProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: null,
        ),
        _NotifTile(
          title: l10n.notifHabits,
          value: habit,
          time: repo.notifHabitTime,
          onChanged: (v) async {
            await ref.read(notifHabitProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: () => _pickTime(context, ref, repo.notifHabitTime,
              (t) async { await repo.setNotifHabitTime(t); await _reschedule(ref); }),
        ),
        _NotifTile(
          title: l10n.notifTodos,
          value: todo,
          time: repo.notifTodoTime,
          onChanged: (v) async {
            await ref.read(notifTodoProvider.notifier).set(v);
            await _reschedule(ref);
          },
          onTimeTap: () => _pickTime(context, ref, repo.notifTodoTime,
              (t) async { await repo.setNotifTodoTime(t); await _reschedule(ref); }),
        ),
        if (periodEnabled)
          _NotifTile(
            title: l10n.notifCycle,
            value: period,
            time: null,
            onChanged: (v) async {
              await ref.read(notifPeriodProvider.notifier).set(v);
              await _reschedule(ref);
            },
            onTimeTap: null,
          ),
      ]),
    );
  }

  Future<void> _reschedule(WidgetRef ref) async {
    final repo = ref.read(preferencesRepositoryProvider);
    await NotificationService.rescheduleAll({
      'notif_medication': repo.notifMedication,
      'notif_medication_time': repo.notifMedicationTime,
      'notif_workout': repo.notifWorkout,
      'notif_workout_time': repo.notifWorkoutTime,
      'notif_habit': repo.notifHabit,
      'notif_habit_time': repo.notifHabitTime,
    });
  }

  Future<void> _pickTime(
    BuildContext context,
    WidgetRef ref,
    String currentTime,
    Future<void> Function(String) onSave,
  ) async {
    final parts = currentTime.split(':');
    final initial = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(primary: TraumColors.coralOrange),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      final formatted = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      await onSave(formatted);
    }
  }
}

class _NotifTile extends StatelessWidget {
  final String title;
  final bool value;
  final String? time;
  final void Function(bool) onChanged;
  final VoidCallback? onTimeTap;

  const _NotifTile({
    required this.title,
    required this.value,
    required this.time,
    required this.onChanged,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return SwitchListTile(
      title: Text(title,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
      subtitle: time != null && value
          ? GestureDetector(
              onTap: onTimeTap,
              child: Text(
                l10n.notifDailyAt(time!),
                style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                  fontSize: 12,
                ),
              ),
            )
          : null,
      value: value,
      activeThumbColor: TraumColors.coralOrange,
      onChanged: onChanged,
    );
  }
}

// ─── Goals ───────────────────────────────────────────────────────────────────

class _GoalsSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final kcal = ref.watch(kcalGoalNotifierProvider);
    final protein = ref.watch(proteinGoalNotifierProvider);
    final steps = ref.watch(stepsGoalNotifierProvider);
    final height = ref.watch(heightCmNotifierProvider);
    final weightGoal = ref.watch(weightGoalNotifierProvider);
    final waterGoal = ref.watch(waterGoalMlProvider);
    final unit = ref.watch(unitSystemProvider);

    return _Section(
      title: l10n.goals,
      child: Column(children: [
        _GoalTile(
          title: l10n.kcalGoalLabel,
          value: '$kcal kcal',
          onTap: () => _editIntDialog(context, l10n.kcalGoalLabel, kcal, 'kcal', (v) {
            ref.read(kcalGoalNotifierProvider.notifier).set(v);
          }),
        ),
        _GoalTile(
          title: l10n.proteinGoalLabel,
          value: '$protein g',
          onTap: () => _editIntDialog(context, l10n.proteinGoalLabel, protein, 'g', (v) {
            ref.read(proteinGoalNotifierProvider.notifier).set(v);
          }),
        ),
        _GoalTile(
          title: l10n.stepsGoalLabel,
          value: '$steps ${l10n.stepsGoalSuffix}',
          onTap: () => _editIntDialog(context, l10n.stepsGoalLabel, steps, l10n.stepsGoalSuffix, (v) {
            ref.read(stepsGoalNotifierProvider.notifier).set(v);
          }),
        ),
        _GoalTile(
          title: l10n.heightLabel,
          value: unit == 'metric'
              ? '${height.toStringAsFixed(0)} cm'
              : '${(height / 2.54).toStringAsFixed(1)} in',
          onTap: () => _editDoubleDialog(context, l10n.heightCm, height, (v) {
            ref.read(heightCmNotifierProvider.notifier).set(v);
          }),
        ),
        _GoalTile(
          title: l10n.weightGoalLabel,
          value: unit == 'metric'
              ? '${weightGoal.toStringAsFixed(1)} kg'
              : '${(weightGoal * 2.20462).toStringAsFixed(1)} lb',
          onTap: () => _editDoubleDialog(context, l10n.weightGoalCm, weightGoal, (v) {
            ref.read(weightGoalNotifierProvider.notifier).set(v);
          }),
        ),
        ListTile(
          title: Text(l10n.waterGoal,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          subtitle: Text(
            l10n.waterGoalAutomatic(waterGoal),
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
          ),
          trailing: const Icon(Icons.info_outline, color: TraumColors.onBackgroundSubtle, size: 18),
        ),
      ]),
    );
  }

  void _editIntDialog(BuildContext context, String label, int current, String unit,
      void Function(int) onSave) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(label,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: const TextStyle(color: TraumColors.onBackground),
          decoration: InputDecoration(
            suffixText: unit,
            suffixStyle: const TextStyle(color: TraumColors.onBackgroundMuted),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () {
              final v = int.tryParse(ctrl.text);
              if (v != null && v > 0) onSave(v);
              Navigator.pop(ctx);
            },
            child: Text(l10n.save,
                style: const TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
  }

  void _editDoubleDialog(BuildContext context, String label, double current,
      void Function(double) onSave) {
    final l10n = AppLocalizations.of(context)!;
    final ctrl = TextEditingController(text: current.toStringAsFixed(1));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(label,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(color: TraumColors.onBackground),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) onSave(v);
              Navigator.pop(ctx);
            },
            child: Text(l10n.save,
                style: const TextStyle(color: TraumColors.coralOrange)),
          ),
        ],
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;

  const _GoalTile({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
          const SizedBox(width: 4),
          const Icon(Icons.edit_outlined, color: TraumColors.onBackgroundSubtle, size: 16),
        ],
      ),
      onTap: onTap,
    );
  }
}

// ─── Currency ────────────────────────────────────────────────────────────────

class _CurrencySection extends ConsumerWidget {
  static const _currencies = [
    '€', r'$', '£', '¥', '₹', '₽', 'CHF', 'kr', 'zł', 'Ft', '₺', 'R\$', 'A\$', 'C\$'
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final currency = ref.watch(currencySymbolProvider);
    return _Section(
      title: l10n.currency,
      child: ListTile(
        title: Text(l10n.currencySymbol,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(currency,
                style: const TextStyle(
                    color: TraumColors.amberGold,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
          ],
        ),
        onTap: () => _showCurrencyPicker(context, ref, currency),
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, WidgetRef ref, String current) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.chooseCurrency,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _currencies.map((c) {
            final selected = c == current;
            return GestureDetector(
              onTap: () {
                ref.read(currencySymbolProvider.notifier).set(c);
                Navigator.pop(ctx);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: selected ? TraumColors.amberGold.withValues(alpha: 0.2) : TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.chip),
                  border: Border.all(
                    color: selected ? TraumColors.amberGold : TraumColors.surfaceVariant,
                  ),
                ),
                child: Text(c,
                    style: TextStyle(
                        color: selected ? TraumColors.amberGold : TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600)),
              ),
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
        ],
      ),
    );
  }
}

// ─── Period tracking ─────────────────────────────────────────────────────────

class _PeriodSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(isPeriodTrackingEnabledProvider);
    return _Section(
      title: l10n.periodTracking,
      child: SwitchListTile(
        title: Text(l10n.enablePeriodTracking,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        subtitle: Text(l10n.periodTrackingSubtitle,
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
        value: enabled,
        activeThumbColor: TraumColors.periodRose,
        onChanged: (v) => ref.read(isPeriodTrackingEnabledProvider.notifier).set(v),
      ),
    );
  }
}

// ─── Experimental ────────────────────────────────────────────────────────────

class _ExperimentalSection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_ExperimentalSection> createState() =>
      _ExperimentalSectionState();
}

class _ExperimentalSectionState extends ConsumerState<_ExperimentalSection> {
  bool _isDefaultLauncher = false;

  @override
  void initState() {
    super.initState();
    _refreshLauncherStatus();
  }

  Future<void> _refreshLauncherStatus() async {
    final isDefault =
        await ref.read(launcherServiceProvider).isDefaultLauncher();
    if (mounted) setState(() => _isDefaultLauncher = isDefault);
  }

  Future<void> _onSetLauncher() async {
    await ref.read(launcherServiceProvider).requestSetDefault();
    await _refreshLauncherStatus();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabled = ref.watch(appLauncherEnabledProvider);
    return _Section(
      title: l10n.experimentalSection,
      child: Column(
        children: [
          SwitchListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.appLauncher,
                    style: const TextStyle(
                        color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  ),
                ),
                const SizedBox(width: 8),
                const _ExperimentalBadge(),
              ],
            ),
            subtitle: Text(l10n.appLauncherSubtitle,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
            value: enabled,
            activeThumbColor: TraumColors.amberGold,
            onChanged: (v) =>
                ref.read(appLauncherEnabledProvider.notifier).set(v),
          ),
          ListTile(
            title: Row(
              children: [
                Flexible(
                  child: Text(
                    l10n.setAsLauncher,
                    style: const TextStyle(
                        color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  ),
                ),
                const SizedBox(width: 8),
                const _ExperimentalBadge(),
              ],
            ),
            subtitle: Text(
                _isDefaultLauncher
                    ? l10n.setAsLauncherActive
                    : l10n.setAsLauncherInactive,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
            trailing: Icon(
              _isDefaultLauncher
                  ? Icons.check_circle_rounded
                  : Icons.chevron_right_rounded,
              color: _isDefaultLauncher
                  ? TraumColors.amberGold
                  : TraumColors.onBackgroundSubtle,
            ),
            onTap: _onSetLauncher,
          ),
        ],
      ),
    );
  }
}

/// Kleines „Experimentell"-Badge, geteilt von den Einträgen im
/// experimentellen Bereich.
class _ExperimentalBadge extends StatelessWidget {
  const _ExperimentalBadge();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: TraumColors.amberGold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(TraumRadius.chip),
      ),
      child: Text(
        l10n.experimentalBadge,
        style: const TextStyle(
          color: TraumColors.amberGold,
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 9,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

// ─── Security ────────────────────────────────────────────────────────────────

class _SecuritySection extends ConsumerStatefulWidget {
  @override
  ConsumerState<_SecuritySection> createState() => _SecuritySectionState();
}

class _SecuritySectionState extends ConsumerState<_SecuritySection> {
  final _auth = LocalAuthentication();
  bool _biometricAvailable = false;
  List<BiometricType> _availableTypes = [];

  @override
  void initState() {
    super.initState();
    _checkBiometric();
  }

  Future<void> _checkBiometric() async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (isSupported) {
        final types = await _auth.getAvailableBiometrics();
        if (mounted) {
          setState(() {
            _biometricAvailable = true;
            _availableTypes = types;
          });
        }
      }
    } catch (_) {}
  }

  IconData get _biometricIcon {
    if (_availableTypes.contains(BiometricType.face)) return Icons.face_rounded;
    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final biometricLock = ref.watch(biometricLockProvider);
    final pinLock = ref.watch(pinLockProvider);

    return _Section(
      title: l10n.privacySecurity,
      child: Column(children: [
        SwitchListTile(
          title: Row(children: [
            Icon(_biometricIcon, color: TraumColors.coralOrange, size: 20),
            const SizedBox(width: 8),
            Text(l10n.biometric_lock,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          ]),
          subtitle: Text(
            _biometricAvailable
                ? l10n.biometricLockSubtitle
                : l10n.biometricLockUnavailable,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
          ),
          value: biometricLock,
          activeThumbColor: TraumColors.coralOrange,
          inactiveThumbColor:
              _biometricAvailable ? null : TraumColors.onBackgroundSubtle,
          onChanged: _biometricAvailable
              ? (v) => _toggleBiometric(v)
              : null,
        ),
        SwitchListTile(
          title: Row(children: [
            const Icon(Icons.pin_rounded, color: TraumColors.coralOrange, size: 20),
            const SizedBox(width: 8),
            Text(l10n.pinLock,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          ]),
          subtitle: Text(
            l10n.pinLockSubtitle,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
          ),
          value: pinLock,
          activeThumbColor: TraumColors.coralOrange,
          onChanged: (v) => _togglePin(context, v),
        ),
        if (pinLock)
          ListTile(
            leading: const Icon(Icons.edit_rounded, color: TraumColors.indigoBlue, size: 20),
            title: Text(l10n.changePin,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
            onTap: () => _changePinDialog(context),
          ),
        ListTile(
          leading: const Icon(Icons.download_rounded, color: TraumColors.cyanBlue),
          title: Text(l10n.export_data,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
          onTap: () => _showExportSheet(context),
        ),
        ListTile(
          leading: const Icon(Icons.delete_forever_rounded, color: TraumColors.roseRed),
          title: Text(l10n.delete_all_data,
              style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
          onTap: () => _confirmDeleteAll(context),
        ),
      ]),
    );
  }

  Future<void> _toggleBiometric(bool enable) async {
    if (enable) {
      try {
        final l10n = AppLocalizations.of(context)!;
        final authenticated = await _auth.authenticate(
          localizedReason: l10n.unlockReason,
          options: const AuthenticationOptions(
            biometricOnly: false,
            stickyAuth: true,
            useErrorDialogs: true,
          ),
        );
        if (authenticated) {
          await ref.read(biometricLockProvider.notifier).set(true);
        }
      } on PlatformException {
        // Auth failed or unavailable
      }
    } else {
      await ref.read(biometricLockProvider.notifier).set(false);
    }
  }

  Future<void> _togglePin(BuildContext context, bool enable) async {
    if (enable) {
      _changePinDialog(context, initial: true);
    } else {
      await PinService.clear();
      await ref.read(pinLockProvider.notifier).set(false);
    }
  }

  void _changePinDialog(BuildContext context, {bool initial = false}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PinSetupSheet(
        onSave: (pin) async {
          await PinService.save(pin);
          await ref.read(pinLockProvider.notifier).set(true);
        },
      ),
    );
  }

  void _showExportSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      isScrollControlled: true,
      builder: (ctx) => const _ExportSheet(),
    );
  }

  Future<void> _confirmDeleteAll(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.deleteAllConfirmTitle,
            style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
        content: Text(
          l10n.deleteAllConfirmContent,
          style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.continueLabel,
                style: const TextStyle(color: TraumColors.roseRed)),
          ),
        ],
      ),
    );

    if (first != true || !context.mounted) return;

    final second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.reallyDeleteAllTitle,
            style: const TextStyle(color: TraumColors.roseRed, fontFamily: 'DMSans')),
        content: Text(
          l10n.reallyDeleteAllContent,
          style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.deleteEverything,
                style: const TextStyle(color: TraumColors.roseRed, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (second != true || !context.mounted) return;

    await ref.read(preferencesRepositoryProvider).clearAll();
    if (context.mounted) context.go(Routes.onboarding);
  }
}

class _ExportSheet extends StatefulWidget {
  const _ExportSheet();

  @override
  State<_ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends State<_ExportSheet> {
  String _format = 'json';
  // Keys are module ids; labels come from l10n at build time.
  final Map<String, bool> _modules = {
    'training': false,
    'health': false,
    'nutrition': false,
    'supplements': false,
    'planning': false,
    'medication': false,
    'abstinence': false,
    'budget': false,
    'period': false,
  };

  bool get _anySelected => _modules.values.any((v) => v);

  String _moduleLabel(String key, AppLocalizations l10n) {
    switch (key) {
      case 'training':
        return l10n.training;
      case 'health':
        return l10n.health;
      case 'nutrition':
        return l10n.nutrition;
      case 'supplements':
        return l10n.supplements;
      case 'planning':
        return l10n.planning;
      case 'medication':
        return l10n.medication;
      case 'abstinence':
        return l10n.abstinence;
      case 'budget':
        return l10n.budget;
      case 'period':
        return l10n.periodTracking;
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 16, right: 16, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TraumColors.onBackgroundSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(l10n.export_data,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: TraumColors.cyanBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TraumRadius.button)),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.download_rounded),
            label: Text(l10n.exportAll, style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(l10n.exportPreparing)),
              );
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 20),
          Text(l10n.exportSelection,
              style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ..._modules.keys.map((m) => CheckboxListTile(
            title: Text(_moduleLabel(m, l10n),
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            value: _modules[m],
            activeColor: TraumColors.cyanBlue,
            checkColor: Colors.white,
            controlAffinity: ListTileControlAffinity.leading,
            onChanged: (v) => setState(() => _modules[m] = v ?? false),
          )),
          const SizedBox(height: 8),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'json', label: Text('JSON')),
              ButtonSegment(value: 'csv', label: Text('CSV')),
            ],
            selected: {_format},
            onSelectionChanged: (s) => setState(() => _format = s.first),
            style: ButtonStyle(
              backgroundColor: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) return TraumColors.cyanBlue;
                return TraumColors.surfaceVariant;
              }),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: _anySelected ? TraumColors.cyanBlue : TraumColors.surfaceVariant,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TraumRadius.button)),
              minimumSize: const Size(double.infinity, 48),
            ),
            icon: const Icon(Icons.share_rounded),
            label: Text('${l10n.exportSelected} (${_format.toUpperCase()})',
                style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            onPressed: _anySelected
                ? () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(l10n.exportPreparing)),
                    );
                    Navigator.pop(context);
                  }
                : null,
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

// ─── Legal ───────────────────────────────────────────────────────────────────

class _LegalSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.legal,
      child: Column(children: [
        _LegalTile(title: l10n.privacy_policy, asset: 'assets/legal/privacy.md'),
        _LegalTile(title: l10n.terms_of_service, asset: 'assets/legal/terms.md'),
        _LegalTile(title: l10n.medical_disclaimer, asset: 'assets/legal/disclaimer.md'),
        _LegalTile(title: l10n.open_source_licenses, asset: 'assets/legal/licenses.md'),
      ]),
    );
  }
}

class _LegalTile extends StatelessWidget {
  final String title;
  final String asset;

  const _LegalTile({required this.title, required this.asset});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(title,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
      trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundMuted),
      onTap: () => _showMarkdown(context),
    );
  }

  void _showMarkdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (_, controller) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(title,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
            ),
            Expanded(
              child: FutureBuilder<String>(
                future: rootBundle.loadString(asset),
                builder: (ctx, snap) {
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange));
                  }
                  return Markdown(
                    controller: controller,
                    data: snap.data!,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                      h1: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                      h2: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Support ─────────────────────────────────────────────────────────────────

class _SupportSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.supportSection,
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TraumColors.coralOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.feedback_outlined,
              color: TraumColors.coralOrange, size: 20),
        ),
        title: Text(
          l10n.settingsFeedback,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          l10n.settingsFeedbackSubtitle,
          style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 12,
          ),
        ),
        trailing: const Icon(Icons.chevron_right, color: TraumColors.onBackgroundSubtle),
        onTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const FeedbackBottomSheet(),
        ),
      ),
    );
  }
}

// ─── Account ─────────────────────────────────────────────────────────────────

class _AccountSection extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return _Section(
      title: l10n.appSection,
      child: Column(children: [
        ListTile(
          leading: const Icon(Icons.replay_rounded, color: TraumColors.lavender),
          title: Text(l10n.reset_onboarding,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
          subtitle: Text(l10n.repeatOnboardingSubtitle,
              style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
          onTap: () async {
            await ref.read(preferencesRepositoryProvider).setOnboardingComplete(false);
            if (context.mounted) context.go(Routes.onboarding);
          },
        ),
      ]),
    );
  }
}

// ─── Version ─────────────────────────────────────────────────────────────────

class _VersionTile extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<PackageInfo>(
      future: PackageInfo.fromPlatform(),
      builder: (ctx, snap) {
        final version = snap.hasData
            ? '${snap.data!.version} (${snap.data!.buildNumber})'
            : '…';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'TRAUM v$version',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}

// ─── Helper widgets ──────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final String title;
  final Widget child;

  const _Section({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16, top: 20, bottom: 4),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          child: child,
        ),
      ],
    );
  }
}

// ── PIN setup sheet used in Settings ─────────────────────────────────────────

class _PinSetupSheet extends StatefulWidget {
  final Future<void> Function(String pin) onSave;
  const _PinSetupSheet({required this.onSave});

  @override
  State<_PinSetupSheet> createState() => _PinSetupSheetState();
}

class _PinSetupSheetState extends State<_PinSetupSheet> {
  String _pin = '';
  String _confirm = '';
  bool _confirming = false;
  String? _error;
  bool _saving = false;

  void _addDigit(String d) {
    if (_saving) return;
    if (!_confirming) {
      if (_pin.length >= 4) return;
      setState(() { _pin += d; _error = null; });
      if (_pin.length == 4) {
        setState(() { _confirming = true; _confirm = ''; });
      }
    } else {
      if (_confirm.length >= 4) return;
      setState(() { _confirm += d; _error = null; });
      if (_confirm.length == 4) _save();
    }
  }

  void _removeDigit() {
    if (_saving) return;
    if (!_confirming && _pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    } else if (_confirming && _confirm.isNotEmpty) {
      setState(() => _confirm = _confirm.substring(0, _confirm.length - 1));
    }
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_pin != _confirm) {
      setState(() {
        _error = l10n.pinsDoNotMatch;
        _confirming = false;
        _pin = '';
        _confirm = '';
      });
      return;
    }
    setState(() => _saving = true);
    await widget.onSave(_pin);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final current = _confirming ? _confirm : _pin;
    final title = _confirming ? l10n.pinConfirmTitle : l10n.pinSetTitle;

    return Padding(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(child: Container(
            width: 40, height: 4,
            decoration: BoxDecoration(
              color: TraumColors.onBackgroundSubtle,
              borderRadius: BorderRadius.circular(2),
            ),
          )),
          const SizedBox(height: 20),
          Text(title, style: const TextStyle(
            color: TraumColors.onBackground, fontFamily: 'DMSans',
            fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(4, (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 16, height: 16,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i < current.length ? TraumColors.indigoBlue : Colors.transparent,
                border: Border.all(
                  color: i < current.length
                      ? TraumColors.indigoBlue
                      : TraumColors.onBackgroundSubtle,
                  width: 2,
                ),
              ),
            )),
          ),
          if (_error != null) ...[
            const SizedBox(height: 8),
            Text(_error!, style: const TextStyle(
                color: TraumColors.roseRed, fontFamily: 'DMSans', fontSize: 13)),
          ],
          const SizedBox(height: 24),
          _buildNumpad(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(children: [
      _buildRow(['1', '2', '3']),
      const SizedBox(height: 10),
      _buildRow(['4', '5', '6']),
      const SizedBox(height: 10),
      _buildRow(['7', '8', '9']),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        const SizedBox(width: 60),
        const SizedBox(width: 10),
        _key('0'),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _removeDigit,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              color: TraumColors.surface, shape: BoxShape.circle,
              border: Border.all(color: TraumColors.surfaceVariant),
            ),
            child: const Center(child: Icon(
              Icons.backspace_outlined,
              color: TraumColors.onBackgroundMuted, size: 20)),
          ),
        ),
      ]),
    ]);
  }

  Widget _buildRow(List<String> digits) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: digits.asMap().entries.map((e) => Padding(
      padding: EdgeInsets.only(left: e.key > 0 ? 10 : 0),
      child: _key(e.value),
    )).toList(),
  );

  Widget _key(String d) => GestureDetector(
    onTap: () => _addDigit(d),
    child: Container(
      width: 60, height: 60,
      decoration: BoxDecoration(
        color: TraumColors.surface, shape: BoxShape.circle,
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      child: Center(child: Text(d, style: const TextStyle(
        color: TraumColors.onBackground, fontFamily: 'DMSans',
        fontSize: 20, fontWeight: FontWeight.w500))),
    ),
  );
}
