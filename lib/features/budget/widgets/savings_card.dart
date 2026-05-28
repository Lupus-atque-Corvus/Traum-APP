import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/components.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';
import '../budget_providers.dart';

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
                      const Text(
                        'Sparziele',
                        style: TextStyle(
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
                  const Text(
                    'Schulden',
                    style: TextStyle(
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
