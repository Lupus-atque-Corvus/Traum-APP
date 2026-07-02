import 'calendar_picker_dialog.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';


class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _runSync());
  }

  Future<void> _runSync({int depth = 0}) async {
    if (depth > 1 || !mounted) return;
    setState(() => _isSyncing = true);
    try {
      final syncService = ref.read(calendarSyncServiceProvider);
      final result = await syncService.sync();
      if (!mounted) return;

      if (result.permissionDenied) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                AppLocalizations.of(context)!.calendarAccessDeniedSyncOff),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }

      if (result.needsCalendarSelection) {
        final calendars = await syncService.getAvailableCalendars();
        if (!mounted) return;
        final currentIds = ref.read(preferencesRepositoryProvider).selectedCalendarIds;
        final picked = await showCalendarPickerDialog(context, calendars, currentIds);
        if (picked == null || picked.isEmpty || !mounted) return;
        await ref.read(preferencesRepositoryProvider).setSelectedCalendarIds(picked);
        if (!mounted) return;
        await _runSync(depth: depth + 1);
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.planning,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          if (_isSyncing)
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: TraumColors.lavender,
                  ),
                ),
              ),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TraumColors.lavender,
          labelColor: TraumColors.lavender,
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: [
            Tab(text: AppLocalizations.of(context)!.calendar),
            Tab(text: AppLocalizations.of(context)!.todosTab),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CalendarTab(),
          _TodosTab(),
        ],
      ),
    );
  }
}

// ─── Calendar tab ─────────────────────────────────────────────────────────────

class _CalendarTab extends ConsumerStatefulWidget {
  const _CalendarTab();

  @override
  ConsumerState<_CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends ConsumerState<_CalendarTab> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();
  late CalendarFormat _calendarFormat;

  @override
  void initState() {
    super.initState();
    _calendarFormat =
        ref.read(preferencesRepositoryProvider).planningCalendarFormat ==
                'week'
            ? CalendarFormat.week
            : CalendarFormat.month;
  }

  @override
  Widget build(BuildContext context) {
    final apptAsync = ref.watch(allAppointmentsStreamProvider);
    final dayApptAsync = ref.watch(appointmentsForDateProvider(_selectedDay));

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.lavender,
        onPressed: () => _showAddAppointment(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          apptAsync.when(
            data: (appts) {
              final events = <DateTime, List<Appointment>>{};
              for (final a in appts) {
                final day = DateTime(a.startTime.year, a.startTime.month, a.startTime.day);
                events.putIfAbsent(day, () => []).add(a);
              }
              return TableCalendar<Appointment>(
                firstDay: DateTime(2000),
                lastDay: DateTime(2100),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                availableCalendarFormats: {
                  CalendarFormat.month: AppLocalizations.of(context)!.periodMonth,
                  CalendarFormat.week: AppLocalizations.of(context)!.periodWeek,
                },
                onFormatChanged: (format) {
                  setState(() => _calendarFormat = format);
                  ref.read(preferencesRepositoryProvider).setPlanningCalendarFormat(
                      format == CalendarFormat.week ? 'week' : 'month');
                },
                selectedDayPredicate: (d) => isSameDay(d, _selectedDay),
                eventLoader: (day) {
                  final key = DateTime(day.year, day.month, day.day);
                  return events[key] ?? [];
                },
                onDaySelected: (selected, focused) => setState(() {
                  _selectedDay = selected;
                  _focusedDay = focused;
                }),
                onPageChanged: (focused) => setState(() => _focusedDay = focused),
                calendarStyle: CalendarStyle(
                  outsideDaysVisible: false,
                  defaultTextStyle: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  weekendTextStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  todayDecoration: BoxDecoration(
                    color: TraumColors.lavender.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: TraumColors.lavender,
                    shape: BoxShape.circle,
                  ),
                  markerDecoration: const BoxDecoration(color: TraumColors.coralOrange, shape: BoxShape.circle),
                ),
                headerStyle: HeaderStyle(
                  formatButtonVisible: true,
                  formatButtonShowsNext: false,
                  titleCentered: true,
                  titleTextFormatter: (date, locale) =>
                      '${DateFormat.yMMMM(locale).format(date)} · ${date.month}',
                  titleTextStyle: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                  leftChevronIcon: const Icon(Icons.chevron_left, color: TraumColors.onBackground),
                  rightChevronIcon: const Icon(Icons.chevron_right, color: TraumColors.onBackground),
                  formatButtonTextStyle: const TextStyle(
                      color: TraumColors.lavender, fontFamily: 'DMSans', fontSize: 12,
                      fontWeight: FontWeight.w600),
                  formatButtonDecoration: BoxDecoration(
                    border: Border.all(color: TraumColors.lavender.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
                  weekendStyle: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 12),
                ),
              );
            },
            loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: TraumColors.lavender))),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const Divider(color: TraumColors.surfaceVariant, height: 1),
          Expanded(
            child: dayApptAsync.when(
              data: (appts) {
                if (appts.isEmpty) {
                  return Center(
                    child: Text(
                      AppLocalizations.of(context)!.noAppointmentsOnDate('${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}'),
                      style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: appts.length,
                  itemBuilder: (ctx, i) {
                    final a = appts[i];
                    return Dismissible(
                      key: ValueKey(a.id),
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
                      onDismissed: (_) => ref.read(calendarSyncServiceProvider).deleteAppointmentWithSync(a.id),
                      child: AppointmentChip(
                        title: a.title,
                        time: '${a.startTime.hour.toString().padLeft(2, '0')}:${a.startTime.minute.toString().padLeft(2, '0')}',
                        color: a.color != null ? Color(a.color!) : TraumColors.lavender,
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.lavender)),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddAppointment(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddAppointmentSheet(
        initialDate: _selectedDay,
        onAdd: (c) async {
          final id = await ref.read(planningDaoProvider).insertAppointment(c);
          // Push immediately to device calendar without waiting
          ref.read(calendarSyncServiceProvider).syncNewAppointment(id);
        },
      ),
    );
  }
}

class _AddAppointmentSheet extends StatefulWidget {
  final DateTime initialDate;
  final Future<void> Function(AppointmentsCompanion) onAdd;
  const _AddAppointmentSheet({required this.initialDate, required this.onAdd});

  @override
  State<_AddAppointmentSheet> createState() => _AddAppointmentSheetState();
}

class _AddAppointmentSheetState extends State<_AddAppointmentSheet> {
  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  late DateTime _startTime;
  late DateTime _endTime;

  @override
  void initState() {
    super.initState();
    _startTime = DateTime(widget.initialDate.year, widget.initialDate.month, widget.initialDate.day, DateTime.now().hour + 1, 0);
    _endTime = _startTime.add(const Duration(hours: 1));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _locationCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.addAppointment, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            _buildField(AppLocalizations.of(context)!.titleRequiredField, _titleCtrl),
            const SizedBox(height: 10),
            _buildField(AppLocalizations.of(context)!.location, _locationCtrl, hint: AppLocalizations.of(context)!.optional),
            const SizedBox(height: 10),
            _buildField(AppLocalizations.of(context)!.fieldDescription, _descCtrl, hint: AppLocalizations.of(context)!.optional, maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateTimeTile(
                label: AppLocalizations.of(context)!.startLabel,
                dateTime: _startTime,
                color: TraumColors.lavender,
                onChanged: (dt) => setState(() { _startTime = dt; if (_endTime.isBefore(_startTime)) _endTime = _startTime.add(const Duration(hours: 1)); }),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateTimeTile(
                label: AppLocalizations.of(context)!.endLabel,
                dateTime: _endTime,
                color: TraumColors.lavender,
                onChanged: (dt) => setState(() => _endTime = dt),
              )),
            ]),
            const SizedBox(height: 20),
            GradientButton(
              label: AppLocalizations.of(context)!.save,
              onPressed: () async {
                if (_titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.titleRequired)));
                  return;
                }
                await widget.onAdd(AppointmentsCompanion.insert(
                  title: _titleCtrl.text.trim(),
                  description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
                  location: Value(_locationCtrl.text.trim().isEmpty ? null : _locationCtrl.text.trim()),
                  startTime: _startTime,
                  endTime: Value(_endTime),
                ));
                if (context.mounted) Navigator.pop(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, {String? hint, int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
      decoration: InputDecoration(
        labelText: label, hintText: hint,
        labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
        hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
        filled: true, fillColor: TraumColors.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

class _DateTimeTile extends StatelessWidget {
  final String label;
  final DateTime dateTime;
  final Color color;
  final void Function(DateTime) onChanged;

  const _DateTimeTile({required this.label, required this.dateTime, required this.color, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final date = await showDatePicker(
          context: context, initialDate: dateTime,
          firstDate: DateTime(2000), lastDate: DateTime(2100),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: color)),
            child: child!,
          ),
        );
        if (date == null || !context.mounted) return;
        final time = await showTimePicker(
          context: context, initialTime: TimeOfDay.fromDateTime(dateTime),
          builder: (ctx, child) => Theme(
            data: ThemeData.dark().copyWith(colorScheme: ColorScheme.dark(primary: color)),
            child: child!,
          ),
        );
        if (time == null) return;
        onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(color: color, fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text(
            '${dateTime.day.toString().padLeft(2, '0')}.${dateTime.month.toString().padLeft(2, '0')} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}',
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ]),
      ),
    );
  }
}

// ─── Todos tab ────────────────────────────────────────────────────────────────

class _TodosTab extends ConsumerWidget {
  const _TodosTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todosAsync = ref.watch(allTodosStreamProvider);

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.lavender,
        onPressed: () => _showAddTodo(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: todosAsync.when(
        data: (todos) {
          if (todos.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.check_circle_outline_rounded, size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noTasks, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tapToAddTask,
                    style: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13), textAlign: TextAlign.center),
              ]),
            );
          }
          final open = todos.where((t) => !t.done).toList();
          final done = todos.where((t) => t.done).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (open.isNotEmpty) ...[
                SectionHeader(title: AppLocalizations.of(context)!.open),
                const SizedBox(height: 8),
                ...open.map((t) => _TodoTile(todo: t, ref: ref)),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionHeader(title: AppLocalizations.of(context)!.finished),
                const SizedBox(height: 8),
                ...done.map((t) => _TodoTile(todo: t, ref: ref)),
              ],
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.lavender)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddTodo(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddTodoSheet(
        onAdd: (c) => ref.read(planningDaoProvider).insertTodo(c),
      ),
    );
  }
}

class _TodoTile extends StatelessWidget {
  final Todo todo;
  final WidgetRef ref;
  const _TodoTile({required this.todo, required this.ref});

  @override
  Widget build(BuildContext context) {
    final priorityColor = todo.priority == 2
        ? TraumColors.roseRed
        : todo.priority == 1
            ? TraumColors.amberGold
            : TraumColors.onBackgroundSubtle;

    return Dismissible(
      key: ValueKey(todo.id),
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
      onDismissed: (_) => ref.read(planningDaoProvider).deleteTodo(todo.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: CheckboxListTile(
          value: todo.done,
          activeColor: TraumColors.mintGreen,
          checkColor: Colors.white,
          controlAffinity: ListTileControlAffinity.leading,
          onChanged: (v) => ref.read(planningDaoProvider).updateTodo(
            TodosCompanion(
              id: Value(todo.id),
              title: Value(todo.title),
              done: Value(v ?? false),
              completedAt: Value(v == true ? DateTime.now() : null),
            ),
          ),
          title: Text(
            todo.title,
            style: TextStyle(
              color: todo.done ? TraumColors.onBackgroundSubtle : TraumColors.onBackground,
              fontFamily: 'DMSans',
              decoration: todo.done ? TextDecoration.lineThrough : null,
            ),
          ),
          subtitle: todo.dueDate != null
              ? Text(AppLocalizations.of(context)!.dueDateLabel('${todo.dueDate!.day}.${todo.dueDate!.month}.${todo.dueDate!.year}'),
                  style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11))
              : null,
          secondary: Container(
            width: 8, height: 8,
            decoration: BoxDecoration(color: priorityColor, shape: BoxShape.circle),
          ),
        ),
      ),
    );
  }
}

class _AddTodoSheet extends StatefulWidget {
  final Future<void> Function(TodosCompanion) onAdd;
  const _AddTodoSheet({required this.onAdd});

  @override
  State<_AddTodoSheet> createState() => _AddTodoSheetState();
}

class _AddTodoSheetState extends State<_AddTodoSheet> {
  final _titleCtrl = TextEditingController();
  int _priority = 0;
  DateTime? _dueDate;

  @override
  void dispose() { _titleCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          Text(AppLocalizations.of(context)!.addTask, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
              fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context)!.fieldTitle,
              labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              filled: true, fillColor: TraumColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          Text(AppLocalizations.of(context)!.fieldPriority, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _PriorityChip(label: AppLocalizations.of(context)!.priorityLow, value: 0, selected: _priority == 0, color: TraumColors.onBackgroundSubtle, onTap: () => setState(() => _priority = 0)),
            const SizedBox(width: 8),
            _PriorityChip(label: AppLocalizations.of(context)!.priorityMedium, value: 1, selected: _priority == 1, color: TraumColors.amberGold, onTap: () => setState(() => _priority = 1)),
            const SizedBox(width: 8),
            _PriorityChip(label: AppLocalizations.of(context)!.priorityHigh, value: 2, selected: _priority == 2, color: TraumColors.roseRed, onTap: () => setState(() => _priority = 2)),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(AppLocalizations.of(context)!.dueDate, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            trailing: Text(
              _dueDate != null
                  ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                  : AppLocalizations.of(context)!.noDate,
              style: TextStyle(
                color: _dueDate != null ? TraumColors.lavender : TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans', fontWeight: FontWeight.w600,
              ),
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _dueDate ?? DateTime.now(),
                firstDate: DateTime(2000), lastDate: DateTime(2100),
                builder: (ctx, child) => Theme(
                  data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.lavender)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _dueDate = picked);
            },
          ),
          const SizedBox(height: 20),
          GradientButton(
            label: AppLocalizations.of(context)!.save,
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.titleRequired)));
                return;
              }
              await widget.onAdd(TodosCompanion.insert(
                title: _titleCtrl.text.trim(),
                priority: Value(_priority),
                dueDate: Value(_dueDate),
              ));
              if (context.mounted) Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _PriorityChip extends StatelessWidget {
  final String label;
  final int value;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _PriorityChip({required this.label, required this.value, required this.selected, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.2) : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(TraumRadius.chip),
          border: Border.all(color: selected ? color : Colors.transparent),
        ),
        child: Text(label, style: TextStyle(
            color: selected ? color : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans', fontSize: 13)),
      ),
    );
  }
}

