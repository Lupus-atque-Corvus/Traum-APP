import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/progress_icon.dart';

class AbstinenceScreen extends ConsumerStatefulWidget {
  const AbstinenceScreen({super.key});

  @override
  ConsumerState<AbstinenceScreen> createState() => _AbstinenceScreenState();
}

class _AbstinenceScreenState extends ConsumerState<AbstinenceScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text(
          'Fortschritt',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TraumColors.roseRed,
          labelColor: TraumColors.roseRed,
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: [
            Tab(text: l10n.abstinence),
            Tab(text: l10n.goalsTab),
            Tab(text: l10n.habitsTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _AbstinenceTab(),
          _GoalsTab(),
          _HabitsTab(),
        ],
      ),
    );
  }
}

// ─── Abstinence tab ───────────────────────────────────────────────────────────

class _AbstinenceTab extends ConsumerWidget {
  const _AbstinenceTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackersAsync = ref.watch(abstinenceTrackersStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddDialog(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: trackersAsync.when(
        data: (trackers) {
          if (trackers.isEmpty) return const _EmptyState();
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trackers.length,
            itemBuilder: (ctx, i) => _TrackerCard(
              tracker: trackers[i],
              onDelete: () =>
                  ref.read(abstinenceDaoProvider).deleteTracker(trackers[i].id),
              onRelapse: () =>
                  _showRelapseDialog(context, ref, trackers[i]),
            ),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.roseRed)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddDialog(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddTrackerSheet(
        onAdd: (c) => ref.read(abstinenceDaoProvider).insertTracker(c),
      ),
    );
  }

  void _showRelapseDialog(
      BuildContext context, WidgetRef ref, AbstinenceTracker tracker) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(AppLocalizations.of(ctx)!.relapseAt(tracker.name),
            style: const TextStyle(
                color: TraumColors.roseRed, fontFamily: 'DMSans')),
        content: Text(
          AppLocalizations.of(ctx)!.relapseDescription,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style:
                    const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final now = DateTime.now();
              await ref.read(abstinenceDaoProvider).insertEvent(
                    AbstinenceEventsCompanion.insert(
                      trackerId: tracker.id,
                      type: 'relapse',
                      eventDate: now,
                    ),
                  );
              await ref.read(abstinenceDaoProvider).updateTracker(
                    AbstinenceTrackersCompanion(
                      id: Value(tracker.id),
                      name: Value(tracker.name),
                      startDate: Value(now),
                      isActive: Value(tracker.isActive),
                      createdAt: Value(tracker.createdAt),
                    ),
                  );
            },
            child: Text(AppLocalizations.of(ctx)!.confirmRelapse,
                style: const TextStyle(
                    color: TraumColors.roseRed,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ─── Goals tab ────────────────────────────────────────────────────────────────

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allGoalsStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.lavender,
        onPressed: () => _showAddGoal(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.flag_rounded,
                    size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noGoals,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (ctx, i) => _GoalCard(goal: goals[i], ref: ref),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.lavender)),
        error: (e, _) => Center(
            child: Text('$e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) =>
          _AddGoalSheet(onAdd: (c) => ref.read(planningDaoProvider).insertGoal(c)),
    );
  }
}

class _GoalCard extends StatelessWidget {
  final Goal goal;
  final WidgetRef ref;
  const _GoalCard({required this.goal, required this.ref});

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetValue != null && goal.targetValue! > 0
        ? (goal.currentValue / goal.targetValue!).clamp(0.0, 1.0)
        : 0.0;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: TraumColors.roseRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(TraumRadius.card)),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => ref.read(planningDaoProvider).deleteGoal(goal.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border:
              Border.all(color: TraumColors.lavender.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                  child: Text(goal.title,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700))),
              if (goal.done)
                Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: TraumColors.mintGreenDim,
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(AppLocalizations.of(context)!.reached,
                        style: const TextStyle(
                            color: TraumColors.mintGreen,
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w600))),
            ]),
            if (goal.description != null) ...[
              const SizedBox(height: 4),
              Text(goal.description!,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
            ],
            if (goal.targetValue != null) ...[
              const SizedBox(height: 10),
              GradientProgressBar(
                value: progress,
                gradient: const LinearGradient(
                    colors: [TraumColors.lavender, TraumColors.indigoBlue]),
              ),
              const SizedBox(height: 4),
              Text(
                  '${goal.currentValue} / ${goal.targetValue} ${goal.unit ?? ''}',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 11)),
            ],
            if (goal.targetDate != null) ...[
              const SizedBox(height: 6),
              Text(
                  '${AppLocalizations.of(context)!.deadline}: ${goal.targetDate!.day}.${goal.targetDate!.month}.${goal.targetDate!.year}',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans',
                      fontSize: 11)),
            ],
          ]),
        ),
      ),
    );
  }
}

class _AddGoalSheet extends StatefulWidget {
  final Future<void> Function(GoalsCompanion) onAdd;
  const _AddGoalSheet({required this.onAdd});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  DateTime? _deadline;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(l10n.addGoal,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 16),
              _field(l10n.titleRequiredField, _titleCtrl),
              const SizedBox(height: 10),
              _field(l10n.fieldDescription, _descCtrl, maxLines: 2),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _field(l10n.targetValue, _targetCtrl,
                        keyboard: TextInputType.number)),
                const SizedBox(width: 12),
                Expanded(
                    child: _field(l10n.fieldUnit, _unitCtrl,
                        hint: l10n.unitHintKgKm)),
              ]),
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.deadline,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 13)),
                trailing: Text(
                    _deadline != null
                        ? '${_deadline!.day}.${_deadline!.month}.${_deadline!.year}'
                        : l10n.noDate,
                    style: TextStyle(
                        color: _deadline != null
                            ? TraumColors.lavender
                            : TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600)),
                onTap: () async {
                  final p = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (ctx, child) => Theme(
                          data: ThemeData.dark().copyWith(
                              colorScheme: const ColorScheme.dark(
                                  primary: TraumColors.lavender)),
                          child: child!));
                  if (p != null) setState(() => _deadline = p);
                },
              ),
              const SizedBox(height: 20),
              GradientButton(
                  label: l10n.save,
                  onPressed: () async {
                    if (_titleCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.titleRequired)));
                      return;
                    }
                    await widget.onAdd(GoalsCompanion.insert(
                      title: _titleCtrl.text.trim(),
                      description: Value(_descCtrl.text.trim().isEmpty
                          ? null
                          : _descCtrl.text.trim()),
                      targetValue:
                          Value(int.tryParse(_targetCtrl.text)),
                      unit: Value(_unitCtrl.text.trim().isEmpty
                          ? null
                          : _unitCtrl.text.trim()),
                      targetDate: Value(_deadline),
                    ));
                    if (context.mounted) Navigator.pop(context);
                  }),
              const SizedBox(height: 8),
            ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl,
      {String? hint, int maxLines = 1, TextInputType? keyboard}) {
    return TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboard,
        style: const TextStyle(
            color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            labelStyle: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
            hintStyle: const TextStyle(
                color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
            filled: true,
            fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 12)));
  }
}

// ─── Habits tab ───────────────────────────────────────────────────────────────

class _HabitsTab extends ConsumerWidget {
  const _HabitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(allHabitsStreamProvider);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final logsAsync = ref.watch(habitLogsForDateProvider(today));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.lavender,
        onPressed: () => _showAddHabit(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: habitsAsync.when(
        data: (habits) {
          if (habits.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.loop_rounded,
                    size: 64,
                    color:
                        TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noHabits,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tapToAddHabit,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }
          return logsAsync.when(
            data: (logs) => ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: habits.length,
              itemBuilder: (ctx, i) => _HabitTile(
                habit: habits[i],
                isCheckedToday: logs.any((l) => l.habitId == habits[i].id),
                onToggle: (checked) async {
                  if (checked) {
                    await ref.read(planningDaoProvider).insertHabitLog(
                          HabitLogsCompanion.insert(
                              habitId: habits[i].id, logDate: today),
                        );
                  } else {
                    await ref
                        .read(planningDaoProvider)
                        .deleteHabitLog(habits[i].id, today);
                  }
                },
                onDelete: () =>
                    ref.read(planningDaoProvider).deleteHabit(habits[i].id),
                ref: ref,
              ),
            ),
            loading: () => const Center(
                child:
                    CircularProgressIndicator(color: TraumColors.lavender)),
            error: (_, _) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.lavender)),
        error: (e, _) => Center(
            child: Text('$e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddHabit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddHabitSheet(
          onAdd: (c) => ref.read(planningDaoProvider).insertHabit(c)),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final bool isCheckedToday;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;
  final WidgetRef ref;

  const _HabitTile(
      {required this.habit,
      required this.isCheckedToday,
      required this.onToggle,
      required this.onDelete,
      required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last7Async = ref.watch(habitLogsLast7DaysProvider(habit.id));

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
            color: TraumColors.roseRed.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(TraumRadius.card)),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
              color: isCheckedToday
                  ? TraumColors.mintGreen.withValues(alpha: 0.3)
                  : TraumColors.surfaceVariant),
        ),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(children: [
            Row(children: [
              ProgressIcon(habit.emoji, size: 20, color: TraumColors.lavender),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(habit.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: () => onToggle(!isCheckedToday),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: isCheckedToday
                        ? TraumColors.mintGreen
                        : TraumColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                      isCheckedToday
                          ? Icons.check_rounded
                          : Icons.add_rounded,
                      color: Colors.white,
                      size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            last7Async.when(
              data: (logs) {
                final weekStatus = List.generate(7, (i) {
                  final day =
                      DateTime.now().subtract(Duration(days: 6 - i));
                  return logs.any((l) => _isSameDay(l.logDate, day));
                });
                return HabitWeekRow(
                    habitName: '', weekStatus: weekStatus);
              },
              loading: () => const SizedBox(height: 28),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _AddHabitSheet extends StatefulWidget {
  final Future<void> Function(HabitsCompanion) onAdd;
  const _AddHabitSheet({required this.onAdd});

  @override
  State<_AddHabitSheet> createState() => _AddHabitSheetState();
}

class _AddHabitSheetState extends State<_AddHabitSheet> {
  final _nameCtrl = TextEditingController();
  String _iconKey = kDefaultProgressIcon;
  String _frequency = 'daily';

  @override
  void dispose() {
    _nameCtrl.dispose();
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
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
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
                          borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text(l10n.addHabit,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 18)),
              const SizedBox(height: 16),
              TextField(
                  controller: _nameCtrl,
                  autofocus: true,
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                      labelText: l10n.fieldName,
                      labelStyle: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans'),
                      filled: true,
                      fillColor: TraumColors.surface,
                      border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(TraumRadius.card),
                          borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12))),
              const SizedBox(height: 12),
              Text('Icon',
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
              const SizedBox(height: 6),
              GestureDetector(
                onTap: () async {
                  final picked = await showIconPickerSheet(context,
                      selected: _iconKey, accentColor: TraumColors.lavender);
                  if (picked != null) setState(() => _iconKey = picked);
                },
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: TraumColors.lavenderDim,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: TraumColors.lavender)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    ProgressIcon(_iconKey,
                        size: 22, color: TraumColors.lavender),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_rounded,
                        size: 14, color: TraumColors.onBackgroundMuted),
                  ]),
                ),
              ),
              const SizedBox(height: 12),
              Text(l10n.frequency,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
              const SizedBox(height: 6),
              Row(children: [
                _FreqChip(
                    label: l10n.frequencyDaily,
                    value: 'daily',
                    selected: _frequency == 'daily',
                    onTap: () => setState(() => _frequency = 'daily')),
                const SizedBox(width: 8),
                _FreqChip(
                    label: l10n.frequencyWeekly,
                    value: 'weekly',
                    selected: _frequency == 'weekly',
                    onTap: () => setState(() => _frequency = 'weekly')),
              ]),
              const SizedBox(height: 20),
              GradientButton(
                  label: l10n.save,
                  onPressed: () async {
                    if (_nameCtrl.text.trim().isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(l10n.nameRequired)));
                      return;
                    }
                    await widget.onAdd(HabitsCompanion.insert(
                        name: _nameCtrl.text.trim(),
                        emoji: Value(_iconKey),
                        frequency: Value(_frequency)));
                    if (context.mounted) Navigator.pop(context);
                  }),
              const SizedBox(height: 8),
            ]),
      ),
    );
  }
}

class _FreqChip extends StatelessWidget {
  final String label, value;
  final bool selected;
  final VoidCallback onTap;

  const _FreqChip(
      {required this.label,
      required this.value,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected
                ? TraumColors.lavenderDim
                : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(TraumRadius.chip),
            border: Border.all(
                color: selected
                    ? TraumColors.lavender
                    : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected
                      ? TraumColors.lavender
                      : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 13)),
        ));
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────

class _TrackerCard extends StatefulWidget {
  final AbstinenceTracker tracker;
  final VoidCallback onDelete;
  final VoidCallback onRelapse;

  const _TrackerCard(
      {required this.tracker,
      required this.onDelete,
      required this.onRelapse});

  @override
  State<_TrackerCard> createState() => _TrackerCardState();
}

class _TrackerCardState extends State<_TrackerCard> {
  late Timer _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateElapsed();
    _timer = Timer.periodic(
        const Duration(seconds: 1), (_) => _updateElapsed());
  }

  void _updateElapsed() {
    if (mounted) {
      setState(() =>
          _elapsed = DateTime.now().difference(widget.tracker.startDate));
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _elapsed.inDays;
    final hours = _elapsed.inHours % 24;
    final minutes = _elapsed.inMinutes % 60;
    final seconds = _elapsed.inSeconds % 60;
    final l10n = AppLocalizations.of(context)!;

    return Dismissible(
      key: ValueKey(widget.tracker.id),
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
      onDismissed: (_) => widget.onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border:
              Border.all(color: TraumColors.roseRed.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                ProgressIcon(widget.tracker.emoji,
                    size: 24, color: TraumColors.roseRed),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(widget.tracker.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 18)),
                ),
                TextButton(
                  onPressed: widget.onRelapse,
                  style: TextButton.styleFrom(
                      foregroundColor: TraumColors.roseRed),
                  child: Text(l10n.relapse,
                      style: const TextStyle(
                          fontFamily: 'DMSans', fontSize: 12)),
                ),
              ]),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _TimeUnit(value: days, label: l10n.daysShort),
                  const Text(':',
                      style: TextStyle(
                          color: TraumColors.roseRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 28)),
                  _TimeUnit(value: hours, label: l10n.hoursShort),
                  const Text(':',
                      style: TextStyle(
                          color: TraumColors.roseRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 28)),
                  _TimeUnit(value: minutes, label: l10n.minutesShort),
                  const Text(':',
                      style: TextStyle(
                          color: TraumColors.roseRed,
                          fontWeight: FontWeight.w700,
                          fontSize: 28)),
                  _TimeUnit(value: seconds, label: l10n.secondsShort),
                ],
              ),
              if (widget.tracker.note != null) ...[
                const SizedBox(height: 8),
                Text(widget.tracker.note!,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TimeUnit extends StatelessWidget {
  final int value;
  final String label;
  const _TimeUnit({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Text(value.toString().padLeft(2, '0'),
          style: const TextStyle(
              color: TraumColors.roseRed,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 28)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 11)),
    ]);
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.block_rounded,
            size: 64,
            color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Text(AppLocalizations.of(context)!.noTrackers,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.tapToStartTracker,
            style: const TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                fontSize: 13),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

class _AddTrackerSheet extends StatefulWidget {
  final Future<void> Function(AbstinenceTrackersCompanion) onAdd;
  const _AddTrackerSheet({required this.onAdd});

  @override
  State<_AddTrackerSheet> createState() => _AddTrackerSheetState();
}

class _AddTrackerSheetState extends State<_AddTrackerSheet> {
  final _nameCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _costCtrl = TextEditingController();
  String _iconKey = kDefaultProgressIcon;
  DateTime _startDate = DateTime.now();
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _noteCtrl.dispose();
    _costCtrl.dispose();
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
                        borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(l10n.startTracker,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            TextField(
              controller: _nameCtrl,
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: l10n.whatToAvoid,
                labelStyle: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            Text('Icon',
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: () async {
                final picked = await showIconPickerSheet(context,
                    selected: _iconKey, accentColor: TraumColors.roseRed);
                if (picked != null) setState(() => _iconKey = picked);
              },
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: TraumColors.roseRedDim,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: TraumColors.roseRed)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  ProgressIcon(_iconKey, size: 22, color: TraumColors.roseRed),
                  const SizedBox(width: 8),
                  const Icon(Icons.edit_rounded,
                      size: 14, color: TraumColors.onBackgroundMuted),
                ]),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.startDate,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
              trailing: Text(
                '${_startDate.day.toString().padLeft(2, '0')}.${_startDate.month.toString().padLeft(2, '0')}.${_startDate.year}',
                style: const TextStyle(
                    color: TraumColors.coralOrange,
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
                        colorScheme: const ColorScheme.dark(
                            primary: TraumColors.roseRed)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _startDate = picked);
              },
            ),
            TextField(
              controller: _noteCtrl,
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans'),
              maxLines: 2,
              decoration: InputDecoration(
                labelText: l10n.motivationOptional,
                labelStyle: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _costCtrl,
              style: const TextStyle(
                  color: TraumColors.onBackground, fontFamily: 'DMSans'),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Kosten pro Tag (€, optional)',
                labelStyle: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans'),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
            const SizedBox(height: 20),
            GradientButton(
                label: _saving ? l10n.starting : l10n.startTrackerButton,
                onPressed: _saving ? null : _save),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(AbstinenceTrackersCompanion.insert(
      name: _nameCtrl.text.trim(),
      emoji: Value(_iconKey),
      startDate: _startDate,
      note: Value(
          _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
      costPerDay:
          Value(double.tryParse(_costCtrl.text.trim().replaceAll(',', '.'))),
    ));
    if (mounted) Navigator.pop(context);
  }
}
