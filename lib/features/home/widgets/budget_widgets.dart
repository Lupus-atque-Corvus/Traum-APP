import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/components.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/providers/preferences_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart'
    show Account, SavingsGoal, Transaction;
import '../../budget/budget_providers.dart';
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

// ─── One-shot snapshot providers (no drift query streams) ────────────────────

final _accountsSnapshotProvider =
    FutureProvider.autoDispose<List<Account>>((ref) {
  return ref.watch(accountsDaoProvider).getAll();
});

final _savingsGoalsSnapshotProvider =
    FutureProvider.autoDispose<List<SavingsGoal>>((ref) {
  return ref.watch(budgetDaoProvider).getAllSavingsGoals();
});

final _recurringSnapshotProvider =
    FutureProvider.autoDispose<List<Transaction>>((ref) {
  return ref.watch(budgetDaoProvider).getRecurringTransactions();
});

(int, int) _nowYm() {
  final now = DateTime.now();
  return (now.year, now.month);
}

// ─── Registry ────────────────────────────────────────────────────────────────

final Map<HomeWidgetType, HomeWidgetDescriptor> budgetHomeWidgets = {
  HomeWidgetType.balanceMonth: HomeWidgetDescriptor(
    title: 'Saldo',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Saldo',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.budget,
      child: const _BalanceMonthContent(),
    ),
  ),
  HomeWidgetType.incomeExpense: HomeWidgetDescriptor(
    title: 'Ein/Aus',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Ein/Aus',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.budget,
      child: const _IncomeExpenseContent(),
    ),
  ),
  HomeWidgetType.budgetProgress: HomeWidgetDescriptor(
    title: 'Budget',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Budget',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.budget,
      child: const _BudgetProgressContent(),
    ),
  ),
  HomeWidgetType.accountsOverview: HomeWidgetDescriptor(
    title: 'Konten',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Konten',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.budget,
      child: const _AccountsOverviewContent(),
    ),
  ),
  HomeWidgetType.topCategory: HomeWidgetDescriptor(
    title: 'Top-Ausgabe',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Top-Ausgabe',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.budget,
      child: const _TopCategoryContent(),
    ),
  ),
  HomeWidgetType.recentTransactions: HomeWidgetDescriptor(
    title: 'Letzte',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letzte',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.budget,
      child: const _RecentTransactionsContent(),
    ),
  ),
  HomeWidgetType.savingsGoal: HomeWidgetDescriptor(
    title: 'Sparziel',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Sparziel',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.budget,
      child: const _SavingsGoalContent(),
    ),
  ),
  HomeWidgetType.recurringDue: HomeWidgetDescriptor(
    title: 'Wiederkehrend',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Wiederkehrend',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.budget,
      child: const _RecurringDueContent(),
    ),
  ),
  HomeWidgetType.monthTrend: HomeWidgetDescriptor(
    title: 'Monats-Trend',
    group: HomeWidgetGroup.budget,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.budget,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Monats-Trend',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.budget,
      child: const _MonthTrendContent(),
    ),
  ),
};

// ─── Shared bits ─────────────────────────────────────────────────────────────

class _EmptyDash extends StatelessWidget {
  const _EmptyDash();

  @override
  Widget build(BuildContext context) {
    return const Text(
      '—',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
      ),
    );
  }
}

String _fmtAmount(double v) {
  final sign = v < 0 ? '−' : '';
  return '$sign${v.abs().toStringAsFixed(0)}';
}

// ─── Saldo (balanceMonth) ────────────────────────────────────────────────────

class _BalanceMonthContent extends ConsumerWidget {
  const _BalanceMonthContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(budgetSummaryProvider(_nowYm())).value;
    final currency = ref.watch(currencySymbolProvider);
    if (summary == null) return const _EmptyDash();
    final balance = summary.balance;
    final color = balance >= 0 ? TraumColors.mintGreen : TraumColors.roseRed;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_fmtAmount(balance)} $currency',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'diesen Monat',
          style: TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Ein/Aus (incomeExpense) ─────────────────────────────────────────────────

class _IncomeExpenseContent extends ConsumerWidget {
  const _IncomeExpenseContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(budgetSummaryProvider(_nowYm())).value;
    final currency = ref.watch(currencySymbolProvider);
    if (summary == null) return const _EmptyDash();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _StatColumn(
          label: 'Ein.',
          value: '+${summary.income.toStringAsFixed(0)} $currency',
          color: TraumColors.mintGreen,
        ),
        _StatColumn(
          label: 'Aus.',
          value: '−${summary.expenses.toStringAsFixed(0)} $currency',
          color: TraumColors.roseRed,
        ),
        _StatColumn(
          label: 'Saldo',
          value: '${_fmtAmount(summary.balance)} $currency',
          color: summary.balance >= 0
              ? TraumColors.mintGreen
              : TraumColors.roseRed,
        ),
      ],
    );
  }
}

class _StatColumn extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatColumn({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
                fontFamily: 'DMSans',
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Budget (budgetProgress) ─────────────────────────────────────────────────

class _BudgetProgressContent extends ConsumerWidget {
  const _BudgetProgressContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(budgetSummaryProvider(_nowYm())).value;
    final prefs = ref.watch(sharedPreferencesProvider);
    final budget = prefs.getDouble('monthly_budget') ?? 0.0;
    if (summary == null || budget <= 0) {
      return const _EmptyDash();
    }
    final spent = summary.expenses;
    final ratio = (spent / budget).clamp(0.0, 1.0);
    final pct = (spent / budget * 100).round();
    final over = spent > budget;
    final color = over ? TraumColors.roseRed : TraumColors.cyanBlue;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$pct%',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: color,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: ratio,
            minHeight: 6,
            backgroundColor: TraumColors.surface,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${spent.toStringAsFixed(0)} / ${budget.toStringAsFixed(0)}',
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Konten (accountsOverview) ───────────────────────────────────────────────

class _AccountsOverviewContent extends ConsumerWidget {
  const _AccountsOverviewContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(_accountsSnapshotProvider).value;
    final currency = ref.watch(currencySymbolProvider);
    if (accounts == null || accounts.isEmpty) {
      return const _EmptyDash();
    }
    final total = accounts.fold<double>(0.0, (sum, a) {
      final contribution = a.type == 'credit' ? -a.balance.abs() : a.balance;
      return sum + contribution;
    });
    final color = total >= 0 ? TraumColors.cyanBlue : TraumColors.roseRed;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            '${_fmtAmount(total)} $currency',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${accounts.length} ${accounts.length == 1 ? 'Konto' : 'Konten'}',
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Top-Ausgabe (topCategory) ───────────────────────────────────────────────

class _TopCategoryContent extends ConsumerWidget {
  const _TopCategoryContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(categoryExpensesProvider(_nowYm())).value;
    final currency = ref.watch(currencySymbolProvider);
    if (cats == null || cats.isEmpty) {
      return const _EmptyDash();
    }
    final top = cats.first; // provider sorts desc by amount
    final emoji = top.category.emoji ?? '📦';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(emoji, style: const TextStyle(fontSize: 26)),
        const SizedBox(height: 4),
        Text(
          top.category.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 2),
        Text(
          '${top.amount.toStringAsFixed(0)} $currency',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: TraumColors.roseRed,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Letzte (recentTransactions) ─────────────────────────────────────────────

class _RecentTransactionsContent extends ConsumerWidget {
  const _RecentTransactionsContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(recentTransactionItemsProvider(3)).value;
    final currency = ref.watch(currencySymbolProvider);
    if (items == null || items.isEmpty) {
      return const _EmptyDash();
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final item in items)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.name.isEmpty ? item.categoryName : item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${item.type == 'income' ? '+' : '−'}'
                  '${item.amount.toStringAsFixed(0)} $currency',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: item.type == 'income'
                        ? TraumColors.mintGreen
                        : TraumColors.roseRed,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ─── Sparziel (savingsGoal) ──────────────────────────────────────────────────

class _SavingsGoalContent extends ConsumerWidget {
  const _SavingsGoalContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goals = ref.watch(_savingsGoalsSnapshotProvider).value;
    if (goals == null || goals.isEmpty) {
      return const _EmptyDash();
    }
    // Prefer an active (non-completed) goal; otherwise fall back to first.
    final goal = goals.firstWhere(
      (g) => !g.isCompleted,
      orElse: () => goals.first,
    );
    final ratio = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final pct = (ratio * 100).round();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressRing(
          value: ratio.toDouble(),
          size: 64,
          color: TraumColors.mintGreen,
          center: Text(
            '$pct%',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: TraumColors.mintGreen,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          goal.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontSize: 12,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Wiederkehrend (recurringDue) ────────────────────────────────────────────

class _RecurringDueContent extends ConsumerWidget {
  const _RecurringDueContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recurring = ref.watch(_recurringSnapshotProvider).value;
    final count = recurring?.length ?? 0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '$count',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w700,
            color: count > 0
                ? TraumColors.roseRed
                : TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        const SizedBox(height: 2),
        const Text(
          'fällig',
          style: TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Monats-Trend (monthTrend) ───────────────────────────────────────────────

class _MonthTrendContent extends ConsumerWidget {
  const _MonthTrendContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bars = ref.watch(trendDataProvider(TrendPeriod.sixMonths)).value;
    if (bars == null || bars.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Daten',
          style: TextStyle(
            fontSize: 13,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      );
    }
    final spots = <FlSpot>[
      for (var i = 0; i < bars.length; i++)
        FlSpot(i.toDouble(), bars[i].income - bars[i].expenses),
    ];
    final labels = [for (final b in bars) b.label];
    return TraumLineChart(
      spots: spots,
      xLabels: labels,
      color: TraumColors.cyanBlue,
      height: 140,
    );
  }
}
