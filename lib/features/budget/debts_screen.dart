import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final debts = ref.watch(allDebtsStreamProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text('Schulden', style: TextStyle(
            color: TraumColors.onBackground, fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: debts.when(
        data: (list) => list.isEmpty
            ? const Center(child: Text('Keine Schulden erfasst',
                style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                itemCount: list.length,
                itemBuilder: (_, i) => _DebtCard(
                  debt: list[i], currency: currency,
                  onPay: (amt) {
                    final rem = (list[i].remainingAmount - amt).clamp(0.0, list[i].originalAmount);
                    ref.read(budgetDaoProvider).updateDebt(DebtsCompanion(
                      id: Value(list[i].id),
                      creditor: Value(list[i].creditor),
                      originalAmount: Value(list[i].originalAmount),
                      remainingAmount: Value(rem),
                      isPaidOff: Value(rem <= 0),
                    ));
                  },
                  onDelete: () => ref.read(budgetDaoProvider).deleteDebt(list[i].id),
                ),
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.roseRed)),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final creditor = TextEditingController();
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          decoration: const BoxDecoration(color: TraumColors.surface,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Schuld hinzufügen', style: TextStyle(fontFamily: 'DMSans',
                fontWeight: FontWeight.w700, color: TraumColors.onBackground, fontSize: 18)),
            const SizedBox(height: 16),
            _debtField(creditor, 'Gläubiger *', 'z.B. Bank'),
            const SizedBox(height: 8),
            _debtField(amount, 'Betrag *', '0,00', number: true),
            const SizedBox(height: 16),
            SizedBox(width: double.infinity, child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: TraumColors.roseRed,
                  foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TraumRadius.button))),
              onPressed: () {
                final c = creditor.text.trim();
                final a = double.tryParse(amount.text.trim().replaceAll(',', '.')) ?? 0;
                if (c.isEmpty || a <= 0) return;
                ref.read(budgetDaoProvider).insertDebt(DebtsCompanion.insert(
                    creditor: c, originalAmount: a, remainingAmount: a));
                Navigator.of(ctx).pop();
              },
              child: const Text('Speichern', style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
            )),
          ]),
        ),
      ),
    );
  }

  static Widget _debtField(TextEditingController c, String label, String hint, {bool number = false}) =>
      TextField(controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground, fontSize: 14),
        decoration: InputDecoration(labelText: label, hintText: hint, filled: true,
          fillColor: TraumColors.surfaceVariant,
          labelStyle: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted, fontSize: 13),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10)));
}

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String currency;
  final void Function(double) onPay;
  final VoidCallback onDelete;
  const _DebtCard({required this.debt, required this.currency, required this.onPay, required this.onDelete});
  @override
  Widget build(BuildContext context) {
    final ratio = debt.originalAmount > 0
        ? (1 - debt.remainingAmount / debt.originalAmount).clamp(0.0, 1.0) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: TraumColors.surface, borderRadius: BorderRadius.circular(TraumRadius.card)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(debt.creditor, style: const TextStyle(color: TraumColors.onBackground,
              fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 15))),
          IconButton(icon: const Icon(Icons.delete_outline, color: TraumColors.onBackgroundMuted),
              onPressed: onDelete),
        ]),
        Text('${fmtAmount(debt.remainingAmount)} $currency von ${fmtAmount(debt.originalAmount)} $currency offen',
            style: const TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
        const SizedBox(height: 8),
        ClipRRect(borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(value: ratio, minHeight: 6,
              backgroundColor: TraumColors.surfaceVariant,
              valueColor: const AlwaysStoppedAnimation(TraumColors.mintGreen))),
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerRight, child: TextButton(
          onPressed: debt.isPaidOff ? null : () => _payDialog(context),
          child: Text(debt.isPaidOff ? 'Bezahlt' : 'Rate zahlen',
              style: TextStyle(fontFamily: 'DMSans',
                  color: debt.isPaidOff ? TraumColors.mintGreen : TraumColors.amberGold)),
        )),
      ]),
    );
  }
  void _payDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: TraumColors.surface,
      title: const Text('Rate zahlen', style: TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground)),
      content: TextField(controller: ctrl, keyboardType: TextInputType.number, autofocus: true,
        style: const TextStyle(fontFamily: 'DMSans', color: TraumColors.onBackground),
        decoration: const InputDecoration(hintText: '0,00')),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Abbrechen')),
        TextButton(onPressed: () {
          final a = double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ?? 0;
          if (a > 0) onPay(a);
          Navigator.pop(ctx);
        }, child: const Text('OK')),
      ],
    ));
  }
}
