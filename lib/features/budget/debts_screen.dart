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

class DebtsScreen extends ConsumerWidget {
  const DebtsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final debts = ref.watch(allDebtsStreamProvider);
    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.roseRed,
        onPressed: () => _showAddSheet(context, ref),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 20),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BudgetSubHeader(title: 'Schulden'),
            Expanded(
              child: debts.when(
                data: (list) {
                  if (list.isEmpty) {
                    return const Center(
                      child: Text(
                        'Keine Schulden erfasst',
                        style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    );
                  }
                  final totalDebt = list
                      .where((d) => !d.isPaidOff)
                      .fold(0.0, (s, d) => s + d.remainingAmount);
                  final openCount = list.where((d) => !d.isPaidOff).length;
                  final paidCount = list.where((d) => d.isPaidOff).length;
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 80),
                    itemCount: list.length + 1,
                    itemBuilder: (_, i) {
                      if (i == 0) {
                        return _DebtsHero(
                          totalDebt: totalDebt,
                          openCount: openCount,
                          paidCount: paidCount,
                          currency: currency,
                        );
                      }
                      final debt = list[i - 1];
                      return _DebtCard(
                        debt: debt,
                        currency: currency,
                        onPay: (amt) {
                          final rem = (debt.remainingAmount - amt)
                              .clamp(0.0, debt.originalAmount);
                          ref.read(budgetDaoProvider).updateDebt(DebtsCompanion(
                            id: Value(debt.id),
                            creditor: Value(debt.creditor),
                            originalAmount: Value(debt.originalAmount),
                            remainingAmount: Value(rem),
                            isPaidOff: Value(rem <= 0),
                          ));
                        },
                        onDelete: () =>
                            ref.read(budgetDaoProvider).deleteDebt(debt.id),
                      );
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.roseRed),
                ),
                error: (_, _) => const SizedBox.shrink(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSheet(BuildContext context, WidgetRef ref) {
    final creditor = TextEditingController();
    final amount = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
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
              const Text(
                'Schuld hinzufügen',
                style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 16),
              _debtField(creditor, 'Gläubiger *', 'z.B. Bank'),
              const SizedBox(height: 8),
              _debtField(amount, 'Betrag *', '0,00', number: true),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.roseRed,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50),
                    ),
                  ),
                  onPressed: () {
                    final c = creditor.text.trim();
                    final a = double.tryParse(
                            amount.text.trim().replaceAll(',', '.')) ??
                        0;
                    if (c.isEmpty || a <= 0) return;
                    ref.read(budgetDaoProvider).insertDebt(
                          DebtsCompanion.insert(
                            creditor: c,
                            originalAmount: a,
                            remainingAmount: a,
                          ),
                        );
                    Navigator.of(ctx).pop();
                  },
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
      ),
    );
  }

  static Widget _debtField(
    TextEditingController c,
    String label,
    String hint, {
    bool number = false,
  }) =>
      TextField(
        controller: c,
        keyboardType:
            number ? TextInputType.number : TextInputType.text,
        style: const TextStyle(
          fontFamily: 'DMSans',
          color: TraumColors.onBackground,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          filled: true,
          fillColor: TraumColors.surfaceVariant,
          labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            color: TraumColors.onBackgroundMuted,
            fontSize: 13,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      );
}

// ---------------------------------------------------------------------------
// Hero summary
// ---------------------------------------------------------------------------

class _DebtsHero extends StatelessWidget {
  final double totalDebt;
  final int openCount;
  final int paidCount;
  final String currency;

  const _DebtsHero({
    required this.totalDebt,
    required this.openCount,
    required this.paidCount,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(
            color: TraumColors.roseRed.withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Offene Schulden gesamt',
              style: TextStyle(
                fontSize: 9,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '${fmtAmount(totalDebt)} $currency',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: TraumColors.roseRed,
                fontFamily: 'DMSans',
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '$openCount offen · $paidCount beglichen',
              style: const TextStyle(
                fontSize: 9,
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              ),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// Debt card
// ---------------------------------------------------------------------------

class _DebtCard extends StatelessWidget {
  final Debt debt;
  final String currency;
  final void Function(double) onPay;
  final VoidCallback onDelete;

  const _DebtCard({
    required this.debt,
    required this.currency,
    required this.onPay,
    required this.onDelete,
  });

  // Default icon: open debts use account_balance_rounded (bank/landmark),
  // paid-off debts show a checkmark so this icon is only for the container.
  static const IconData _defaultIcon = Icons.account_balance_rounded;

  // Accent color for this card — roseRed for open, mintGreen for paid.
  Color get _accentColor =>
      debt.isPaidOff ? TraumColors.mintGreen : TraumColors.roseRed;

  @override
  Widget build(BuildContext context) {
    final ratio = debt.originalAmount > 0
        ? (1 - debt.remainingAmount / debt.originalAmount).clamp(0.0, 1.0)
        : 0.0;
    final paidAmount = debt.originalAmount - debt.remainingAmount;
    final paidPct = (ratio * 100).round();

    return Dismissible(
      key: ValueKey(debt.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(15),
        ),
        child: const Icon(Icons.delete_outline,
            color: TraumColors.roseRed, size: 22),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 9),
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: debt.isPaidOff
                ? TraumColors.mintGreen.withValues(alpha: 0.2)
                : Colors.white.withValues(alpha: 0.07),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Card header ──────────────────────────────────────────────
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Icon container 38×38, radius 10
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    _defaultIcon,
                    size: 16,
                    color: _accentColor,
                  ),
                ),
                const SizedBox(width: 10),
                // Name + original amount
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        debt.creditor,
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: TraumColors.onBackground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Ursprünglich: ${fmtAmount(debt.originalAmount)} $currency',
                        style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 9,
                          color: TraumColors.onBackgroundMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Right side: remaining amount OR paid badge
                debt.isPaidOff
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: const [
                          Icon(Icons.check_circle_rounded,
                              size: 14, color: TraumColors.mintGreen),
                          SizedBox(width: 4),
                          Text(
                            'Bezahlt',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                              color: TraumColors.mintGreen,
                            ),
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '${fmtAmount(debt.remainingAmount)} $currency',
                            style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: TraumColors.roseRed,
                            ),
                          ),
                          const Text(
                            'offen',
                            style: TextStyle(
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              color: TraumColors.onBackgroundMuted,
                            ),
                          ),
                        ],
                      ),
              ],
            ),
            // ── Progress bar ─────────────────────────────────────────────
            if (!debt.isPaidOff) ...[
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: SizedBox(
                  height: 6,
                  child: LinearProgressIndicator(
                    value: ratio,
                    backgroundColor: TraumColors.surfaceVariant,
                    valueColor: const AlwaysStoppedAnimation(Colors.transparent),
                  ),
                ),
              ),
              // Overlay the gradient fill on top of the progress track
              Transform.translate(
                offset: const Offset(0, -6),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: SizedBox(
                    height: 6,
                    child: LayoutBuilder(
                      builder: (ctx, constraints) => Stack(
                        children: [
                          Container(
                            width: constraints.maxWidth,
                            color: TraumColors.surfaceVariant,
                          ),
                          Container(
                            width: constraints.maxWidth * ratio,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  TraumColors.mintGreen,
                                  TraumColors.amberGold,
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              // ── Footer ───────────────────────────────────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '$paidPct% getilgt · ${fmtAmount(paidAmount)} $currency bezahlt',
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 9,
                      color: TraumColors.mintGreen,
                    ),
                  ),
                  // "Rate zahlen" pill
                  GestureDetector(
                    onTap: () => _payDialog(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: TraumColors.roseRed.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Rate zahlen',
                        style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: TraumColors.roseRed,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _payDialog(BuildContext context) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: const Text(
          'Rate zahlen',
          style: TextStyle(
              fontFamily: 'DMSans', color: TraumColors.onBackground),
        ),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          autofocus: true,
          style: const TextStyle(
              fontFamily: 'DMSans', color: TraumColors.onBackground),
          decoration: const InputDecoration(hintText: '0,00'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen'),
          ),
          TextButton(
            onPressed: () {
              final a =
                  double.tryParse(ctrl.text.trim().replaceAll(',', '.')) ??
                      0;
              if (a > 0) onPay(a);
              Navigator.pop(ctx);
            },
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
