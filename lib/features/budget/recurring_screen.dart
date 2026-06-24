import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';
import 'widgets/budget_sub_header.dart';

void _showEditSheet(
    BuildContext context, WidgetRef ref, Transaction d, String currency) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _EditRecurringSheet(
      transaction: d,
      currency: currency,
      onSave: (description, amount, day) {
        ref.read(budgetDaoProvider).updateTransaction(
              d.toCompanion(true).copyWith(
                    description: Value(description),
                    amount: Value(amount),
                    recurringDay: Value(day),
                  ),
            );
      },
    ),
  );
}

class RecurringScreen extends ConsumerWidget {
  const RecurringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final defs = ref.watch(recurringTransactionsProvider);
    final currency = ref.watch(currencySymbolProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BudgetSubHeader(title: 'Wiederkehrend'),
            Expanded(
              child: defs.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'Keine wiederkehrenden Buchungen',
                        style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    );
                  }
                  final totalIncome = list
                      .where((d) => d.type == 'income')
                      .fold(0.0, (s, d) => s + d.amount);
                  final totalExpense = list
                      .where((d) => d.type != 'income')
                      .fold(0.0, (s, d) => s + d.amount);
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    child: Column(
                      children: [
                        _SummaryBar(
                          totalIncome: totalIncome,
                          totalExpense: totalExpense,
                          currency: currency,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            color: TraumColors.surface,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.07),
                            ),
                          ),
                          child: Column(
                            children: [
                              for (int i = 0; i < list.length; i++) ...[
                                if (i > 0)
                                  Divider(
                                    height: 1,
                                    thickness: 1,
                                    color: Colors.white.withValues(alpha: 0.05),
                                    indent: 0,
                                    endIndent: 0,
                                  ),
                                _RecurringRow(
                                  d: list[i],
                                  currency: currency,
                                  onEdit: () => _showEditSheet(
                                      context, ref, list[i], currency),
                                  onDelete: () => ref
                                      .read(budgetDaoProvider)
                                      .deleteTransaction(list[i].id),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.amberGold),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryBar extends StatelessWidget {
  final double totalIncome;
  final double totalExpense;
  final String currency;

  const _SummaryBar({
    required this.totalIncome,
    required this.totalExpense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 10),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.07),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monatliche Einnahmen',
                  style: TextStyle(
                    fontSize: 8,
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '+${fmtAmount(totalIncome)} $currency',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.mintGreen,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: 1,
            height: 28,
            color: Colors.white.withValues(alpha: 0.08),
            margin: const EdgeInsets.symmetric(horizontal: 12),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Monatliche Ausgaben',
                  style: TextStyle(
                    fontSize: 8,
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '−${fmtAmount(totalExpense)} $currency',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.roseRed,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecurringRow extends StatelessWidget {
  final Transaction d;
  final String currency;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _RecurringRow({
    required this.d,
    required this.currency,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final income = d.type == 'income';
    final accentColor = income ? TraumColors.mintGreen : TraumColors.roseRed;
    final iconData = income ? Icons.south_west_rounded : Icons.repeat_rounded;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 11),
      child: Row(
        children: [
          // Leading icon container 34×34 radius 9 accentColor@0.15
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              iconData,
              size: 14,
              color: accentColor,
            ),
          ),
          const SizedBox(width: 10),
          // Name 11/w600 + interval 9/muted
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  d.description,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Jeden ${d.recurringDay ?? d.date.day}. im Monat',
                  style: const TextStyle(
                    fontSize: 9,
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
          // Amount 11/w700 margin-right 4
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(
              '${income ? '+' : '−'}${fmtAmount(d.amount)} $currency',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: accentColor,
                fontFamily: 'DMSans',
              ),
            ),
          ),
          const SizedBox(width: 6),
          // Edit: 26×26 radius 13 bg indigo@0.1 pencil 11 indigo
          GestureDetector(
            onTap: onEdit,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: TraumColors.indigoBlue.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.edit_rounded,
                size: 11,
                color: TraumColors.indigoBlue,
              ),
            ),
          ),
          const SizedBox(width: 4),
          // Delete: 26×26 bg rose@0.1 trash 12 rose
          GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: TraumColors.roseRed.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.delete_rounded,
                size: 12,
                color: TraumColors.roseRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditRecurringSheet extends StatefulWidget {
  final Transaction transaction;
  final String currency;
  final void Function(String description, double amount, int day) onSave;

  const _EditRecurringSheet({
    required this.transaction,
    required this.currency,
    required this.onSave,
  });

  @override
  State<_EditRecurringSheet> createState() => _EditRecurringSheetState();
}

class _EditRecurringSheetState extends State<_EditRecurringSheet> {
  late final TextEditingController _descCtrl;
  late final TextEditingController _amountCtrl;
  late int _day;

  @override
  void initState() {
    super.initState();
    _descCtrl = TextEditingController(text: widget.transaction.description);
    _amountCtrl = TextEditingController(
        text: widget.transaction.amount.toStringAsFixed(2).replaceAll('.', ','));
    _day = (widget.transaction.recurringDay ?? widget.transaction.date.day)
        .clamp(1, 28);
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final desc = _descCtrl.text.trim();
    final amount =
        double.tryParse(_amountCtrl.text.trim().replaceAll(',', '.')) ?? 0;
    if (desc.isEmpty || amount <= 0) return;
    widget.onSave(desc, amount, _day);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        decoration: const BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Text(
              'Wiederkehrend bearbeiten',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                color: TraumColors.onBackground,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _field(_descCtrl, 'Beschreibung'),
            const SizedBox(height: 8),
            _field(_amountCtrl, 'Betrag (${widget.currency})', number: true),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text(
                  'Am Tag des Monats:',
                  style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: _day,
                  dropdownColor: TraumColors.surfaceVariant,
                  style: const TextStyle(
                      fontFamily: 'DMSans', color: TraumColors.onBackground),
                  items: [
                    for (var d = 1; d <= 28; d++)
                      DropdownMenuItem(value: d, child: Text('$d.')),
                  ],
                  onChanged: (v) => setState(() => _day = v ?? 1),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.indigoBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _save,
                child: const Text(
                  'Speichern',
                  style: TextStyle(
                      fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label,
          {bool number = false}) =>
      TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackground,
            fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 13),
          filled: true,
          fillColor: TraumColors.surfaceVariant,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}
