import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/components.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';
import '../../../l10n/app_localizations.dart';
import '../budget_providers.dart';

void _showDepositDialog(
    BuildContext context, WidgetRef ref, SavingsGoal goal, String currency) {
  final controller = TextEditingController();
  showDialog(
    context: context,
    builder: (_) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        backgroundColor: TraumColors.surface,
        title: Text(
          'Einzahlen – ${goal.name}',
          style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          style: const TextStyle(
              color: TraumColors.onBackground, fontFamily: 'DMSans'),
          decoration: InputDecoration(
            labelText: 'Betrag ($currency)',
            labelStyle: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Abbrechen',
                style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans')),
          ),
          TextButton(
            onPressed: () async {
              final amount =
                  double.tryParse(controller.text.replaceAll(',', '.'));
              if (amount == null || amount <= 0) return;
              final newAmount =
                  (goal.currentAmount + amount).clamp(0.0, goal.targetAmount);
              final completed = newAmount >= goal.targetAmount;
              await (ref
                      .read(budgetDaoProvider)
                      .update(ref.read(budgetDaoProvider).savingsGoals)
                    ..where((t) => t.id.equals(goal.id)))
                  .write(SavingsGoalsCompanion(
                currentAmount: Value(newAmount),
                isCompleted: Value(completed),
              ));
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Einzahlen',
                style: TextStyle(
                    color: TraumColors.amberGold,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ),
  );
}

class SavingsCard extends ConsumerWidget {
  final String currency;

  const SavingsCard({super.key, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalsAsync = ref.watch(allSavingsGoalsStreamProvider);
    final debtsAsync = ref.watch(allDebtsStreamProvider);

    return Column(
      children: [
        // Savings goals
        goalsAsync.when(
          data: (goals) {
            final active = goals.where((g) => !g.isCompleted).toList();
            if (active.isEmpty) return const SizedBox.shrink();
            return TraumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        AppLocalizations.of(context)!.budgetSavingGoals,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => context.go('/budget/savings'),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        icon: const Icon(
                          Icons.add_rounded,
                          color: TraumColors.mintGreen,
                          size: 16,
                        ),
                        label: const Text(
                          'Hinzufügen',
                          style: TextStyle(
                            color: TraumColors.mintGreen,
                            fontFamily: 'DMSans',
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...active.map((g) {
                    final ratio =
                        (g.currentAmount / g.targetAmount).clamp(0.0, 1.0);
                    final remaining = g.targetAmount - g.currentAmount;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Expanded(
                              child: Text(
                                g.name,
                                style: const TextStyle(
                                    color: TraumColors.onBackground,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            GestureDetector(
                              onTap: () =>
                                  _showDepositDialog(context, ref, g, currency),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: TraumColors.mintGreenDim,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  'Einzahlen',
                                  style: TextStyle(
                                      color: TraumColors.mintGreen,
                                      fontFamily: 'DMSans',
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${g.currentAmount.toStringAsFixed(0)} / ${g.targetAmount.toStringAsFixed(0)} $currency',
                              style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 12),
                            ),
                          ]),
                          const SizedBox(height: 6),
                          GradientProgressBar(
                            value: ratio,
                            gradient: TraumColors.gradientNutrition,
                          ),
                          const SizedBox(height: 4),
                          if (g.targetDate != null)
                            Text(
                              'Ziel: ${g.targetDate!.day}.${g.targetDate!.month}.${g.targetDate!.year} · noch ${remaining.toStringAsFixed(0)} $currency',
                              style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontSize: 11),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        // Debts
        debtsAsync.when(
          data: (debts) {
            final unpaid = debts.where((d) => !d.isPaidOff).toList();
            if (unpaid.isEmpty) return const SizedBox.shrink();
            return TraumCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.budgetDebts,
                    style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...unpaid.map((d) => Dismissible(
                        key: ValueKey('debt_${d.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 16),
                          color: TraumColors.mintGreenDim,
                          child: const Icon(Icons.check_rounded,
                              color: TraumColors.mintGreen),
                        ),
                        onDismissed: (_) {
                          (ref.read(budgetDaoProvider).update(
                                  ref.read(budgetDaoProvider).debts)
                                ..where((t) => t.id.equals(d.id)))
                              .write(
                            const DebtsCompanion(isPaidOff: Value(true)),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(children: [
                            Expanded(
                              child: Text(
                                d.creditor,
                                style: const TextStyle(
                                    color: TraumColors.onBackground,
                                    fontFamily: 'DMSans',
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                            Text(
                              '${d.remainingAmount.toStringAsFixed(2)} $currency',
                              style: const TextStyle(
                                  color: TraumColors.roseRed,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600),
                            ),
                          ]),
                        ),
                      )),
                ],
              ),
            );
          },
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ],
    );
  }
}
