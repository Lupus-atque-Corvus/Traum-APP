import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'budget_scale.dart';
import 'widgets/budget_sub_header.dart';

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final goalsAsync = ref.watch(allSavingsGoalsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetSubHeader(title: AppLocalizations.of(context)!.savingsGoals),
            Expanded(
              child: goalsAsync.when(
                data: (goals) {
                  if (goals.isEmpty) {
                    return Center(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.savings_rounded,
                            size: 64,
                            color: TraumColors.onBackgroundSubtle
                                .withValues(alpha: 0.5)),
                        const SizedBox(height: 16),
                        Text(AppLocalizations.of(context)!.noSavingsGoals,
                            style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                                fontSize: 16)),
                        const SizedBox(height: 8),
                        Text(
                            AppLocalizations.of(context)!
                                .tapToCreateSavingsGoal,
                            style: const TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontFamily: 'DMSans',
                                fontSize: 13),
                            textAlign: TextAlign.center),
                      ]),
                    );
                  }
                  return ListView.builder(
                    padding: EdgeInsets.fromLTRB(bs(12), bs(4), bs(12), bs(80)),
                    itemCount: goals.length,
                    itemBuilder: (ctx, i) => _SavingsGoalCard(
                      goal: goals[i],
                      currency: currency,
                      onDelete: () =>
                          ref.read(budgetDaoProvider).deleteSavingsGoal(goals[i].id),
                      onAddAmount: (amount) => _addToGoal(ref, goals[i], amount),
                    ),
                  );
                },
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: TraumColors.mintGreen)),
                error: (e, _) => Center(
                    child: Text('${AppLocalizations.of(context)!.error}: $e',
                        style:
                            const TextStyle(color: TraumColors.roseRed))),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.mintGreen,
        elevation: 0,
        onPressed: () => _showAddGoalSheet(context, ref, currency),
        child: Icon(Icons.add_rounded,
            size: bs(20), color: TraumColors.background),
      ),
    );
  }

  Future<void> _addToGoal(WidgetRef ref, SavingsGoal goal, double amount) async {
    final newAmount =
        (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
    await ref.read(budgetDaoProvider).updateSavingsGoal(
          SavingsGoalsCompanion(
            id: Value(goal.id),
            name: Value(goal.name),
            targetAmount: Value(goal.targetAmount),
            currentAmount: Value(newAmount),
            isCompleted: Value(newAmount >= goal.targetAmount),
          ),
        );
  }

  void _showAddGoalSheet(
      BuildContext context, WidgetRef ref, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddGoalSheet(
        currency: currency,
        onAdd: (c) => ref.read(budgetDaoProvider).insertSavingsGoal(c),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Goal card
// ---------------------------------------------------------------------------

class _SavingsGoalCard extends StatelessWidget {
  final SavingsGoal goal;
  final String currency;
  final VoidCallback onDelete;
  final Future<void> Function(double) onAddAmount;

  const _SavingsGoalCard({
    required this.goal,
    required this.currency,
    required this.onDelete,
    required this.onAddAmount,
  });

  // Default accent for savings goals — no per-goal color in data model.
  static const _accent = TraumColors.mintGreen;

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final percent = (progress * 100).round();

    final borderColor = goal.isCompleted
        ? TraumColors.mintGreen.withValues(alpha: 0.3)
        : Colors.white.withValues(alpha: 0.07);

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: bs(20)),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(bs(15)),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: EdgeInsets.only(bottom: bs(9)),
        padding: EdgeInsets.all(bs(13)),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(bs(15)),
          border: Border.all(color: borderColor, width: bs(1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header row ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Icon container 40×40 / radius 11 / accent@15%
                Container(
                  width: bs(40),
                  height: bs(40),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(bs(11)),
                  ),
                  child: Icon(Icons.savings_rounded,
                      size: bs(18), color: _accent),
                ),
                SizedBox(width: bs(10)),
                // Title + "Ziel: …" subtitle
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(goal.name,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: TraumColors.onBackground)),
                      SizedBox(height: bs(2)),
                      Text(
                          '${AppLocalizations.of(context)!.goal}: '
                          '${goal.targetAmount.toStringAsFixed(2)} $currency'
                          '${goal.targetDate != null ? ' · bis ${goal.targetDate!.month}/${goal.targetDate!.year}' : ''}',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              color: TraumColors.onBackgroundMuted)),
                    ],
                  ),
                ),
                SizedBox(width: bs(8)),
                // Percent display — right aligned
                Text('$percent%',
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: _accent)),
              ],
            ),
            SizedBox(height: bs(9)),
            // ── Progress bar ─────────────────────────────────────────────
            GradientProgressBar(
              value: progress,
              height: bs(6),
              gradient: const LinearGradient(
                  colors: [TraumColors.mintGreen, TraumColors.cyanBlue]),
            ),
            SizedBox(height: bs(6)),
            // ── Footer ───────────────────────────────────────────────────
            if (goal.isCompleted)
              // Completed badge — no deposit row
              Row(children: [
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: bs(6), vertical: bs(2)),
                  decoration: BoxDecoration(
                    color: TraumColors.mintGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(bs(5)),
                  ),
                  child: Text(
                    AppLocalizations.of(context)!.reached.toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 9,
                        color: TraumColors.mintGreen),
                  ),
                ),
              ])
            else
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // "X € von Y €"
                  Text(
                      '${goal.currentAmount.toStringAsFixed(2)} $currency '
                      'von '
                      '${goal.targetAmount.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 10,
                          color: TraumColors.onBackgroundMuted)),
                  // "+ Einzahlen" pill
                  GestureDetector(
                    onTap: () => _showDepositDialog(context),
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: bs(10), vertical: bs(5)),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(bs(8)),
                      ),
                      child: Text(
                          '+ ${AppLocalizations.of(context)!.deposit}',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                              color: _accent)),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  void _showDepositDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(AppLocalizations.of(ctx)!.depositAmount,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(
              color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle:
                const TextStyle(color: TraumColors.onBackgroundSubtle),
            suffixText: currency,
            filled: true,
            fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () async {
              final v =
                  double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) {
                Navigator.pop(ctx);
                await onAddAmount(v);
              }
            },
            child: Text(AppLocalizations.of(ctx)!.deposit,
                style: const TextStyle(
                    color: TraumColors.mintGreen,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Add-goal bottom sheet
// ---------------------------------------------------------------------------

class _AddGoalSheet extends StatefulWidget {
  final String currency;
  final Future<void> Function(SavingsGoalsCompanion) onAdd;

  const _AddGoalSheet({required this.currency, required this.onAdd});

  @override
  State<_AddGoalSheet> createState() => _AddGoalSheetState();
}

class _AddGoalSheetState extends State<_AddGoalSheet> {
  final _nameCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _currentCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  DateTime? _targetDate;
  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _targetCtrl.dispose();
    _currentCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.createSavingsGoal,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _buildTextField(
                AppLocalizations.of(context)!.fieldName, _nameCtrl,
                hint: AppLocalizations.of(context)!.savingsGoalNameHint),
            const SizedBox(height: 12),
            _buildTextField(
                '${AppLocalizations.of(context)!.targetAmountLabel} (${widget.currency})',
                _targetCtrl,
                hint: '1000.00',
                numeric: true),
            const SizedBox(height: 12),
            _buildTextField(
                '${AppLocalizations.of(context)!.alreadySaved} (${widget.currency})',
                _currentCtrl,
                hint: '0.00',
                numeric: true),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(AppLocalizations.of(context)!.targetDateOptional,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
              trailing: Text(
                _targetDate != null
                    ? '${_targetDate!.day}.${_targetDate!.month}.${_targetDate!.year}'
                    : AppLocalizations.of(context)!.noDate,
                style: const TextStyle(
                    color: TraumColors.mintGreen,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600),
              ),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate:
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme: const ColorScheme.dark(
                            primary: TraumColors.mintGreen)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            _buildTextField(
                AppLocalizations.of(context)!.fieldNoteOptional, _noteCtrl,
                hint: AppLocalizations.of(context)!.whatSavingFor),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving
                  ? AppLocalizations.of(context)!.saving
                  : AppLocalizations.of(context)!.createSavingsGoal,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl,
      {String? hint, bool numeric = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: numeric
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
          style: const TextStyle(
              color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans'),
            filled: true,
            fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content:
              Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    final target =
        double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!
              .pleaseEnterValidTargetAmount)));
      return;
    }
    final current =
        double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    await widget.onAdd(SavingsGoalsCompanion.insert(
      name: _nameCtrl.text.trim(),
      targetAmount: target,
      currentAmount: Value(current),
      targetDate: Value(_targetDate),
      note: Value(_noteCtrl.text.trim().isEmpty
          ? null
          : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}
