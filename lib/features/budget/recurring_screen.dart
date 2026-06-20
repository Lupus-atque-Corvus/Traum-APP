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
        data: (list) => list.isEmpty
            ? const Center(
                child: Text(
                  'Keine wiederkehrenden Buchungen',
                  style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
              )
            : ListView.separated(
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
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.amberGold),
        ),
        error: (_, _) => const SizedBox.shrink(),
      ),
    );
  }
}
