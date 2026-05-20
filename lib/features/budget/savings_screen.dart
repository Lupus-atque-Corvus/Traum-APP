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

class SavingsScreen extends ConsumerWidget {
  const SavingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final goalsAsync = ref.watch(allSavingsGoalsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.savingsGoals,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.mintGreen,
        onPressed: () => _showAddGoalSheet(context, ref, currency),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: goalsAsync.when(
        data: (goals) {
          if (goals.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.savings_rounded,
                    size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noSavingsGoals,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tapToCreateSavingsGoal,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: goals.length,
            itemBuilder: (ctx, i) => _SavingsGoalCard(
              goal: goals[i],
              currency: currency,
              onDelete: () => ref.read(budgetDaoProvider).deleteSavingsGoal(goals[i].id),
              onAddAmount: (amount) => _addToGoal(ref, goals[i], amount),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.mintGreen)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  Future<void> _addToGoal(WidgetRef ref, SavingsGoal goal, double amount) async {
    final newAmount = (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
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

  void _showAddGoalSheet(BuildContext context, WidgetRef ref, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddGoalSheet(
        currency: currency,
        onAdd: (c) => ref.read(budgetDaoProvider).insertSavingsGoal(c),
      ),
    );
  }
}

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

  @override
  Widget build(BuildContext context) {
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remaining = goal.targetAmount - goal.currentAmount;

    return Dismissible(
      key: ValueKey(goal.id),
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
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: goal.isCompleted
                ? TraumColors.mintGreen.withValues(alpha: 0.4)
                : TraumColors.mintGreen.withValues(alpha: 0.15),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(goal.name,
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16)),
                ),
                if (goal.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: TraumColors.mintGreenDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(AppLocalizations.of(context)!.reached,
                        style: const TextStyle(
                            color: TraumColors.mintGreen,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 11)),
                  ),
              ]),
              const SizedBox(height: 12),
              GradientProgressBar(
                value: progress,
                gradient: const LinearGradient(
                    colors: [TraumColors.mintGreen, TraumColors.cyanBlue]),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${goal.currentAmount.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                          color: TraumColors.mintGreen,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 14)),
                  Text('${AppLocalizations.of(context)!.goal}: ${goal.targetAmount.toStringAsFixed(2)} $currency',
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 12)),
                ],
              ),
              if (!goal.isCompleted) ...[
                const SizedBox(height: 4),
                Text(AppLocalizations.of(context)!.remainingAmount(remaining.toStringAsFixed(2), currency),
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 11)),
              ],
              if (goal.targetDate != null) ...[
                const SizedBox(height: 4),
                Text(
                    AppLocalizations.of(context)!.targetDate('${goal.targetDate!.day}.${goal.targetDate!.month}.${goal.targetDate!.year}'),
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 11)),
              ],
              if (!goal.isCompleted) ...[
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showDepositDialog(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TraumColors.mintGreen,
                        side: const BorderSide(color: TraumColors.mintGreen),
                      ),
                      child: Text(AppLocalizations.of(context)!.deposit,
                          style: const TextStyle(fontFamily: 'DMSans')),
                    ),
                  ),
                ]),
              ],
            ],
          ),
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
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: TextField(
          controller: ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: '0.00',
            hintStyle: const TextStyle(color: TraumColors.onBackgroundSubtle),
            suffixText: currency,
            filled: true,
            fillColor: TraumColors.surface,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.card),
                borderSide: BorderSide.none),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppLocalizations.of(ctx)!.cancel,
                style: const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () async {
              final v = double.tryParse(ctrl.text.replaceAll(',', '.'));
              if (v != null && v > 0) {
                Navigator.pop(ctx);
                await onAddAmount(v);
              }
            },
            child: Text(AppLocalizations.of(ctx)!.deposit,
                style: const TextStyle(color: TraumColors.mintGreen, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

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
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                  width: 40, height: 4,
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
            _buildTextField(AppLocalizations.of(context)!.fieldName, _nameCtrl, hint: AppLocalizations.of(context)!.savingsGoalNameHint),
            const SizedBox(height: 12),
            _buildTextField('${AppLocalizations.of(context)!.targetAmountLabel} (${widget.currency})', _targetCtrl,
                hint: '1000.00', numeric: true),
            const SizedBox(height: 12),
            _buildTextField('${AppLocalizations.of(context)!.alreadySaved} (${widget.currency})', _currentCtrl,
                hint: '0.00', numeric: true),
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
                  initialDate: DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2100),
                  builder: (ctx, child) => Theme(
                    data: ThemeData.dark().copyWith(
                        colorScheme:
                            const ColorScheme.dark(primary: TraumColors.mintGreen)),
                    child: child!,
                  ),
                );
                if (picked != null) setState(() => _targetDate = picked);
              },
            ),
            _buildTextField(AppLocalizations.of(context)!.fieldNoteOptional, _noteCtrl, hint: AppLocalizations.of(context)!.whatSavingFor),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.createSavingsGoal,
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
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
                color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
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
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    final target = double.tryParse(_targetCtrl.text.replaceAll(',', '.'));
    if (target == null || target <= 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.pleaseEnterValidTargetAmount)));
      return;
    }
    final current = double.tryParse(_currentCtrl.text.replaceAll(',', '.')) ?? 0;
    setState(() => _saving = true);
    await widget.onAdd(SavingsGoalsCompanion.insert(
      name: _nameCtrl.text.trim(),
      targetAmount: target,
      currentAmount: Value(current),
      targetDate: Value(_targetDate),
      note: Value(_noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim()),
    ));
    if (mounted) Navigator.pop(context);
  }
}
