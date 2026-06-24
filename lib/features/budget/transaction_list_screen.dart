import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'budget_category_icons.dart';
import 'budget_helpers.dart';
import 'budget_scale.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/budget_sub_header.dart';

class TransactionListScreen extends ConsumerStatefulWidget {
  const TransactionListScreen({super.key});

  @override
  ConsumerState<TransactionListScreen> createState() => _TransactionListScreenState();
}

class _TransactionListScreenState extends ConsumerState<TransactionListScreen> {
  String _filter = 'all';

  Future<void> _deleteWithUndo(Transaction t) async {
    await ref.read(budgetDaoProvider).deleteTransaction(t.id);
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context)..clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: const Text('Transaktion gelöscht'),
        action: SnackBarAction(
          label: 'Rückgängig',
          textColor: TraumColors.amberGold,
          onPressed: () {
            ref.read(budgetDaoProvider).insertTransaction(
                  TransactionsCompanion.insert(
                    amount: t.amount,
                    description: t.description,
                    date: t.date,
                    type: Value(t.type),
                    categoryId: Value(t.categoryId),
                    note: Value(t.note),
                    receiptImagePath: Value(t.receiptImagePath),
                    isRecurring: Value(t.isRecurring),
                    recurringDay: Value(t.recurringDay),
                    templateName: Value(t.templateName),
                    splitFromId: Value(t.splitFromId),
                  ),
                );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final txAsync = ref.watch(allTransactionsStreamProvider);
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: SizedBox(
        width: bs(44),
        height: bs(44),
        child: FloatingActionButton(
          backgroundColor: TraumColors.amberGold,
          elevation: 4,
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const QuickEntryBottomSheet(),
          ),
          child: Icon(
            Icons.add_rounded,
            size: bs(20),
            color: TraumColors.background,
          ),
        ),
      ),
      body: Column(
        children: [
          BudgetSubHeader(title: AppLocalizations.of(context)!.allTransactions),
          // Filter chips
          Padding(
            padding: EdgeInsets.symmetric(horizontal: bs(16), vertical: bs(8)),
            child: Row(
              children: [
                _FilterChip(
                  label: AppLocalizations.of(context)!.all,
                  value: 'all',
                  current: _filter,
                  onTap: () => setState(() => _filter = 'all'),
                ),
                SizedBox(width: bs(8)),
                _FilterChip(
                  label: AppLocalizations.of(context)!.expense,
                  value: 'expense',
                  current: _filter,
                  onTap: () => setState(() => _filter = 'expense'),
                ),
                SizedBox(width: bs(8)),
                _FilterChip(
                  label: AppLocalizations.of(context)!.income,
                  value: 'income',
                  current: _filter,
                  onTap: () => setState(() => _filter = 'income'),
                ),
              ],
            ),
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
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.receipt_long_rounded,
                              size: bs(48),
                              color: TraumColors.onBackgroundSubtle,
                            ),
                            SizedBox(height: bs(12)),
                            Text(
                              AppLocalizations.of(context)!.noTransactions,
                              style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    final grouped = <String, List<Transaction>>{};
                    for (final t in filtered) {
                      final key =
                          '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
                      grouped.putIfAbsent(key, () => []).add(t);
                    }

                    return ListView(
                      padding: EdgeInsets.fromLTRB(bs(16), 0, bs(16), bs(80)),
                      children: grouped.entries.map((entry) {
                        final parts = entry.key.split('-');
                        final year = int.parse(parts[0]);
                        final month = int.parse(parts[1]);
                        final l10n = AppLocalizations.of(context)!;
                        final monthNames = [
                          l10n.monthJan, l10n.monthFeb, l10n.monthMar,
                          l10n.monthApr, l10n.monthMay, l10n.monthJun,
                          l10n.monthJul, l10n.monthAug, l10n.monthSep,
                          l10n.monthOct, l10n.monthNov, l10n.monthDec,
                        ];
                        final monthTotal = entry.value
                            .where((t) => t.type == 'expense')
                            .fold(0.0, (s, t) => s + t.amount);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: EdgeInsets.only(top: bs(16), bottom: bs(8)),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${monthNames[month - 1]} $year'.toUpperCase(),
                                    style: const TextStyle(
                                      color: TraumColors.amberGold,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w700,
                                      fontSize: 11,
                                      letterSpacing: 0.66,
                                    ),
                                  ),
                                  Text(
                                    '−${fmtAmount(monthTotal)} $currency',
                                    style: const TextStyle(
                                      color: TraumColors.onBackgroundMuted,
                                      fontFamily: 'DMSans',
                                      fontSize: 10,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Group container: all rows in one surface card
                            Container(
                              margin: EdgeInsets.only(bottom: bs(12)),
                              decoration: BoxDecoration(
                                color: TraumColors.surface,
                                borderRadius: BorderRadius.circular(bs(13)),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.07),
                                ),
                              ),
                              clipBehavior: Clip.hardEdge,
                              child: Column(
                                children: [
                                  for (int i = 0; i < entry.value.length; i++) ...[
                                    if (i > 0)
                                      Divider(
                                        height: bs(1),
                                        thickness: bs(1),
                                        color: Colors.white.withValues(alpha: 0.05),
                                      ),
                                    _TxTile(
                                      transaction: entry.value[i],
                                      categories: categories,
                                      currency: currency,
                                      onTap: () => context
                                          .push('/budget/transaction/${entry.value[i].id}'),
                                      onDelete: () => _deleteWithUndo(entry.value[i]),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: TraumColors.amberGold),
                  ),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(color: TraumColors.amberGold),
              ),
              error: (e, _) => Center(
                child: Text(
                  '${AppLocalizations.of(context)!.error}: $e',
                  style: const TextStyle(color: TraumColors.roseRed),
                ),
              ),
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

  const _FilterChip({
    required this.label,
    required this.value,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == current;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: bs(12), vertical: bs(5)),
        decoration: BoxDecoration(
          color: selected
              ? TraumColors.amberGold.withValues(alpha: 0.2)
              : TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(bs(16)),
          border: Border.all(
            color: TraumColors.amberGold.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? TraumColors.amberGold : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
        ),
      ),
    );
  }
}

class _TxTile extends StatelessWidget {
  final Transaction transaction;
  final List<BudgetCategory> categories;
  final String currency;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TxTile({
    required this.transaction,
    required this.categories,
    required this.currency,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isTransfer = transaction.type == 'transfer';
    final isIncome = transaction.type == 'income';
    final cat = transaction.categoryId != null
        ? categories.cast<BudgetCategory?>().firstWhere(
            (c) => c?.id == transaction.categoryId,
            orElse: () => null)
        : null;

    final dateStr =
        '${transaction.date.day.toString().padLeft(2, '0')}.${transaction.date.month.toString().padLeft(2, '0')}.${transaction.date.year}';

    // Determine accent color for icon container background
    final Color accentColor = isTransfer
        ? TraumColors.cyanBlue
        : isIncome
            ? TraumColors.mintGreen
            : TraumColors.amberGold;

    final Color iconColor = accentColor;

    return Dismissible(
      key: ValueKey(transaction.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: EdgeInsets.only(right: bs(20)),
        color: TraumColors.roseRed.withValues(alpha: 0.2),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: bs(10), vertical: bs(11)),
          child: Row(
            children: [
              // Icon container: 32×32, radius 9, accent@15%
              Container(
                width: bs(32),
                height: bs(32),
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(bs(9)),
                ),
                child: Center(
                  child: isTransfer
                      ? Icon(
                          Icons.swap_horiz_rounded,
                          color: iconColor,
                          size: bs(13),
                        )
                      : (cat?.emoji != null
                          ? budgetCategoryGlyph(
                              cat!.emoji,
                              color: iconColor,
                              size: bs(13),
                            )
                          : Icon(
                              isIncome ? Icons.add_rounded : Icons.remove_rounded,
                              color: iconColor,
                              size: bs(13),
                            )),
                ),
              ),
              SizedBox(width: bs(10)),
              // Name + subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      transaction.description,
                      style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: bs(2)),
                    Text(
                      isTransfer
                          ? '$dateStr  •  Umbuchung'
                          : '$dateStr${cat != null ? '  •  ${cat.name}' : ''}',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 9,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              SizedBox(width: bs(8)),
              // Amount + chevron
              Text(
                isTransfer
                    ? '${fmtAmount(transaction.amount)} $currency'
                    : '${isIncome ? '+' : '-'}${fmtAmount(transaction.amount)} $currency',
                style: TextStyle(
                  color: isTransfer
                      ? TraumColors.onBackgroundMuted
                      : isIncome
                          ? TraumColors.mintGreen
                          : TraumColors.roseRed,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              SizedBox(width: bs(2)),
              Icon(
                Icons.chevron_right_rounded,
                size: bs(10),
                color: TraumColors.onBackgroundSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
