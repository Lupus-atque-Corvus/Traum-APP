import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'budget_category_icons.dart';
import 'budget_helpers.dart';
import 'budget_scale.dart';
import 'widgets/budget_sub_header.dart';

// ---------------------------------------------------------------------------
// Public types + pure functions (testable)
// ---------------------------------------------------------------------------

class DonutSlice {
  final Color color;
  final double fraction;
  final String name;
  final double amount;

  const DonutSlice({
    required this.color,
    required this.fraction,
    required this.name,
    required this.amount,
  });
}

const List<Color> _kDonutColors = [
  TraumColors.indigoBlue,
  TraumColors.mintGreen,
  TraumColors.coralOrange,
  TraumColors.amberGold,
  TraumColors.cyanBlue,
  TraumColors.lavender,
];

List<DonutSlice> buildDonutSlices(
    Map<int, double> spendingByCategory, List<BudgetCategory> cats) {
  if (spendingByCategory.isEmpty) return [];

  final total = spendingByCategory.values.fold(0.0, (s, v) => s + v);
  if (total == 0) return [];

  // Sort descending by amount
  final sorted = spendingByCategory.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  return sorted.asMap().entries.map((entry) {
    final i = entry.key;
    final e = entry.value;
    final cat = cats.cast<BudgetCategory?>().firstWhere(
          (c) => c?.id == e.key,
          orElse: () => null,
        );
    final name = cat?.name ?? 'Sonstiges';
    return DonutSlice(
      color: _kDonutColors[i % _kDonutColors.length],
      fraction: e.value / total,
      name: name,
      amount: e.value,
    );
  }).toList();
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class BudgetStatsScreen extends ConsumerWidget {
  const BudgetStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currency = ref.watch(currencySymbolProvider);
    final txAsync = ref.watch(allTransactionsStreamProvider);
    final categoriesAsync = ref.watch(allBudgetCategoriesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            BudgetSubHeader(title: AppLocalizations.of(context)!.statistics),
            Expanded(
              child: txAsync.when(
                data: (allTx) => categoriesAsync.when(
                  data: (categories) => _StatsBody(
                    transactions: allTx,
                    categories: categories,
                    currency: currency,
                  ),
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: TraumColors.amberGold)),
                  error: (e, _) => Center(child: Text('$e')),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator(
                        color: TraumColors.amberGold)),
                error: (e, _) => Center(
                    child: Text(
                        '${AppLocalizations.of(context)!.error}: $e',
                        style:
                            const TextStyle(color: TraumColors.roseRed))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Body
// ---------------------------------------------------------------------------

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
    final now = DateTime.now();
    final months = List.generate(6, (i) {
      final d = DateTime(now.year, now.month - (5 - i));
      return d;
    });

    final monthlyData = months.map((m) {
      final monthTx = transactions
          .where((t) => t.date.year == m.year && t.date.month == m.month);
      final income = monthTx
          .where((t) => t.type == 'income')
          .fold(0.0, (s, t) => s + t.amount);
      final expense = monthTx
          .where((t) => t.type == 'expense')
          .fold(0.0, (s, t) => s + t.amount);
      return _MonthData(month: m, income: income, expense: expense);
    }).toList();

    // Category spending totals (all time) — used for top-categories §5.4 and summary cards
    final spendingByCategory = <int, double>{};
    for (final t in transactions.where((t) => t.type == 'expense')) {
      if (t.categoryId != null) {
        spendingByCategory[t.categoryId!] =
            (spendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }
    final sortedCats = spendingByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final totalIncome = transactions
        .where((t) => t.type == 'income')
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpense = transactions
        .where((t) => t.type == 'expense')
        .fold(0.0, (s, t) => s + t.amount);

    // Current month label for donut title
    const monthNames = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
    ];
    final currentMonthLabel = monthNames[now.month - 1];

    // §5.3 Donut data scoped to current month only
    final donutSpendingByCategory = <int, double>{};
    for (final t in transactions.where((t) =>
        t.type == 'expense' &&
        t.date.year == now.year &&
        t.date.month == now.month)) {
      if (t.categoryId != null) {
        donutSpendingByCategory[t.categoryId!] =
            (donutSpendingByCategory[t.categoryId!] ?? 0) + t.amount;
      }
    }

    final donutSlices = buildDonutSlices(donutSpendingByCategory, categories);
    final donutMonthTotal =
        donutSpendingByCategory.values.fold(0.0, (a, b) => a + b);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: bs(12), vertical: bs(8)),
      children: [
        // §5.1 Summary cards
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
          SizedBox(width: bs(10)),
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
        SizedBox(height: bs(12)),

        // §5.2 Monthly bar chart
        Container(
          padding: EdgeInsets.all(bs(12)),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(bs(13)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppLocalizations.of(context)!.last6Months,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 12),
              ),
              SizedBox(height: bs(12)),
              _MonthlyBarChart(monthlyData: monthlyData, currency: currency),
            ],
          ),
        ),
        SizedBox(height: bs(12)),

        // §5.3 Category donut
        if (donutSlices.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(bs(12)),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(bs(13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ausgaben nach Kategorie · $currentMonthLabel',
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
                SizedBox(height: bs(12)),
                _CategoryDonut(
                    slices: donutSlices,
                    totalExpense: donutMonthTotal,
                    currency: currency),
              ],
            ),
          ),
          SizedBox(height: bs(12)),
        ],

        // §5.4 Top categories
        if (sortedCats.isNotEmpty) ...[
          Container(
            padding: EdgeInsets.all(bs(12)),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(bs(13)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppLocalizations.of(context)!.topExpenseCategories,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
                SizedBox(height: bs(10)),
                ...sortedCats.take(5).map((entry) {
                  final cat = categories.cast<BudgetCategory?>().firstWhere(
                      (c) => c?.id == entry.key,
                      orElse: () => null);
                  final name = cat?.name ??
                      AppLocalizations.of(context)!.categoryOther;
                  final ratio =
                      totalExpense > 0 ? entry.value / totalExpense : 0.0;
                  final color = _kDonutColors[
                      sortedCats.indexOf(entry) % _kDonutColors.length];
                  return Padding(
                    padding: EdgeInsets.only(bottom: bs(8)),
                    child: Row(
                      children: [
                        Container(
                          width: bs(28),
                          height: bs(28),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(bs(8)),
                          ),
                          child: Center(
                            child: budgetCategoryGlyph(cat?.emoji,
                                color: color, size: bs(12)),
                          ),
                        ),
                        SizedBox(width: bs(8)),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(name,
                                  style: const TextStyle(
                                      color: TraumColors.onBackground,
                                      fontFamily: 'DMSans',
                                      fontWeight: FontWeight.w600,
                                      fontSize: 10),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                              SizedBox(height: bs(3)),
                              LayoutBuilder(builder: (ctx, constraints) {
                                return Stack(children: [
                                  Container(
                                    height: bs(3),
                                    width: constraints.maxWidth,
                                    decoration: BoxDecoration(
                                      color: TraumColors.surfaceVariant,
                                      borderRadius: BorderRadius.circular(bs(2)),
                                    ),
                                  ),
                                  Container(
                                    height: bs(3),
                                    width: constraints.maxWidth * ratio,
                                    decoration: BoxDecoration(
                                      color: color,
                                      borderRadius: BorderRadius.circular(bs(2)),
                                    ),
                                  ),
                                ]);
                              }),
                            ],
                          ),
                        ),
                        SizedBox(width: bs(8)),
                        SizedBox(
                          width: bs(40),
                          child: Text(
                            '${entry.value.toStringAsFixed(0)} $currency',
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: bs(12)),
        ],

        // §5.5 Monthly table
        _MonthlyTableCard(monthlyData: monthlyData, currency: currency),
        SizedBox(height: bs(16)),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// §5.3 Category Donut
// ---------------------------------------------------------------------------

class _CategoryDonut extends StatelessWidget {
  final List<DonutSlice> slices;
  final double totalExpense;
  final String currency;

  const _CategoryDonut({
    required this.slices,
    required this.totalExpense,
    required this.currency,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Donut
        SizedBox(
          width: bs(100),
          height: bs(100),
          child: CustomPaint(
            painter: _DonutPainter(slices: slices),
            child: Center(
              child: Container(
                width: bs(66),
                height: bs(66),
                decoration: const BoxDecoration(
                  color: TraumColors.surface,
                  shape: BoxShape.circle,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      fmtAmount(totalExpense),
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 12),
                      textAlign: TextAlign.center,
                    ),
                    const Text(
                      'Gesamt',
                      style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 8),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: bs(16)),
        // Legend
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: slices.take(6).map((s) {
              final pct = (s.fraction * 100).toStringAsFixed(0);
              return Padding(
                padding: EdgeInsets.only(bottom: bs(5)),
                child: Row(
                  children: [
                    Container(
                      width: bs(7),
                      height: bs(7),
                      decoration: BoxDecoration(
                        color: s.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: bs(5)),
                    Expanded(
                      child: Text(
                        s.name,
                        style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(width: bs(4)),
                    Text(
                      fmtAmount(s.amount),
                      style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                          fontSize: 10),
                    ),
                    SizedBox(width: bs(4)),
                    SizedBox(
                      width: bs(22),
                      child: Text(
                        '$pct%',
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 9),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _DonutPainter extends CustomPainter {
  final List<DonutSlice> slices;

  const _DonutPainter({required this.slices});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    const gapAngle = 0.02; // small gap between slices in radians
    double startAngle = -math.pi / 2;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = (size.width - bs(66)) / 2; // ring width

    for (final slice in slices) {
      final sweepAngle =
          slice.fraction * (2 * math.pi) - (slices.length > 1 ? gapAngle : 0);
      paint.color = slice.color;
      canvas.drawArc(
        rect.deflate(paint.strokeWidth / 2),
        startAngle,
        sweepAngle.clamp(0.0, 2 * math.pi),
        false,
        paint,
      );
      startAngle += sweepAngle + (slices.length > 1 ? gapAngle : 0);
    }
  }

  @override
  bool shouldRepaint(_DonutPainter oldDelegate) =>
      oldDelegate.slices != slices;
}

// ---------------------------------------------------------------------------
// §5.1 Summary Card
// ---------------------------------------------------------------------------

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
      padding: EdgeInsets.all(bs(11)),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(bs(13)),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: bs(16)),
          SizedBox(height: bs(6)),
          Text(
            '${value.toStringAsFixed(2)} $currency',
            style: TextStyle(
                color: color,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 14),
          ),
          Text(
            label,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 8),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// §5.2 Monthly Bar Chart
// ---------------------------------------------------------------------------

class _MonthlyBarChart extends StatelessWidget {
  final List<_MonthData> monthlyData;
  final String currency;

  const _MonthlyBarChart(
      {required this.monthlyData, required this.currency});

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

    final bandHeight = bs(58.0);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: monthlyData.map((m) {
        final incomeH =
            maxVal > 0 ? (m.income / maxVal) * bandHeight : bs(2.0);
        final expenseH =
            maxVal > 0 ? (m.expense / maxVal) * bandHeight : bs(2.0);
        return Expanded(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: bs(2)),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      width: bs(8),
                      height: incomeH.clamp(bs(2.0), bandHeight),
                      decoration: BoxDecoration(
                        color: TraumColors.mintGreen,
                        borderRadius: BorderRadius.circular(bs(3)),
                      ),
                    ),
                    SizedBox(width: bs(2)),
                    Container(
                      width: bs(8),
                      height: expenseH.clamp(bs(2.0), bandHeight),
                      decoration: BoxDecoration(
                        color: TraumColors.roseRed,
                        borderRadius: BorderRadius.circular(bs(3)),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: bs(4)),
                Text(
                  monthShort[m.month.month - 1],
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 7),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ---------------------------------------------------------------------------
// §5.5 Monthly Table
// ---------------------------------------------------------------------------

class _MonthlyTableCard extends StatelessWidget {
  final List<_MonthData> monthlyData;
  final String currency;

  const _MonthlyTableCard(
      {required this.monthlyData, required this.currency});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final monthShort = [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];

    return Container(
      padding: EdgeInsets.all(bs(12)),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(bs(13)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Monatliche Übersicht',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 12),
          ),
          SizedBox(height: bs(8)),
          // Header row
          _TableRow(
            month: '',
            income: 'Einnahmen',
            expense: 'Ausgaben',
            balance: 'Bilanz',
            isHeader: true,
            isCurrent: false,
          ),
          for (final m in monthlyData.reversed.take(6))
            _TableRow(
              month: monthShort[m.month.month - 1],
              income: fmtAmount(m.income),
              expense: fmtAmount(m.expense),
              balance:
                  '${m.income - m.expense < 0 ? '−' : ''}${fmtAmount((m.income - m.expense).abs())}',
              isPositive: m.income >= m.expense,
              isCurrent:
                  m.month.year == now.year && m.month.month == now.month,
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
  final bool isCurrent;

  const _TableRow({
    required this.month,
    required this.income,
    required this.expense,
    required this.balance,
    required this.isCurrent,
    this.isHeader = false,
    this.isPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isHeader
        ? TraumColors.onBackgroundMuted
        : isCurrent
            ? TraumColors.onBackground
            : TraumColors.onBackgroundMuted;

    TextStyle cell(Color color) => TextStyle(
          fontFamily: 'DMSans',
          fontSize: isHeader ? 8 : 9,
          fontWeight: isHeader ? FontWeight.w400 : FontWeight.w400,
          color: color,
        );

    return Container(
      decoration: isHeader
          ? null
          : BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
      padding: EdgeInsets.symmetric(vertical: bs(5)),
      child: Row(children: [
        SizedBox(
          width: bs(48),
          child: Text(month, style: cell(textColor)),
        ),
        Expanded(
          child: Text(
            income,
            textAlign: TextAlign.right,
            style: cell(isHeader
                ? TraumColors.onBackgroundMuted
                : TraumColors.mintGreen),
          ),
        ),
        Expanded(
          child: Text(
            expense,
            textAlign: TextAlign.right,
            style: cell(isHeader
                ? TraumColors.onBackgroundMuted
                : TraumColors.roseRed),
          ),
        ),
        Expanded(
          child: Text(
            balance,
            textAlign: TextAlign.right,
            style: cell(isHeader
                ? TraumColors.onBackgroundMuted
                : isPositive
                    ? TraumColors.mintGreen
                    : TraumColors.roseRed),
          ),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Internal data model
// ---------------------------------------------------------------------------

class _MonthData {
  final DateTime month;
  final double income;
  final double expense;

  const _MonthData(
      {required this.month, required this.income, required this.expense});
}
