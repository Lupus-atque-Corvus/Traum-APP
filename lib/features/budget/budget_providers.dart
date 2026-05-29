import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../data/database/traum_database.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class BudgetSummary {
  final double income;
  final double expenses;
  final double balance;

  const BudgetSummary({
    required this.income,
    required this.expenses,
    required this.balance,
  });
}

class CategoryExpense {
  final BudgetCategory category;
  final double amount;

  const CategoryExpense({required this.category, required this.amount});
}

enum TrendPeriod { week, month, sixMonths, year }

class TrendBar {
  final String label;
  final double income;
  final double expenses;

  const TrendBar({
    required this.label,
    required this.income,
    required this.expenses,
  });
}

class BudgetCategoryWithSpending {
  final BudgetCategory category;
  final double spent;
  final double budgetLimit;

  const BudgetCategoryWithSpending({
    required this.category,
    required this.spent,
    required this.budgetLimit,
  });

  String get name => category.name;
  String get emoji => category.emoji ?? '💰';
  double get ratio => budgetLimit > 0
      ? (spent / budgetLimit).clamp(0.0, 1.0)
      : 0.0;
  bool get isOverBudget => budgetLimit > 0 && spent > budgetLimit;
}

class RecentTransactionItem {
  final Transaction tx;
  final BudgetCategory? category;

  const RecentTransactionItem({required this.tx, this.category});

  String get name => tx.description;
  double get amount => tx.amount;
  DateTime get date => tx.date;
  String get type => tx.type;
  String get categoryName => category?.name ?? 'Sonstiges';
}

// ─── State Providers ─────────────────────────────────────────────────────────

final selectedBudgetMonthProvider = StateProvider<DateTime>(
  (_) => DateTime(DateTime.now().year, DateTime.now().month),
);

final budgetBalanceVisibleProvider = StateProvider<bool>((_) => true);

final selectedTrendPeriodProvider = StateProvider<TrendPeriod>((_) => TrendPeriod.month);

// Category name filter — set by CategoryGrid tap or DonutChart tap
final selectedCategoryNameProvider = StateProvider<String?>((_) => null);

// Date range filter — set by TrendBarChart bar tap
final trendBarDateRangeProvider =
    StateProvider<(DateTime, DateTime)?>((_) => null);

// ─── Data Providers ───────────────────────────────────────────────────────────

final budgetSummaryProvider = FutureProvider.autoDispose
    .family<BudgetSummary, (int, int)>((ref, ym) async {
  final dao = ref.watch(budgetDaoProvider);
  final txs = await dao.getTransactionsForMonth(ym.$1, ym.$2);
  final income =
      txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
  final expenses =
      txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
  return BudgetSummary(income: income, expenses: expenses, balance: income - expenses);
});

final categoryExpensesProvider = FutureProvider.autoDispose
    .family<List<CategoryExpense>, (int, int)>((ref, ym) async {
  final dao = ref.watch(budgetDaoProvider);
  final txs = await dao.getTransactionsForMonth(ym.$1, ym.$2);
  final cats = await dao.getAllCategories();
  final catMap = {for (final c in cats) c.id: c};

  final spending = <int?, double>{};
  for (final t in txs.where((t) => t.type == 'expense')) {
    spending[t.categoryId] = (spending[t.categoryId] ?? 0) + t.amount;
  }

  final sonstigesCat = BudgetCategory(
    id: 0,
    name: 'Sonstiges',
    emoji: '📦',
    monthlyLimit: null,
    color: null,
    isExpense: true,
  );

  final result = spending.entries
      .map((e) => CategoryExpense(
            category: e.key != null
                ? (catMap[e.key!] ?? sonstigesCat)
                : sonstigesCat,
            amount: e.value,
          ))
      .toList()
    ..sort((a, b) => b.amount.compareTo(a.amount));
  return result;
});

final dailyBalanceSpotsProvider = FutureProvider.autoDispose
    .family<List<FlSpot>, (int, int)>((ref, ym) async {
  final dao = ref.watch(budgetDaoProvider);
  final prefs = ref.read(sharedPreferencesProvider);
  final txs = await dao.getTransactionsForMonth(ym.$1, ym.$2);
  final daysInMonth = DateTime(ym.$1, ym.$2 + 1, 0).day;
  final startBalance =
      prefs.getDouble('monthly_start_balance_${ym.$1}_${ym.$2}') ?? 0.0;

  final Map<int, double> daily = {};
  for (final t in txs) {
    final day = t.date.day;
    daily[day] =
        (daily[day] ?? 0) + (t.type == 'income' ? t.amount : -t.amount);
  }

  double cumulative = startBalance;
  return List.generate(daysInMonth, (i) {
    cumulative += daily[i + 1] ?? 0;
    return FlSpot(i.toDouble(), cumulative);
  });
});

final quickTemplatesProvider = StreamProvider.autoDispose<List<QuickTemplate>>(
  (ref) => ref.watch(budgetDaoProvider).watchQuickTemplates(),
);

final allDebtsStreamProvider = StreamProvider.autoDispose<List<Debt>>(
  (ref) => ref.watch(budgetDaoProvider).watchAllDebts(),
);

final recurringTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>(
  (ref) => ref.watch(budgetDaoProvider).watchRecurringTransactions(),
);

final trendDataProvider = FutureProvider.autoDispose
    .family<List<TrendBar>, TrendPeriod>((ref, period) async {
  final dao = ref.watch(budgetDaoProvider);
  final now = DateTime.now();

  switch (period) {
    case TrendPeriod.week:
      // Last 7 days as individual bars
      final bars = <TrendBar>[];
      for (int i = 6; i >= 0; i--) {
        final day = now.subtract(Duration(days: i));
        final txs = await dao.getTransactionsForMonth(day.year, day.month);
        final dayTxs = txs.where((t) => t.date.day == day.day).toList();
        final income = dayTxs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expenses = dayTxs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        final label = _weekdayLabel(day.weekday);
        bars.add(TrendBar(label: label, income: income, expenses: expenses));
      }
      return bars;

    case TrendPeriod.month:
      // Last 4 weeks
      final bars = <TrendBar>[];
      for (int w = 3; w >= 0; w--) {
        final weekStart = now.subtract(Duration(days: w * 7 + now.weekday - 1));
        double income = 0, expenses = 0;
        for (int d = 0; d < 7; d++) {
          final day = weekStart.add(Duration(days: d));
          if (day.isAfter(now)) break;
          final txs = await dao.getTransactionsForMonth(day.year, day.month);
          final dayTxs = txs.where((t) => t.date.day == day.day).toList();
          income += dayTxs
              .where((t) => t.type == 'income')
              .fold(0.0, (s, t) => s + t.amount);
          expenses += dayTxs
              .where((t) => t.type == 'expense')
              .fold(0.0, (s, t) => s + t.amount);
        }
        bars.add(TrendBar(label: 'KW${3 - w + 1}', income: income, expenses: expenses));
      }
      return bars;

    case TrendPeriod.sixMonths:
      final bars = <TrendBar>[];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final txs = await dao.getTransactionsForMonth(month.year, month.month);
        final income = txs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expenses = txs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        bars.add(TrendBar(
          label: _monthLabel(month.month),
          income: income,
          expenses: expenses,
        ));
      }
      return bars;

    case TrendPeriod.year:
      final bars = <TrendBar>[];
      for (int i = 11; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final txs = await dao.getTransactionsForMonth(month.year, month.month);
        final income = txs
            .where((t) => t.type == 'income')
            .fold(0.0, (s, t) => s + t.amount);
        final expenses = txs
            .where((t) => t.type == 'expense')
            .fold(0.0, (s, t) => s + t.amount);
        bars.add(TrendBar(
          label: _monthLabel(month.month),
          income: income,
          expenses: expenses,
        ));
      }
      return bars;
  }
});

String _weekdayLabel(int weekday) {
  const labels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
  return labels[(weekday - 1) % 7];
}

String _monthLabel(int month) {
  const labels = ['Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
                   'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'];
  return labels[(month - 1) % 12];
}

// ─── Accounts ─────────────────────────────────────────────────────────────────

final totalAccountBalanceProvider = FutureProvider.autoDispose<double>((ref) async {
  return ref.watch(accountsDaoProvider).getTotalBalance();
});

final monthlyBalanceChangeProvider =
    FutureProvider.autoDispose<double?>((ref) async {
  final dao = ref.watch(budgetDaoProvider);
  final now = DateTime.now();
  final thisMonth = await dao.getNetForMonth(now.year, now.month);
  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;
  final lastMonth = await dao.getNetForMonth(prevYear, prevMonth);
  if (lastMonth == 0) return null;
  return (thisMonth - lastMonth) / lastMonth.abs() * 100;
});

// ─── Budget Overview ──────────────────────────────────────────────────────────

final budgetCategoriesWithSpendingProvider =
    FutureProvider.autoDispose.family<List<BudgetCategoryWithSpending>, (int, int)>(
        (ref, ym) async {
  final dao = ref.watch(budgetDaoProvider);
  final txs = await dao.getTransactionsForMonth(ym.$1, ym.$2);
  final cats = await dao.getAllCategories();

  final spendingById = <int, double>{};
  for (final t in txs.where((t) => t.type == 'expense')) {
    if (t.categoryId != null) {
      spendingById[t.categoryId!] =
          (spendingById[t.categoryId!] ?? 0) + t.amount;
    }
  }

  return cats
      .where((c) => c.isExpense && c.monthlyLimit != null && c.monthlyLimit! > 0)
      .map((cat) => BudgetCategoryWithSpending(
            category: cat,
            spent: spendingById[cat.id] ?? 0,
            budgetLimit: cat.monthlyLimit!,
          ))
      .toList()
    ..sort((a, b) => b.ratio.compareTo(a.ratio));
});

// ─── Recent Transactions ──────────────────────────────────────────────────────

final recentTransactionItemsProvider =
    FutureProvider.autoDispose.family<List<RecentTransactionItem>, int>(
        (ref, limit) async {
  final dao = ref.watch(budgetDaoProvider);
  final txs = await dao.getRecentTransactions(limit: limit);
  final cats = await dao.getAllCategories();
  final catMap = {for (final c in cats) c.id: c};
  return txs.map((tx) {
    final cat = tx.categoryId != null ? catMap[tx.categoryId!] : null;
    return RecentTransactionItem(tx: tx, category: cat);
  }).toList();
});
