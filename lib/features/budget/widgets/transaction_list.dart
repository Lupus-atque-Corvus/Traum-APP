import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../data/database/traum_database.dart';
import '../../../l10n/app_localizations.dart';
import '../budget_providers.dart';

class TransactionList extends ConsumerStatefulWidget {
  final List<Transaction> transactions;
  final List<BudgetCategory> categories;
  final String currency;
  final void Function(Transaction)? onTransactionTap;

  const TransactionList({
    super.key,
    required this.transactions,
    required this.categories,
    required this.currency,
    this.onTransactionTap,
  });

  @override
  ConsumerState<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends ConsumerState<TransactionList> {
  String _filter = 'all'; // all | income | expense | thisWeek | thisMonth
  String? _categoryFilter;

  List<Transaction> _buildFiltered(
      String? externalCatName, (DateTime, DateTime)? externalDateRange) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return widget.transactions.where((t) {
      // Type filter
      if (_filter == 'income' && t.type != 'income') return false;
      if (_filter == 'expense' && t.type != 'expense') return false;
      // Date filters (local)
      if (_filter == 'thisWeek') {
        final weekStart = today.subtract(Duration(days: today.weekday - 1));
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        if (tDate.isBefore(weekStart)) return false;
      }
      if (_filter == 'thisMonth') {
        if (t.date.year != now.year || t.date.month != now.month) return false;
      }
      // External date range filter (from TrendBarChart tap)
      if (externalDateRange != null) {
        final tDate = DateTime(t.date.year, t.date.month, t.date.day);
        if (tDate.isBefore(externalDateRange.$1) ||
            tDate.isAfter(externalDateRange.$2)) {
          return false;
        }
      }
      // Category filter — external overrides local
      final effectiveCat = externalCatName ?? _categoryFilter;
      if (effectiveCat != null) {
        final cat = widget.categories.cast<BudgetCategory?>().firstWhere(
            (c) => c?.name == effectiveCat,
            orElse: () => null);
        if (cat == null || t.categoryId != cat.id) return false;
      }
      // Hide split parents
      if (t.templateName == 'SPLIT_PARENT') return false;
      return true;
    }).toList();
  }

  Map<String, List<Transaction>> _groupTransactions(List<Transaction> filtered) {
    final grouped = <String, List<Transaction>>{};
    for (final t in filtered) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final tDate = DateTime(t.date.year, t.date.month, t.date.day);
      final String key;
      if (tDate == today) {
        key = 'Heute';
      } else if (tDate == today.subtract(const Duration(days: 1))) {
        key = 'Gestern';
      } else {
        key =
            '${t.date.day.toString().padLeft(2, '0')}.${t.date.month.toString().padLeft(2, '0')}.${t.date.year}';
      }
      grouped.putIfAbsent(key, () => []).add(t);
    }
    return grouped;
  }

  void _clearExternalFilters() {
    ref.read(selectedCategoryNameProvider.notifier).state = null;
    ref.read(trendBarDateRangeProvider.notifier).state = null;
  }

  @override
  Widget build(BuildContext context) {
    final externalCatName = ref.watch(selectedCategoryNameProvider);
    final externalDateRange = ref.watch(trendBarDateRangeProvider);
    final filtered = _buildFiltered(externalCatName, externalDateRange);
    final grouped = _groupTransactions(filtered);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(AppLocalizations.of(context)!.budgetTransactions,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: TraumColors.onBackgroundMuted, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
                const SizedBox(width: 4),
                IconButton(
                  icon: const Icon(Icons.filter_list_rounded,
                      color: TraumColors.onBackgroundMuted, size: 20),
                  onPressed: () {},
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Filter bar
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _FilterChip(
                  label: 'Alle',
                  isSelected: _filter == 'all' && _categoryFilter == null,
                  onTap: () {
                    _clearExternalFilters();
                    setState(() {
                      _filter = 'all';
                      _categoryFilter = null;
                    });
                  }),
              const SizedBox(width: 6),
              _FilterChip(
                  label: AppLocalizations.of(context)!.budgetIncome,
                  isSelected: _filter == 'income',
                  onTap: () {
                    _clearExternalFilters();
                    setState(() {
                      _filter = 'income';
                      _categoryFilter = null;
                    });
                  }),
              const SizedBox(width: 6),
              _FilterChip(
                  label: AppLocalizations.of(context)!.budgetExpenses,
                  isSelected: _filter == 'expense',
                  onTap: () {
                    _clearExternalFilters();
                    setState(() {
                      _filter = 'expense';
                      _categoryFilter = null;
                    });
                  }),
              const SizedBox(width: 6),
              _FilterChip(
                  label: 'Diese Woche',
                  isSelected: _filter == 'thisWeek',
                  onTap: () {
                    _clearExternalFilters();
                    setState(() {
                      _filter = 'thisWeek';
                      _categoryFilter = null;
                    });
                  }),
              const SizedBox(width: 6),
              _FilterChip(
                  label: 'Diesen Monat',
                  isSelected: _filter == 'thisMonth',
                  onTap: () {
                    _clearExternalFilters();
                    setState(() {
                      _filter = 'thisMonth';
                      _categoryFilter = null;
                    });
                  }),
              const SizedBox(width: 6),
              ...widget.categories.take(5).map((cat) => Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: _FilterChip(
                      label: '${cat.emoji ?? ''} ${cat.name}'.trim(),
                      isSelected: _categoryFilter == cat.name,
                      onTap: () => setState(() {
                        _filter = 'all';
                        _categoryFilter =
                            _categoryFilter == cat.name ? null : cat.name;
                      }),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        // Transaction rows grouped by date
        if (grouped.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text('Keine Transaktionen',
                  style: TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans')),
            ),
          )
        else
          ...grouped.entries.map((entry) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(entry.key,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            fontSize: 12)),
                  ),
                  ...entry.value.map((t) => _TransactionTile(
                        transaction: t,
                        categories: widget.categories,
                        currency: widget.currency,
                        onTap: widget.onTransactionTap != null
                            ? () => widget.onTransactionTap!(t)
                            : null,
                        onDelete: () =>
                            ref.read(budgetDaoProvider).deleteTransaction(t.id),
                      )),
                ],
              )),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? TraumColors.amberGoldDim : TraumColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: isSelected
              ? Border.all(color: TraumColors.amberGold)
              : null,
        ),
        child: Text(label,
            style: TextStyle(
              color: isSelected
                  ? TraumColors.amberGold
                  : TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 12,
              fontWeight:
                  isSelected ? FontWeight.w600 : FontWeight.w400,
            )),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final List<BudgetCategory> categories;
  final String currency;
  final VoidCallback? onTap;
  final VoidCallback onDelete;

  const _TransactionTile({
    required this.transaction,
    required this.categories,
    required this.currency,
    required this.onDelete,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final cat = transaction.categoryId != null
        ? categories.cast<BudgetCategory?>().firstWhere(
            (c) => c?.id == transaction.categoryId,
            orElse: () => null)
        : null;
    final timeStr =
        '${transaction.date.hour.toString().padLeft(2, '0')}:${transaction.date.minute.toString().padLeft(2, '0')}';

    return Dismissible(
      key: ValueKey('tx_${transaction.id}'),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.amberGold.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.edit_rounded, color: TraumColors.amberGold),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          onTap?.call();
          return false;
        }
        return true;
      },
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: ListTile(
          onTap: onTap,
          leading: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isIncome
                  ? TraumColors.mintGreenDim
                  : TraumColors.amberGoldDim,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: cat?.emoji != null
                  ? Text(cat!.emoji!,
                      style: const TextStyle(fontSize: 18))
                  : Icon(
                      isIncome
                          ? Icons.arrow_downward_rounded
                          : Icons.arrow_upward_rounded,
                      color: isIncome
                          ? TraumColors.mintGreen
                          : TraumColors.amberGold,
                      size: 18,
                    ),
            ),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            '${cat?.name ?? (isIncome ? 'Einnahmen' : 'Ausgaben')} · $timeStr'
            '${transaction.receiptImagePath != null ? '  🧾' : ''}',
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11),
          ),
          trailing: Text(
            '${isIncome ? '+' : '−'}${transaction.amount.toStringAsFixed(2)} $currency',
            style: TextStyle(
              color: isIncome ? TraumColors.mintGreen : TraumColors.roseRed,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}
