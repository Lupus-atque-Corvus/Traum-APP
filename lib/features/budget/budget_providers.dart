import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers/database_provider.dart';
import '../../data/database/traum_database.dart';

/// Budget-Pacing-Konfiguration (PIXELGENAUE_SPEZIFIKATION §10.5).
/// Pacing-Marker auf Budget-Balken ein/aus.
const bool kShowBudgetPacing = true;

/// „Tag X von 30" — Soll-Position = (kBudgetMonthDay / Tage-im-Monat).
const int kBudgetMonthDay = 21;

double pacingLeftFraction(int daysInMonth) =>
    (kBudgetMonthDay / daysInMonth).clamp(0.0, 1.0);

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

// ─── Data Providers ───────────────────────────────────────────────────────────

final budgetSummaryProvider = StreamProvider.autoDispose
    .family<BudgetSummary, (int, int)>((ref, ym) {
  final dao = ref.watch(budgetDaoProvider);
  return dao.watchTransactionsForMonth(ym.$1, ym.$2).map((txs) {
    final income =
        txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final expenses =
        txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    return BudgetSummary(
        income: income, expenses: expenses, balance: income - expenses);
  });
});

final categoryExpensesProvider = StreamProvider.autoDispose
    .family<List<CategoryExpense>, (int, int)>((ref, ym) {
  final dao = ref.watch(budgetDaoProvider);
  // Categories rarely change but stay reactive: a category edit rebuilds this
  // provider, which re-subscribes the transaction stream below.
  final cats = ref.watch(allBudgetCategoriesStreamProvider).value ?? const [];
  final catMap = {for (final c in cats) c.id: c};

  final sonstigesCat = BudgetCategory(
    id: 0,
    name: 'Sonstiges',
    emoji: '📦',
    monthlyLimit: null,
    color: null,
    isExpense: true,
  );

  return dao.watchTransactionsForMonth(ym.$1, ym.$2).map((txs) {
    final spending = <int?, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      spending[t.categoryId] = (spending[t.categoryId] ?? 0) + t.amount;
    }

    return spending.entries
        .map((e) => CategoryExpense(
              category: e.key != null
                  ? (catMap[e.key!] ?? sonstigesCat)
                  : sonstigesCat,
              amount: e.value,
            ))
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
  });
});

final dailyBalanceSpotsProvider = StreamProvider.autoDispose
    .family<List<FlSpot>, (int, int)>((ref, ym) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  final opening = accounts.fold<double>(0.0, (s, a) => s + a.balance);
  final monthStart = DateTime(ym.$1, ym.$2, 1);
  final daysInMonth = DateTime(ym.$1, ym.$2 + 1, 0).day;
  double net(Transaction t) =>
      t.type == 'income' ? t.amount : (t.type == 'expense' ? -t.amount : 0.0);
  return ref.watch(budgetDaoProvider).watchAllTransactions().map((all) {
    final prior = all
        .where((t) => t.date.isBefore(monthStart))
        .fold(0.0, (s, t) => s + net(t));
    final Map<int, double> daily = {};
    for (final t in all.where((t) =>
        t.date.year == ym.$1 && t.date.month == ym.$2)) {
      daily[t.date.day] = (daily[t.date.day] ?? 0) + net(t);
    }
    double cumulative = opening + prior;
    return List.generate(daysInMonth, (i) {
      cumulative += daily[i + 1] ?? 0;
      return FlSpot(i.toDouble(), cumulative);
    });
  });
});

final quickTemplatesProvider = StreamProvider.autoDispose<List<QuickTemplate>>(
  (ref) => ref.watch(budgetDaoProvider).watchQuickTemplates(),
);

final allDebtsStreamProvider = StreamProvider.autoDispose<List<Debt>>(
  (ref) => ref.watch(budgetDaoProvider).watchAllDebts(),
);

final debtItemsStreamProvider =
    StreamProvider.autoDispose.family<List<DebtItem>, int>(
  (ref, debtId) => ref.watch(budgetDaoProvider).watchDebtItems(debtId),
);

final recurringTransactionsProvider =
    StreamProvider.autoDispose<List<Transaction>>(
  (ref) => ref.watch(budgetDaoProvider).watchRecurringTransactions(),
);

final trendDataProvider = StreamProvider.autoDispose
    .family<List<TrendBar>, TrendPeriod>((ref, period) {
  final dao = ref.watch(budgetDaoProvider);
  return dao.watchAllTransactions().map((all) {
    final now = DateTime.now();

    double income(Iterable<Transaction> txs) =>
        txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    double expenses(Iterable<Transaction> txs) =>
        txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    bool sameDay(Transaction t, DateTime d) =>
        t.date.year == d.year && t.date.month == d.month && t.date.day == d.day;
    bool sameMonth(Transaction t, DateTime d) =>
        t.date.year == d.year && t.date.month == d.month;

    switch (period) {
      case TrendPeriod.week:
        // Last 7 days as individual bars
        final bars = <TrendBar>[];
        for (int i = 6; i >= 0; i--) {
          final day = now.subtract(Duration(days: i));
          final dayTxs = all.where((t) => sameDay(t, day));
          bars.add(TrendBar(
            label: _weekdayLabel(day.weekday),
            income: income(dayTxs),
            expenses: expenses(dayTxs),
          ));
        }
        return bars;

      case TrendPeriod.month:
        // Last 4 weeks
        final bars = <TrendBar>[];
        for (int w = 3; w >= 0; w--) {
          final weekStart =
              now.subtract(Duration(days: w * 7 + now.weekday - 1));
          double inc = 0, exp = 0;
          for (int d = 0; d < 7; d++) {
            final day = weekStart.add(Duration(days: d));
            if (day.isAfter(now)) break;
            final dayTxs = all.where((t) => sameDay(t, day));
            inc += income(dayTxs);
            exp += expenses(dayTxs);
          }
          bars.add(TrendBar(label: 'KW${3 - w + 1}', income: inc, expenses: exp));
        }
        return bars;

      case TrendPeriod.sixMonths:
        final bars = <TrendBar>[];
        for (int i = 5; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i, 1);
          final mTxs = all.where((t) => sameMonth(t, month));
          bars.add(TrendBar(
            label: _monthLabel(month.month),
            income: income(mTxs),
            expenses: expenses(mTxs),
          ));
        }
        return bars;

      case TrendPeriod.year:
        final bars = <TrendBar>[];
        for (int i = 11; i >= 0; i--) {
          final month = DateTime(now.year, now.month - i, 1);
          final mTxs = all.where((t) => sameMonth(t, month));
          bars.add(TrendBar(
            label: _monthLabel(month.month),
            income: income(mTxs),
            expenses: expenses(mTxs),
          ));
        }
        return bars;
    }
  });
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

/// Pure helper: derives account balances from opening balances + all transactions.
/// Extracted at top-level so both providers share identical logic with no stale capture.
Map<int, double> deriveAccountBalances(List<Account> accounts, List<Transaction> txs) {
  final m = {for (final a in accounts) a.id: a.balance};
  for (final t in txs) {
    switch (t.type) {
      case 'income':
        if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) + t.amount;
        break;
      case 'expense':
        if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) - t.amount;
        break;
      case 'transfer':
        if (t.accountId != null) m[t.accountId!] = (m[t.accountId!] ?? 0) - t.amount;
        if (t.toAccountId != null) m[t.toAccountId!] = (m[t.toAccountId!] ?? 0) + t.amount;
        break;
    }
  }
  return m;
}

/// Konto-ID → abgeleiteter Stand (Startsaldo + verknüpfte Buchungen + Transfers).
final accountDerivedBalancesProvider =
    StreamProvider.autoDispose<Map<int, double>>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  return ref.watch(budgetDaoProvider).watchAllTransactions().map(
    (txs) => deriveAccountBalances(accounts, txs),
  );
});

final totalAccountBalanceProvider = StreamProvider.autoDispose<double>((ref) {
  final accounts = ref.watch(accountsStreamProvider).value ?? const [];
  return ref.watch(budgetDaoProvider).watchAllTransactions().map((txs) {
    final balances = deriveAccountBalances(accounts, txs);
    return balances.values.fold<double>(0.0, (sum, bal) => sum + bal);
  });
});

final monthlyBalanceChangeProvider =
    StreamProvider.autoDispose<double?>((ref) {
  final dao = ref.watch(budgetDaoProvider);
  final now = DateTime.now();
  final prevYear = now.month == 1 ? now.year - 1 : now.year;
  final prevMonth = now.month == 1 ? 12 : now.month - 1;

  double netForMonth(List<Transaction> all, int year, int month) {
    final txs = all.where((t) => t.date.year == year && t.date.month == month);
    final income =
        txs.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final expenses =
        txs.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);
    return income - expenses;
  }

  return dao.watchAllTransactions().map((all) {
    final thisMonth = netForMonth(all, now.year, now.month);
    final lastMonth = netForMonth(all, prevYear, prevMonth);
    if (lastMonth == 0) return null;
    return (thisMonth - lastMonth) / lastMonth.abs() * 100;
  });
});

// ─── Budget Overview ──────────────────────────────────────────────────────────

final budgetCategoriesWithSpendingProvider =
    StreamProvider.autoDispose.family<List<BudgetCategoryWithSpending>, (int, int)>(
        (ref, ym) {
  final dao = ref.watch(budgetDaoProvider);
  final cats = ref.watch(allBudgetCategoriesStreamProvider).value ?? const [];

  return dao.watchTransactionsForMonth(ym.$1, ym.$2).map((txs) {
    final spendingById = <int, double>{};
    for (final t in txs.where((t) => t.type == 'expense')) {
      if (t.categoryId != null) {
        spendingById[t.categoryId!] =
            (spendingById[t.categoryId!] ?? 0) + t.amount;
      }
    }

    return cats
        .where(
            (c) => c.isExpense && c.monthlyLimit != null && c.monthlyLimit! > 0)
        .map((cat) => BudgetCategoryWithSpending(
              category: cat,
              spent: spendingById[cat.id] ?? 0,
              budgetLimit: cat.monthlyLimit!,
            ))
        .toList()
      ..sort((a, b) => b.ratio.compareTo(a.ratio));
  });
});

// ─── Recent Transactions ──────────────────────────────────────────────────────

final recentTransactionItemsProvider =
    StreamProvider.autoDispose.family<List<RecentTransactionItem>, int>(
        (ref, limit) {
  final dao = ref.watch(budgetDaoProvider);
  final cats = ref.watch(allBudgetCategoriesStreamProvider).value ?? const [];
  final catMap = {for (final c in cats) c.id: c};
  // watchAllTransactions() is already ordered newest-first; take the first N.
  return dao.watchAllTransactions().map((all) {
    return all.take(limit).map((tx) {
      final cat = tx.categoryId != null ? catMap[tx.categoryId!] : null;
      return RecentTransactionItem(tx: tx, category: cat);
    }).toList();
  });
});
