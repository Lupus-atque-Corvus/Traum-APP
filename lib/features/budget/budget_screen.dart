import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});

  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  DateTime _selectedMonth = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() => setState(() {
        _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1);
      });

  void _nextMonth() {
    final next = DateTime(_selectedMonth.year, _selectedMonth.month + 1);
    if (next.isBefore(DateTime(DateTime.now().year, DateTime.now().month + 1))) {
      setState(() => _selectedMonth = next);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = ref.watch(currencySymbolProvider);
    final txAsync = ref.watch(
      StreamProvider((ref) => ref
          .watch(budgetDaoProvider)
          .watchTransactionsForMonth(_selectedMonth.year, _selectedMonth.month)),
    );
    final categoriesAsync = ref.watch(
      StreamProvider((ref) => ref.watch(budgetDaoProvider).watchAllCategories()),
    );

    const monthNames = ['Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'];

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Budget',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_rounded, color: TraumColors.amberGold),
            tooltip: 'Statistiken',
            onPressed: () => context.go('/budget/stats'),
          ),
          IconButton(
            icon: const Icon(Icons.savings_rounded, color: TraumColors.mintGreen),
            tooltip: 'Sparziele',
            onPressed: () => context.go('/budget/savings'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.amberGold,
        onPressed: () => context.go('/budget/add'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: TraumColors.onBackgroundMuted),
                  onPressed: _prevMonth,
                ),
                Text(
                  '${monthNames[_selectedMonth.month - 1]} ${_selectedMonth.year}',
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 16),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: TraumColors.onBackgroundMuted),
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),
          Expanded(
            child: txAsync.when(
              data: (transactions) {
                final totalIncome = transactions
                    .where((t) => t.type == 'income')
                    .fold(0.0, (s, t) => s + t.amount);
                final totalExpense = transactions
                    .where((t) => t.type == 'expense')
                    .fold(0.0, (s, t) => s + t.amount);
                final balance = totalIncome - totalExpense;

                return categoriesAsync.when(
                  data: (categories) => ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _BalanceCard(
                        balance: balance,
                        income: totalIncome,
                        expense: totalExpense,
                        currency: currency,
                      ),
                      const SizedBox(height: 16),
                      if (categories.isNotEmpty) ...[
                        _CategoryDonut(
                          transactions: transactions.where((t) => t.type == 'expense').toList(),
                          categories: categories,
                          currency: currency,
                        ),
                        const SizedBox(height: 16),
                        _CategoryBars(
                          transactions: transactions.where((t) => t.type == 'expense').toList(),
                          categories: categories,
                          currency: currency,
                        ),
                        const SizedBox(height: 16),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Letzte Transaktionen',
                              style: TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15)),
                          TextButton(
                            onPressed: () => context.go('/budget/transactions'),
                            child: const Text('Alle',
                                style: TextStyle(color: TraumColors.amberGold, fontFamily: 'DMSans')),
                          ),
                        ],
                      ),
                      if (transactions.isEmpty)
                        const _EmptyTransactions()
                      else
                        ...transactions.take(10).map((t) => _TransactionTile(
                              transaction: t,
                              categories: categories,
                              currency: currency,
                              onDelete: () => ref.read(budgetDaoProvider).deleteTransaction(t.id),
                            )),
                    ],
                  ),
                  loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.amberGold)),
                  error: (e, _) => Center(child: Text('$e')),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator(color: TraumColors.amberGold)),
              error: (e, _) => Center(
                  child: Text('Fehler: $e', style: const TextStyle(color: TraumColors.roseRed))),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  final double balance;
  final double income;
  final double expense;
  final String currency;

  const _BalanceCard({
    required this.balance,
    required this.income,
    required this.expense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final isPositive = balance >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(
          color: isPositive
              ? TraumColors.mintGreen.withValues(alpha: 0.3)
              : TraumColors.roseRed.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Text(
            '${isPositive ? '+' : ''}${balance.toStringAsFixed(2)} $currency',
            style: TextStyle(
                color: isPositive ? TraumColors.mintGreen : TraumColors.roseRed,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 32),
          ),
          const SizedBox(height: 4),
          const Text('Saldo diesen Monat',
              style: TextStyle(
                  color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 12)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_downward_rounded,
                  label: 'Einnahmen',
                  amount: income,
                  currency: currency,
                  color: TraumColors.mintGreen,
                ),
              ),
              Container(width: 1, height: 40, color: TraumColors.surfaceVariant),
              Expanded(
                child: _StatItem(
                  icon: Icons.arrow_upward_rounded,
                  label: 'Ausgaben',
                  amount: expense,
                  currency: currency,
                  color: TraumColors.roseRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final double amount;
  final String currency;
  final Color color;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.amount,
    required this.currency,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Icon(icon, color: color, size: 16),
      const SizedBox(height: 4),
      Text('${amount.toStringAsFixed(2)} $currency',
          style: TextStyle(
              color: color, fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 14)),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 11)),
    ]);
  }
}

class _CategoryDonut extends StatelessWidget {
  final List<Transaction> transactions;
  final List<BudgetCategory> categories;
  final String currency;

  const _CategoryDonut({
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final spendingByCategory = <int, double>{};
    for (final t in transactions) {
      if (t.categoryId != null) {
        spendingByCategory[t.categoryId!] =
            (spendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }
    if (spendingByCategory.isEmpty) return const SizedBox.shrink();

    final categoryColors = [
      TraumColors.amberGold,
      TraumColors.coralOrange,
      TraumColors.indigoBlue,
      TraumColors.mintGreen,
      TraumColors.lavender,
      TraumColors.cyanBlue,
      TraumColors.roseRed,
      TraumColors.peachOrange,
    ];

    final sections = <DonutSection>[];
    final legend = <_LegendItem>[];
    int colorIdx = 0;
    for (final entry in spendingByCategory.entries) {
      final cat = categories.firstWhere((c) => c.id == entry.key,
          orElse: () => BudgetCategory(
              id: 0, name: 'Sonstige', emoji: null, monthlyLimit: null, color: null, isExpense: true));
      final color = categoryColors[colorIdx % categoryColors.length];
      sections.add(DonutSection(value: entry.value, color: color, label: cat.name));
      legend.add(_LegendItem(label: cat.name, amount: entry.value, color: color, currency: currency));
      colorIdx++;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Row(
        children: [
          DonutChart(sections: sections),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: legend.map((l) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(children: [
                  Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(color: l.color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l.label,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                  ),
                  Text('${l.amount.toStringAsFixed(0)} ${l.currency}',
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 11)),
                ]),
              )).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendItem {
  final String label;
  final double amount;
  final Color color;
  final String currency;
  const _LegendItem(
      {required this.label,
      required this.amount,
      required this.color,
      required this.currency});
}

class _CategoryBars extends StatelessWidget {
  final List<Transaction> transactions;
  final List<BudgetCategory> categories;
  final String currency;

  const _CategoryBars({
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    final catWithLimit =
        categories.where((c) => c.monthlyLimit != null && c.monthlyLimit! > 0).toList();
    if (catWithLimit.isEmpty) return const SizedBox.shrink();

    final spendingByCategory = <int, double>{};
    for (final t in transactions) {
      if (t.categoryId != null) {
        spendingByCategory[t.categoryId!] =
            (spendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Budgets',
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 12),
          ...catWithLimit.map((cat) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: BudgetCategoryBar(
                  name: '${cat.emoji ?? ''} ${cat.name}'.trim(),
                  spent: spendingByCategory[cat.id] ?? 0,
                  limit: cat.monthlyLimit!,
                  currencySymbol: currency,
                ),
              )),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final Transaction transaction;
  final List<BudgetCategory> categories;
  final String currency;
  final VoidCallback onDelete;

  const _TransactionTile({
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
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11),
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

class _EmptyTransactions extends StatelessWidget {
  const _EmptyTransactions();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.receipt_long_rounded, size: 48, color: TraumColors.onBackgroundSubtle),
          SizedBox(height: 12),
          Text('Noch keine Transaktionen',
              style: TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600)),
          SizedBox(height: 4),
          Text('Tippe auf + um eine hinzuzufügen',
              style: TextStyle(
                  color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans',
                  fontSize: 12)),
        ]),
      ),
    );
  }
}
