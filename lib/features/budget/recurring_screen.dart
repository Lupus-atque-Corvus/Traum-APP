import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import 'budget_helpers.dart';
import 'budget_providers.dart';

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
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: TraumColors.roseRed,
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
