import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _filter = 'all';

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final txAsync = ref.watch(allTransactionsStreamProvider);
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.allTransactions,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.amberGold,
        onPressed: () => context.go('/budget/add'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(children: [
              _FilterChip(label: AppLocalizations.of(context)!.all, value: 'all', current: _filter,
                  onTap: () => setState(() => _filter = 'all')),
              const SizedBox(width: 8),
              _FilterChip(label: AppLocalizations.of(context)!.expense, value: 'expense', current: _filter,
                  onTap: () => setState(() => _filter = 'expense')),
              const SizedBox(width: 8),
              _FilterChip(label: AppLocalizations.of(context)!.income, value: 'income', current: _filter,
                  onTap: () => setState(() => _filter = 'income')),
            ]),
          ),
          Expanded(
            child: txAsync.when(
              data: (allTx) {
                final filtered = _filter == 'all'
                    ? allTx
                    : allTx.where((t) => t.type == _filter).toList();

                return categoriesAsync.when(
                  data: (categories) {
                    if (filtered.isEmpty) {
                      return Center(
                        child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.receipt_long_rounded,
                              size: 48, color: TraumColors.onBackgroundSubtle),
                          const SizedBox(height: 12),
                          Text(AppLocalizations.of(context)!.noTransactions,
                              style: const TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600)),
                        ]),
                      );
                    }

                    final grouped = <String, List<Transaction>>{};
                    for (final t in filtered) {
                      final key =
                          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
                      grouped.putIfAbsent(key, () => []).add(t);
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                      children: grouped.entries.map((entry) {
                        final parts = entry.key.split('-');
                        final year = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final l10n = AppLocalizations.of(context)!;
                        final monthNames = [
                          l10n.monthJan, l10n.monthFeb, l10n.monthMar, l10n.monthApr,
                          l10n.monthMay, l10n.monthJun, l10n.monthJul, l10n.monthAug,
                          l10n.monthSep, l10n.monthOct, l10n.monthNov, l10n.monthDec,
                        ];
                        final monthTotal = entry.value
                            .where((t) => t.type == 'expense')
                            .fold(0.0, (s, t) => s + t.amount);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 16, bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('${monthNames[month - 1]} $year',
                                      style: const TextStyle(
                                          color: TraumColors.amberGold,
                                          fontFamily: 'DMSans',
                                          fontWeight: FontWeight.w700,
                                          fontSize: 13)),
                                  Text('${monthTotal.toStringAsFixed(2)} $currency',
                                      style: const TextStyle(
                                          color: TraumColors.onBackgroundMuted,
                                          fontFamily: 'DMSans',
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            ...entry.value.map((t) => _TxTile(
                                  transaction: t,
                                  categories: categories,
                                  currency: currency,
                                  onDelete: () =>
                                      ref.read(budgetDaoProvider).deleteTransaction(t.id),
                                )),
                          ],
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: TraumColors.amberGold)),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: TraumColors.amberGold)),
              error: (e, _) => Center(
                  child: Text('${AppLocalizations.of(context)!.error}: $e',
                      style: const TextStyle(color: TraumColors.roseRed))),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String current;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.value,
      required this.current,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? TraumColors.amberGoldDim : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected ? TraumColors.amberGold : Colors.transparent),
        ),
        child: Text(label,
            style: TextStyle(
                color: selected ? TraumColors.amberGold : TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 13)),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction transaction;
  final List<BudgetCategory> categories;
  final String currency;
  final VoidCallback onDelete;

  const _TxTile({
    required this.transaction,
    required this.categories,
    required this.currency,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final cat = transaction.categoryId != null
        ? categories.cast<BudgetCategory?>().firstWhere(
            (c) => c?.id == transaction.categoryId,
            orElse: () => null)
        : null;

    return Dismissible(
      key: ValueKey(transaction.id),
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
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: ListTile(
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome ? TraumColors.mintGreenDim : TraumColors.amberGoldDim,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: cat?.emoji != null
                  ? Text(cat!.emoji!, style: const TextStyle(fontSize: 18))
                  : Icon(
                      isIncome ? Icons.add_rounded : Icons.remove_rounded,
                      color: isIncome ? TraumColors.mintGreen : TraumColors.amberGold,
                      size: 20,
                    ),
            ),
          ),
          title: Text(transaction.description,
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w500)),
          subtitle: Text(
            '${transaction.date.day.toString().padLeft(2, '0')}.${transaction.date.month.toString().padLeft(2, '0')}.${transaction.date.year}'
            '${cat != null ? '  •  ${cat.name}' : ''}',
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11),
          ),
          trailing: Text(
            '${isIncome ? '+' : '-'}${transaction.amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
                color: isIncome ? TraumColors.mintGreen : TraumColors.roseRed,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 14),
          ),
        ),
      ),
    );
  }
}
