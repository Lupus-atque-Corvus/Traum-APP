import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';

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
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text(
          'Wiederkehrend',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: defs.when(
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
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                child: Row(children: [
                  Expanded(
                    child: _RecurringSummaryTile(
                      label: 'Monatliche Einnahmen',
                      amount: totalIncome,
                      currency: currency,
                      color: TraumColors.mintGreen,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _RecurringSummaryTile(
                      label: 'Monatliche Ausgaben',
                      amount: totalExpense,
                      currency: currency,
                      color: TraumColors.roseRed,
                    ),
                  ),
                ]),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, _) =>
                      const Divider(height: 1, color: TraumColors.surfaceVariant),
                  itemBuilder: (_, i) {
                  final d = list[i];
                  final income = d.type == 'income';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      d.description,
                      style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Text(
                      'Jeden ${d.recurringDay ?? d.date.day}. im Monat',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${income ? '+' : '−'}${fmtAmount(d.amount)} $currency',
                          style: TextStyle(
                            color: income
                                ? TraumColors.mintGreen
                                : TraumColors.roseRed,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.edit_rounded, size: 14),
                          color: TraumColors.indigoBlue,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                TraumColors.indigoBlue.withValues(alpha: 0.1),
                            minimumSize: const Size(26, 26),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () =>
                              _showEditSheet(context, ref, d, currency),
                        ),
                        const SizedBox(width: 4),
                        IconButton(
                          icon: const Icon(Icons.delete_rounded, size: 14),
                          color: TraumColors.roseRed,
                          style: IconButton.styleFrom(
                            backgroundColor:
                                TraumColors.roseRed.withValues(alpha: 0.1),
                            minimumSize: const Size(26, 26),
                            padding: EdgeInsets.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: const CircleBorder(),
                          ),
                          onPressed: () =>
                              ref.read(budgetDaoProvider).deleteTransaction(d.id),
                        ),
                      ],
                    ),
                  );
                  },
                ),
              ),
            ],
          );
        },
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.amberGold),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}

class _RecurringSummaryTile extends StatelessWidget {
  final String label;
  final double amount;
  final String currency;
  final Color color;
  const _RecurringSummaryTile({
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 4),
          Text('${fmtAmount(amount)} $currency',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: color,
                  fontFamily: 'DMSans')),
        ]),
      );
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
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
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
            const Text('Wiederkehrend bearbeiten',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _field(_descCtrl, 'Beschreibung'),
            const SizedBox(height: 8),
            _field(_amountCtrl, 'Betrag (${widget.currency})', number: true),
            const SizedBox(height: 12),
            Row(children: [
              const Text('Am Tag des Monats:',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 13)),
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
            ]),
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
                child: const Text('Speichern',
                    style: TextStyle(
                        fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, {bool number = false}) =>
      TextField(
        controller: c,
        keyboardType: number
            ? const TextInputType.numberWithOptions(decimal: true)
            : TextInputType.text,
        style: const TextStyle(
            fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 14),
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
