import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class PlanningScreen extends ConsumerStatefulWidget {
  const PlanningScreen({super.key});

  @override
  ConsumerState<PlanningScreen> createState() => _PlanningScreenState();
}

class _PlanningScreenState extends ConsumerState<PlanningScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
        title: const Text('Planung',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: TraumColors.lavender,
          labelColor: TraumColors.lavender,
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Kalender'),
            Tab(text: 'Todos'),
            Tab(text: 'Ziele'),
            Tab(text: 'Gewohnheiten'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _CalendarTab(),
          _TodosTab(),
          _GoalsTab(),
          _HabitsTab(),
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

  @override
  Widget build(BuildContext context) {
    final apptAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchAllAppointments()),
    );
    final dayApptAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchAppointmentsForDate(_selectedDay)),
    );

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
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                  leftChevronIcon: Icon(Icons.chevron_left, color: TraumColors.onBackground),
                  rightChevronIcon: Icon(Icons.chevron_right, color: TraumColors.onBackground),
                ),
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12),
                  weekendStyle: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 12),
                ),
              );
            },
            loading: () => const SizedBox(height: 300, child: Center(child: CircularProgressIndicator(color: TraumColors.lavender))),
            error: (_, __) => const SizedBox.shrink(),
          ),
          const Divider(color: TraumColors.surfaceVariant, height: 1),
          Expanded(
            child: dayApptAsync.when(
              data: (appts) {
                if (appts.isEmpty) {
                  return Center(
                    child: Text(
                      'Keine Termine am ${_selectedDay.day}.${_selectedDay.month}.${_selectedDay.year}',
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
                      onDismissed: (_) => ref.read(planningDaoProvider).deleteAppointment(a.id),
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
              error: (_, __) => const SizedBox.shrink(),
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
        onAdd: (c) => ref.read(planningDaoProvider).insertAppointment(c),
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
            const Text('Termin hinzufügen', style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
                fontWeight: FontWeight.w700, fontSize: 18)),
            const SizedBox(height: 16),
            _buildField('Titel *', _titleCtrl),
            const SizedBox(height: 10),
            _buildField('Ort', _locationCtrl, hint: 'optional'),
            const SizedBox(height: 10),
            _buildField('Beschreibung', _descCtrl, hint: 'optional', maxLines: 2),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _DateTimeTile(
                label: 'Start',
                dateTime: _startTime,
                color: TraumColors.lavender,
                onChanged: (dt) => setState(() { _startTime = dt; if (_endTime.isBefore(_startTime)) _endTime = _startTime.add(const Duration(hours: 1)); }),
              )),
              const SizedBox(width: 12),
              Expanded(child: _DateTimeTile(
                label: 'Ende',
                dateTime: _endTime,
                color: TraumColors.lavender,
                onChanged: (dt) => setState(() => _endTime = dt),
              )),
            ]),
            const SizedBox(height: 20),
            GradientButton(
              label: 'Speichern',
              onPressed: () async {
                if (_titleCtrl.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titel ist ein Pflichtfeld')));
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
    final todosAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchAllTodos()),
    );

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
                const Text('Keine Aufgaben', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Tippe auf + um eine Aufgabe hinzuzufügen',
                    style: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13), textAlign: TextAlign.center),
              ]),
            );
          }
          final open = todos.where((t) => !t.done).toList();
          final done = todos.where((t) => t.done).toList();
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (open.isNotEmpty) ...[
                const SectionHeader(title: 'Offen'),
                const SizedBox(height: 8),
                ...open.map((t) => _TodoTile(todo: t, ref: ref)),
              ],
              if (done.isNotEmpty) ...[
                const SizedBox(height: 16),
                const SectionHeader(title: 'Erledigt'),
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
              ? Text('Fällig: ${todo.dueDate!.day}.${todo.dueDate!.month}.${todo.dueDate!.year}',
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
          const Text('Aufgabe hinzufügen', style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans',
              fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(
            controller: _titleCtrl,
            autofocus: true,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              labelText: 'Titel',
              labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              filled: true, fillColor: TraumColors.surface,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Priorität', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _PriorityChip(label: 'Niedrig', value: 0, selected: _priority == 0, color: TraumColors.onBackgroundSubtle, onTap: () => setState(() => _priority = 0)),
            const SizedBox(width: 8),
            _PriorityChip(label: 'Mittel', value: 1, selected: _priority == 1, color: TraumColors.amberGold, onTap: () => setState(() => _priority = 1)),
            const SizedBox(width: 8),
            _PriorityChip(label: 'Hoch', value: 2, selected: _priority == 2, color: TraumColors.roseRed, onTap: () => setState(() => _priority = 2)),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Fälligkeitsdatum', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            trailing: Text(
              _dueDate != null
                  ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                  : 'Kein Datum',
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
            label: 'Speichern',
            onPressed: () async {
              if (_titleCtrl.text.trim().isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titel ist ein Pflichtfeld')));
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

// ─── Goals tab ────────────────────────────────────────────────────────────────

class _GoalsTab extends ConsumerWidget {
  const _GoalsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchAllGoals()),
    );

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
                Icon(Icons.flag_rounded, size: 64, color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('Noch keine Ziele', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w600)),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: goals.length,
            itemBuilder: (ctx, i) => _GoalCard(goal: goals[i], ref: ref),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.lavender)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddGoal(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddGoalSheet(onAdd: (c) => ref.read(planningDaoProvider).insertGoal(c)),
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
        decoration: BoxDecoration(color: TraumColors.roseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(TraumRadius.card)),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => ref.read(planningDaoProvider).deleteGoal(goal.id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: TraumColors.lavender.withValues(alpha: 0.25)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(goal.title, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700))),
              if (goal.done)
                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: TraumColors.mintGreenDim, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Erreicht', style: TextStyle(color: TraumColors.mintGreen, fontFamily: 'DMSans', fontSize: 11, fontWeight: FontWeight.w600))),
            ]),
            if (goal.description != null) ...[
              const SizedBox(height: 4),
              Text(goal.description!, style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
            ],
            if (goal.targetValue != null) ...[
              const SizedBox(height: 10),
              GradientProgressBar(
                value: progress,
                gradient: const LinearGradient(colors: [TraumColors.lavender, TraumColors.indigoBlue]),
              ),
              const SizedBox(height: 4),
              Text('${goal.currentValue} / ${goal.targetValue} ${goal.unit ?? ''}',
                  style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11)),
            ],
            if (goal.targetDate != null) ...[
              const SizedBox(height: 6),
              Text('Deadline: ${goal.targetDate!.day}.${goal.targetDate!.month}.${goal.targetDate!.year}',
                  style: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 11)),
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
    _titleCtrl.dispose(); _descCtrl.dispose(); _targetCtrl.dispose(); _unitCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Ziel hinzufügen', style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          _field('Titel *', _titleCtrl),
          const SizedBox(height: 10),
          _field('Beschreibung', _descCtrl, maxLines: 2),
          const SizedBox(height: 10),
          Row(children: [
            Expanded(child: _field('Zielwert', _targetCtrl, keyboard: TextInputType.number)),
            const SizedBox(width: 12),
            Expanded(child: _field('Einheit', _unitCtrl, hint: 'kg, km, …')),
          ]),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Deadline', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
            trailing: Text(_deadline != null ? '${_deadline!.day}.${_deadline!.month}.${_deadline!.year}' : 'Kein Datum',
                style: TextStyle(color: _deadline != null ? TraumColors.lavender : TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            onTap: () async {
              final p = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: TraumColors.lavender)), child: child!));
              if (p != null) setState(() => _deadline = p);
            },
          ),
          const SizedBox(height: 20),
          GradientButton(label: 'Speichern', onPressed: () async {
            if (_titleCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Titel ist ein Pflichtfeld'))); return; }
            await widget.onAdd(GoalsCompanion.insert(
              title: _titleCtrl.text.trim(),
              description: Value(_descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim()),
              targetValue: Value(int.tryParse(_targetCtrl.text)),
              unit: Value(_unitCtrl.text.trim().isEmpty ? null : _unitCtrl.text.trim()),
              targetDate: Value(_deadline),
            ));
            if (context.mounted) Navigator.pop(context);
          }),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, {String? hint, int maxLines = 1, TextInputType? keyboard}) {
    return TextField(controller: ctrl, maxLines: maxLines, keyboardType: keyboard,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(labelText: label, hintText: hint,
            labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
            filled: true, fillColor: TraumColors.surface,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)));
  }
}

// ─── Habits tab ───────────────────────────────────────────────────────────────

class _HabitsTab extends ConsumerWidget {
  const _HabitsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final habitsAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchAllHabits()),
    );
    final today = DateTime.now();
    final logsAsync = ref.watch(
      StreamProvider((ref) => ref.watch(planningDaoProvider).watchHabitLogsForDate(today)),
    );

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
                Icon(Icons.loop_rounded, size: 64, color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                const Text('Noch keine Gewohnheiten', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                const Text('Tippe auf + um eine Gewohnheit hinzuzufügen',
                    style: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans', fontSize: 13), textAlign: TextAlign.center),
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
                      HabitLogsCompanion.insert(habitId: habits[i].id, logDate: today),
                    );
                  } else {
                    await ref.read(planningDaoProvider).deleteHabitLog(habits[i].id, today);
                  }
                },
                onDelete: () => ref.read(planningDaoProvider).deleteHabit(habits[i].id),
                ref: ref,
              ),
            ),
            loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.lavender)),
            error: (_, __) => const SizedBox.shrink(),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.lavender)),
        error: (e, _) => Center(child: Text('$e', style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  void _showAddHabit(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card))),
      builder: (ctx) => _AddHabitSheet(onAdd: (c) => ref.read(planningDaoProvider).insertHabit(c)),
    );
  }
}

class _HabitTile extends ConsumerWidget {
  final Habit habit;
  final bool isCheckedToday;
  final void Function(bool) onToggle;
  final VoidCallback onDelete;
  final WidgetRef ref;

  const _HabitTile({required this.habit, required this.isCheckedToday, required this.onToggle, required this.onDelete, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final last7Async = ref.watch(
      FutureProvider.family<List<HabitLog>, int>((ref, id) =>
          ref.watch(planningDaoProvider).getHabitLogsForLast7Days(id))(habit.id),
    );

    return Dismissible(
      key: ValueKey(habit.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(color: TraumColors.roseRed.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(TraumRadius.card)),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(color: isCheckedToday ? TraumColors.mintGreen.withValues(alpha: 0.3) : TraumColors.surfaceVariant),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(children: [
            Row(children: [
              if (habit.emoji != null) Text(habit.emoji!, style: const TextStyle(fontSize: 20)),
              if (habit.emoji != null) const SizedBox(width: 10),
              Expanded(child: Text(habit.name, style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w600))),
              GestureDetector(
                onTap: () => onToggle(!isCheckedToday),
                child: Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: isCheckedToday ? TraumColors.mintGreen : TraumColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(isCheckedToday ? Icons.check_rounded : Icons.add_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ]),
            const SizedBox(height: 10),
            last7Async.when(
              data: (logs) {
                final weekStatus = List.generate(7, (i) {
                  final day = DateTime.now().subtract(Duration(days: 6 - i));
                  return logs.any((l) => isSameDay(l.logDate, day));
                });
                return HabitWeekRow(habitName: '', weekStatus: weekStatus);
              },
              loading: () => const SizedBox(height: 28),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
        ),
      ),
    );
  }

  bool isSameDay(DateTime a, DateTime b) =>
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
  String _emoji = '⭐';
  String _frequency = 'daily';

  static const _emojis = ['⭐', '💪', '🏃', '📚', '💧', '🧘', '🍎', '😴', '✍️', '🎯'];

  @override
  void dispose() { _nameCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 16, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: SingleChildScrollView(
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 40, height: 4,
              decoration: BoxDecoration(color: TraumColors.onBackgroundSubtle, borderRadius: BorderRadius.circular(2)))),
          const SizedBox(height: 16),
          const Text('Gewohnheit hinzufügen', style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          TextField(controller: _nameCtrl, autofocus: true,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(labelText: 'Name', labelStyle: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  filled: true, fillColor: TraumColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(TraumRadius.card), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12))),
          const SizedBox(height: 12),
          const Text('Emoji', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(spacing: 8, runSpacing: 8, children: _emojis.map((e) {
            final selected = e == _emoji;
            return GestureDetector(onTap: () => setState(() => _emoji = e),
                child: Container(padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: selected ? TraumColors.lavenderDim : TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: selected ? TraumColors.lavender : Colors.transparent)),
                    child: Text(e, style: const TextStyle(fontSize: 20))));
          }).toList()),
          const SizedBox(height: 12),
          const Text('Häufigkeit', style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
          const SizedBox(height: 6),
          Row(children: [
            _FreqChip(label: 'Täglich', value: 'daily', selected: _frequency == 'daily', onTap: () => setState(() => _frequency = 'daily')),
            const SizedBox(width: 8),
            _FreqChip(label: 'Wöchentlich', value: 'weekly', selected: _frequency == 'weekly', onTap: () => setState(() => _frequency = 'weekly')),
          ]),
          const SizedBox(height: 20),
          GradientButton(label: 'Speichern', onPressed: () async {
            if (_nameCtrl.text.trim().isEmpty) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Name ist ein Pflichtfeld'))); return; }
            await widget.onAdd(HabitsCompanion.insert(name: _nameCtrl.text.trim(), emoji: Value(_emoji), frequency: Value(_frequency)));
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

  const _FreqChip({required this.label, required this.value, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? TraumColors.lavenderDim : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(TraumRadius.chip),
            border: Border.all(color: selected ? TraumColors.lavender : Colors.transparent),
          ),
          child: Text(label, style: TextStyle(color: selected ? TraumColors.lavender : TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
        ));
  }
}
