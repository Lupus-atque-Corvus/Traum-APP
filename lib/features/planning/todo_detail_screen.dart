import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class TodoDetailScreen extends ConsumerStatefulWidget {
  /// Pass null to create a new todo.
  final Todo? todo;

  const TodoDetailScreen({super.key, this.todo});

  @override
  ConsumerState<TodoDetailScreen> createState() => _TodoDetailScreenState();
}

class _TodoDetailScreenState extends ConsumerState<TodoDetailScreen> {
  late final TextEditingController _titleCtrl;
  late final TextEditingController _noteCtrl;
  late final TextEditingController _listCtrl;
  late int _priority;
  DateTime? _dueDate;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final t = widget.todo;
    _titleCtrl = TextEditingController(text: t?.title ?? '');
    _noteCtrl = TextEditingController(text: t?.note ?? '');
    _listCtrl = TextEditingController(text: t?.listName ?? '');
    _priority = t?.priority ?? 0;
    _dueDate = t?.dueDate;
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _noteCtrl.dispose();
    _listCtrl.dispose();
    super.dispose();
  }

  Future<void> _save(BuildContext context) async {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;
    setState(() => _saving = true);
    try {
      final dao = ref.read(planningDaoProvider);
      final listVal = _listCtrl.text.trim();
      final companion = TodosCompanion(
        id: widget.todo != null ? Value(widget.todo!.id) : const Value.absent(),
        title: Value(title),
        note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
        priority: Value(_priority),
        dueDate: Value(_dueDate),
        listName: Value(listVal.isEmpty ? null : listVal),
        done: Value(widget.todo?.done ?? false),
      );
      if (widget.todo == null) {
        await dao.insertTodo(companion);
      } else {
        await dao.updateTodo(companion);
      }
      if (context.mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _pickDueDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: TraumColors.cyanBlue,
            surface: TraumColors.surfaceElevated,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isNew = widget.todo == null;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(
          isNew ? l10n.newTodo : l10n.editTodo,
          style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          if (!isNew)
            IconButton(
              icon: const Icon(Icons.delete_outline_rounded,
                  color: TraumColors.roseRed),
              onPressed: () => _confirmDelete(context),
            ),
          TextButton(
            onPressed: _saving ? null : () => _save(context),
            child: Text(l10n.save,
                style: const TextStyle(
                    color: TraumColors.cyanBlue,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Title
          _FieldLabel(l10n.title),
          const SizedBox(height: 6),
          _TextField(
            controller: _titleCtrl,
            hint: l10n.todoTitleHint,
            autofocus: isNew,
          ),
          const SizedBox(height: 16),

          // Note
          _FieldLabel(l10n.note),
          const SizedBox(height: 6),
          _TextField(
            controller: _noteCtrl,
            hint: l10n.todoNoteHint,
            maxLines: 4,
          ),
          const SizedBox(height: 16),

          // List name
          _FieldLabel(l10n.todoList),
          const SizedBox(height: 6),
          _TextField(
            controller: _listCtrl,
            hint: l10n.todoListHint,
          ),
          const SizedBox(height: 16),

          // Priority
          _FieldLabel(l10n.fieldPriority),
          const SizedBox(height: 8),
          Row(
            children: [
              _PriorityChip(
                label: l10n.priorityLow,
                value: 0,
                selected: _priority == 0,
                color: TraumColors.mintGreen,
                onTap: () => setState(() => _priority = 0),
              ),
              const SizedBox(width: 8),
              _PriorityChip(
                label: l10n.priorityMedium,
                value: 1,
                selected: _priority == 1,
                color: TraumColors.amberGold,
                onTap: () => setState(() => _priority = 1),
              ),
              const SizedBox(width: 8),
              _PriorityChip(
                label: l10n.priorityHigh,
                value: 2,
                selected: _priority == 2,
                color: TraumColors.roseRed,
                onTap: () => setState(() => _priority = 2),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Due date
          _FieldLabel(l10n.dueDate),
          const SizedBox(height: 6),
          InkWell(
            onTap: () => _pickDueDate(context),
            borderRadius: BorderRadius.circular(TraumRadius.input),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: TraumColors.surface,
                borderRadius: BorderRadius.circular(TraumRadius.input),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.event_rounded,
                    color: _dueDate != null
                        ? TraumColors.cyanBlue
                        : TraumColors.onBackgroundSubtle,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _dueDate != null
                        ? '${_dueDate!.day}.${_dueDate!.month}.${_dueDate!.year}'
                        : l10n.noDueDate,
                    style: TextStyle(
                        color: _dueDate != null
                            ? TraumColors.onBackground
                            : TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans'),
                  ),
                  const Spacer(),
                  if (_dueDate != null)
                    GestureDetector(
                      onTap: () => setState(() => _dueDate = null),
                      child: const Icon(Icons.close_rounded,
                          color: TraumColors.onBackgroundMuted, size: 18),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Sub-items (only for existing todos)
          if (!isNew) ...[
            _FieldLabel(l10n.todoSubItems),
            const SizedBox(height: 8),
            _SubItemsList(todoId: widget.todo!.id),
          ],
        ],
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.confirmDelete,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: Text(l10n.confirmDeleteTodo,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: TraumColors.roseRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(planningDaoProvider).deleteTodo(widget.todo!.id);
      if (context.mounted) Navigator.pop(context, true);
    }
  }
}

// ── Sub-items widget ──────────────────────────────────────────────────────────

class _SubItemsList extends ConsumerStatefulWidget {
  final int todoId;
  const _SubItemsList({required this.todoId});

  @override
  ConsumerState<_SubItemsList> createState() => _SubItemsListState();
}

class _SubItemsListState extends ConsumerState<_SubItemsList> {
  final _addCtrl = TextEditingController();

  @override
  void dispose() {
    _addCtrl.dispose();
    super.dispose();
  }

  Future<void> _addItem() async {
    final title = _addCtrl.text.trim();
    if (title.isEmpty) return;
    await ref.read(planningDaoProvider).insertSubItem(
          TodoSubItemsCompanion.insert(
            todoId: widget.todoId,
            title: title,
          ),
        );
    _addCtrl.clear();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final itemsAsync =
        ref.watch(todoSubItemsProvider(widget.todoId));

    return Column(
      children: [
        itemsAsync.when(
          data: (items) => items.isEmpty
              ? const SizedBox.shrink()
              : Column(
                  children: items.map((item) => _SubItemTile(item: item)).toList(),
                ),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _addCtrl,
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
                decoration: InputDecoration(
                  hintText: l10n.todoAddSubItem,
                  hintStyle: const TextStyle(
                      color: TraumColors.onBackgroundSubtle,
                      fontFamily: 'DMSans'),
                  filled: true,
                  fillColor: TraumColors.surface,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.input),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
                onSubmitted: (_) => _addItem(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: _addItem,
              icon: const Icon(Icons.add_circle_rounded,
                  color: TraumColors.cyanBlue),
            ),
          ],
        ),
      ],
    );
  }
}

class _SubItemTile extends ConsumerWidget {
  final TodoSubItem item;
  const _SubItemTile({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Checkbox(
        value: item.done,
        activeColor: TraumColors.cyanBlue,
        checkColor: Colors.white,
        onChanged: (v) => ref.read(planningDaoProvider).updateSubItem(
              TodoSubItemsCompanion(
                id: Value(item.id),
                done: Value(v ?? false),
              ),
            ),
      ),
      title: Text(
        item.title,
        style: TextStyle(
          color: item.done
              ? TraumColors.onBackgroundMuted
              : TraumColors.onBackground,
          fontFamily: 'DMSans',
          decoration: item.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.close_rounded,
            color: TraumColors.onBackgroundSubtle, size: 18),
        onPressed: () =>
            ref.read(planningDaoProvider).deleteSubItem(item.id),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text,
        style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 13));
  }
}

class _TextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final bool autofocus;

  const _TextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      style: const TextStyle(
          color: TraumColors.onBackground, fontFamily: 'DMSans'),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
        filled: true,
        fillColor: TraumColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TraumRadius.input),
          borderSide: BorderSide.none,
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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

  const _PriorityChip({
    required this.label,
    required this.value,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color.withAlpha(40) : TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.button),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? color : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 13)),
      ),
    );
  }
}
