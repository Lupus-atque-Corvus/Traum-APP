import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'budget_category_icons.dart';
import 'budget_helpers.dart';

class BudgetStatsScreen extends ConsumerWidget {
  const BudgetStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final txAsync = ref.watch(allTransactionsStreamProvider);
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.statistics,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: txAsync.when(
        data: (allTx) => categoriesAsync.when(
          data: (categories) => _StatsBody(
            transactions: allTx,
            categories: categories,
            currency: currency,
          ),
          loading: () => const Center(
              child: CircularProgressIndicator(color: TraumColors.amberGold)),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.amberGold)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }
}

class _StatsBody extends StatelessWidget {
  final List<Transaction> transactions;
  final List<BudgetCategory> categories;
  final String currency;

  const _StatsBody({
    required this.transactions,
    required this.categories,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    // Build monthly aggregates for last 6 months
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return d;
    });

    final monthlyData = months.map((m) {
      final monthTx = transactions.where((t) =>
          t.date.year == m.year && t.date.month == m.month);
      final income = monthTx
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTx
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      return _MonthData(month: m, income: income, expense: expense);
    }).toList();

    // Category spending totals
    final spendingByCategory = <int, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      if (t.categoryId != null) {
        spendingByCategory[t.categoryId!] =
            (spendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }
    final sortedCats = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Overall totals
    final totalIncome =
        transactions.where((t) => t.type == 'income').fold(0.0, (s, t) => s + t.amount);
    final totalExpense =
        transactions.where((t) => t.type == 'expense').fold(0.0, (s, t) => s + t.amount);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary cards
        Row(children: [
          Expanded(
            child: _SummaryCard(
              label: AppLocalizations.of(context)!.totalIncome,
              value: totalIncome,
              currency: currency,
              color: TraumColors.mintGreen,
              icon: Icons.trending_up_rounded,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: AppLocalizations.of(context)!.totalExpense,
              value: totalExpense,
              currency: currency,
              color: TraumColors.roseRed,
              icon: Icons.trending_down_rounded,
            ),
          ),
        ]),
        const SizedBox(height: 16),
        // Monthly bar chart
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(AppLocalizations.of(context)!.last6Months,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                      fontSize: 14)),
              const SizedBox(height: 16),
              _MonthlyBarChart(monthlyData: monthlyData, currency: currency),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Top categories
        if (sortedCats.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppLocalizations.of(context)!.topExpenseCategories,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                const SizedBox(height: 12),
                ...sortedCats.take(5).map((entry) {
                  final cat = categories.cast<BudgetCategory?>().firstWhere(
                      (c) => c?.id == entry.key,
                      orElse: () => null);
                  final name = cat != null
                      ? '${budgetCategoryEmojiPrefix(cat.emoji)}${cat.name}'.trim()
                      : AppLocalizations.of(context)!.categoryOther;
                  final ratio = totalExpense > 0 ? entry.value / totalExpense : 0.0;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(name,
                                style: const TextStyle(
                                    color: TraumColors.onBackground,
                                    fontFamily: 'DMSans',
                                    fontSize: 13)),
                            Text(
                                '${entry.value.toStringAsFixed(2)} $currency  (${(ratio * 100).toStringAsFixed(0)}%)',
                                style: const TextStyle(
                                    color: TraumColors.onBackgroundMuted,
                                    fontFamily: 'DMSans',
                                    fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GradientProgressBar(
                          value: ratio,
                          gradient: const LinearGradient(
                              colors: [TraumColors.amberGold, TraumColors.coralOrange]),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 16),
        _MonthlyTableCard(monthlyData: monthlyData, currency: currency),
      ],
    );
  }
}

class _MonthlyTableCard extends StatelessWidget {
  final List<_MonthData> monthlyData;
  final String currency;

  const _MonthlyTableCard(
      {required this.monthlyData, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final monthShort = [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Monatliche Übersicht',
              style: TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 8),
          const _TableRow(
            month: '',
            income: 'Einnahmen',
            expense: 'Ausgaben',
            balance: 'Bilanz',
            isHeader: true,
          ),
          for (final m in monthlyData.reversed.take(6))
            _TableRow(
              month: monthShort[m.month.month - 1],
              income: fmtAmount(m.income),
              expense: fmtAmount(m.expense),
              balance: '${m.income - m.expense < 0 ? '−' : ''}'
                  '${fmtAmount(m.income - m.expense)}',
              isPositive: m.income >= m.expense,
            ),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  final String month;
  final String income;
  final String expense;
  final String balance;
  final bool isHeader;
  final bool isPositive;

  const _TableRow({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    this.isHeader = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final baseColor = isHeader
        ? TraumColors.onBackgroundSubtle
        : TraumColors.onBackgroundMuted;
    TextStyle cell(Color color) => TextStyle(
          fontFamily: 'DMSans',
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.w600 : FontWeight.w400,
          color: color,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(children: [
        Expanded(
          flex: 2,
          child: Text(month,
              style: cell(isHeader
                  ? baseColor
                  : TraumColors.onBackground)),
        ),
        Expanded(
          flex: 3,
          child: Text(income,
              textAlign: TextAlign.right,
              style: cell(isHeader ? baseColor : TraumColors.mintGreen)),
        ),
        Expanded(
          flex: 3,
          child: Text(expense,
              textAlign: TextAlign.right,
              style: cell(isHeader ? baseColor : TraumColors.roseRed)),
        ),
        Expanded(
          flex: 3,
          child: Text(balance,
              textAlign: TextAlign.right,
              style: cell(isHeader
                  ? baseColor
                  : isPositive
                      ? TraumColors.mintGreen
                      : TraumColors.roseRed)),
        ),
      ]),
    );
  }
}

class _MonthData {
  final DateTime month;
  final double income;
  final double expense;
  const _MonthData({required this.month, required this.income, required this.expense});
}

class _SummaryCard extends StatelessWidget {
  final String label;
  final double value;
  final String currency;
  final Color color;
  final IconData icon;

  const _SummaryCard({
    required this.label,
    required this.value,
    required this.currency,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 8),
        Text('${value.toStringAsFixed(2)} $currency',
            style: TextStyle(
                color: color,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 16)),
        Text(label,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11)),
      ]),
    );
  }
}

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthData> monthlyData;
  final String currency;

  const _MonthlyBarChart({required this.monthlyData, required this.currency});

  @override
  Widget build(BuildContext context) {
    final maxVal = monthlyData
        .expand((m) => [m.income, m.expense])
        .fold(0.0, (a, b) => a > b ? a : b);

    final l10n = AppLocalizations.of(context)!;
    final monthShort = [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyData.map((m) {
        final incomeH = maxVal > 0 ? (m.income / maxVal) * 120 : 0.0;
        final expenseH = maxVal > 0 ? (m.expense / maxVal) * 120 : 0.0;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: 8,
                      height: incomeH.clamp(2.0, 120.0),
                      decoration: BoxDecoration(
                        color: TraumColors.mintGreen,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 2),
                    Container(
                      width: 8,
                      height: expenseH.clamp(2.0, 120.0),
                      decoration: BoxDecoration(
                        color: TraumColors.roseRed,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(monthShort[m.month.month - 1],
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 10)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
