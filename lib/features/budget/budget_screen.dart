import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/colors.dart';
import 'budget_category_colors.dart';
import 'budget_providers.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/accounts_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/quick_template_row.dart';
import 'widgets/trend_bar_chart.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
          ),
          const SliverToBoxAdapter(child: _BudgetHeaderCard()),
          const SliverToBoxAdapter(child: _GesamtsaldoCard()),
          const SliverToBoxAdapter(child: _KontenCard()),
          const SliverToBoxAdapter(child: _SchnellvorlagenRow()),
          const SliverToBoxAdapter(child: _BudgetUebersichtCard()),
          const SliverToBoxAdapter(child: _DonutChartCard()),
          const SliverToBoxAdapter(child: _KategorieListeCard()),
          const SliverToBoxAdapter(child: _VerlaufCard()),
          const SliverToBoxAdapter(child: _LetzteTransaktionenCard()),
          SliverPadding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).padding.bottom + 90,
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: FloatingActionButton.extended(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (_) => const QuickEntryBottomSheet(),
          ),
          backgroundColor: TraumColors.amberGold,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(50)),
          label: const Text('+ Neu',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
    );
  }
}

// ─── 1. Header Card ───────────────────────────────────────────────────────────

class _BudgetHeaderCard extends ConsumerWidget {
  const _BudgetHeaderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final summary =
        ref.watch(budgetSummaryProvider((month.year, month.month)));
    final visible = ref.watch(budgetBalanceVisibleProvider);

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _NavBtn(
                  icon: Icons.chevron_left,
                  onTap: () => ref
                      .read(selectedBudgetMonthProvider.notifier)
                      .state = DateTime(month.year, month.month - 1),
                ),
                Text(_monthYear(month),
                    style: _style(17, FontWeight.w700)),
                _NavBtn(
                  icon: Icons.chevron_right,
                  onTap: () => ref
                      .read(selectedBudgetMonthProvider.notifier)
                      .state = DateTime(month.year, month.month + 1),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text('Verfügbares Guthaben',
                style: _style(
                    12, FontWeight.w400, TraumColors.onBackgroundMuted)),
            const SizedBox(height: 8),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              summary.when(
                data: (s) => Text(
                  visible
                      ? '${s.balance < 0 ? '−' : ''}${_fmt(s.balance)} €'
                      : '•••• €',
                  style: _style(
                    36,
                    FontWeight.w700,
                    s.balance >= 0
                        ? TraumColors.mintGreen
                        : TraumColors.roseRed,
                  ),
                ),
                loading: () => Text('— €',
                    style: _style(
                        36, FontWeight.w700, TraumColors.onBackgroundMuted)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => ref
                    .read(budgetBalanceVisibleProvider.notifier)
                    .state = !visible,
                child: Icon(
                  visible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: TraumColors.onBackgroundMuted,
                  size: 22,
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.transparent,
                  TraumColors.amberGold.withValues(alpha: 0.7),
                  TraumColors.coralOrange.withValues(alpha: 0.5),
                  Colors.transparent,
                ]),
              ),
            ),
            const SizedBox(height: 16),
            summary.when(
              data: (s) => Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _Metric(
                    icon: Icons.arrow_downward_rounded,
                    iconColor: TraumColors.mintGreen,
                    value: '${_fmt(s.income)} €',
                    valueColor: TraumColors.mintGreen,
                    label: 'Einnahmen',
                  ),
                  _Metric(
                    icon: Icons.arrow_upward_rounded,
                    iconColor: TraumColors.roseRed,
                    value: '${_fmt(s.expenses)} €',
                    valueColor: TraumColors.roseRed,
                    label: 'Ausgaben',
                  ),
                  _Metric(
                    icon: Icons.savings_outlined,
                    iconColor: TraumColors.amberGold,
                    value: s.income > 0
                        ? '${((s.income - s.expenses) / s.income * 100).toStringAsFixed(0)}%'
                        : '0%',
                    valueColor: TraumColors.amberGold,
                    label: 'Gespart',
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 48),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const SizedBox(height: 14),
            summary.when(
              data: (s) {
                final text = _prognose(s, month);
                if (text.isEmpty) return const SizedBox.shrink();
                return Text(text,
                    style: _style(
                        12, FontWeight.w400, TraumColors.onBackgroundMuted));
              },
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
    );
  }

  String _monthYear(DateTime d) {
    const m = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${m[d.month - 1]} ${d.year}';
  }

  String _prognose(BudgetSummary s, DateTime month) {
    final now = DateTime.now();
    if (now.month != month.month || now.year != month.year) return '';
    if (now.day < 5) return '';
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final daily = s.expenses / now.day;
    final forecast = s.balance - daily * (daysInMonth - now.day);
    return 'Prognose: Bei aktuellem Tempo hast du am Monatsende ~${_fmt(forecast)} übrig.';
  }
}

// ─── 2. Gesamtsaldo Card ──────────────────────────────────────────────────────

class _GesamtsaldoCard extends ConsumerWidget {
  const _GesamtsaldoCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visible = ref.watch(budgetBalanceVisibleProvider);
    final balance = ref.watch(totalAccountBalanceProvider);
    final change = ref.watch(monthlyBalanceChangeProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final spots = ref
        .watch(dailyBalanceSpotsProvider((month.year, month.month)));

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Gesamtsaldo', style: _style(16, FontWeight.w600)),
              const SizedBox(width: 8),
              Icon(
                visible
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: TraumColors.onBackgroundMuted,
                size: 18,
              ),
              const Spacer(),
              Icon(Icons.more_horiz,
                  color: TraumColors.onBackgroundMuted, size: 20),
            ]),
            const SizedBox(height: 14),
            Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
              balance.when(
                data: (b) => Text(
                  visible
                      ? '${b < 0 ? '−' : ''}€${_fmt(b)}'
                      : '€ ••••',
                  style: _style(30, FontWeight.w700),
                ),
                loading: () => Text('€ —',
                    style: _style(
                        30, FontWeight.w700, TraumColors.onBackgroundMuted)),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(width: 10),
              change.when(
                data: (c) {
                  if (c == null) return const SizedBox.shrink();
                  final pos = c >= 0;
                  final color =
                      pos ? TraumColors.mintGreen : TraumColors.roseRed;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          pos
                              ? Icons.arrow_upward
                              : Icons.arrow_downward,
                          color: color,
                          size: 11),
                      const SizedBox(width: 2),
                      Text(
                        '${pos ? '+' : ''}${c.toStringAsFixed(1)}%',
                        style: _style(12, FontWeight.w600, color),
                      ),
                    ]),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ]),
            const SizedBox(height: 2),
            Text('vs. letzter Monat',
                style: _style(
                    12, FontWeight.w400, TraumColors.onBackgroundMuted)),
            const SizedBox(height: 16),
            SizedBox(
              height: 130,
              child: spots.when(
                data: (s) {
                  if (s.isEmpty || s.every((p) => p.y == 0)) {
                    return Center(
                      child: Text('Noch keine Transaktionen',
                          style: _style(12, FontWeight.w400,
                              TraumColors.onBackgroundSubtle)),
                    );
                  }
                  final minY = s.map((p) => p.y).reduce(min);
                  final maxY = s.map((p) => p.y).reduce(max);
                  final padding = (maxY - minY) * 0.15;

                  return LineChart(LineChartData(
                    gridData: const FlGridData(show: false),
                    borderData: FlBorderData(show: false),
                    minY: minY - padding,
                    maxY: maxY + padding,
                    titlesData: FlTitlesData(
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 44,
                          getTitlesWidget: (v, _) => Text(
                            v >= 1000
                                ? '${(v / 1000).toStringAsFixed(0)}k €'
                                : '${v.toInt()} €',
                            style: _style(9, FontWeight.w400,
                                TraumColors.onBackgroundSubtle),
                          ),
                        ),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          getTitlesWidget: (v, _) {
                            final day = v.toInt() + 1;
                            if (day != 1 &&
                                day % 7 != 0 &&
                                day != s.length) {
                              return const SizedBox.shrink();
                            }
                            const abbrs = [
                              'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
                              'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
                            ];
                            return Text(
                              '$day. ${abbrs[month.month - 1]}',
                              style: _style(9, FontWeight.w400,
                                  TraumColors.onBackgroundSubtle),
                            );
                          },
                        ),
                      ),
                    ),
                    lineTouchData: LineTouchData(
                      touchTooltipData: LineTouchTooltipData(
                        getTooltipColor: (_) =>
                            TraumColors.surfaceVariant,
                        tooltipRoundedRadius: 10,
                        getTooltipItems: (spots) => spots
                            .map((sp) => LineTooltipItem(
                                  '${sp.y.toStringAsFixed(0)} €',
                                  _style(12, FontWeight.w600),
                                ))
                            .toList(),
                      ),
                    ),
                    lineBarsData: [
                      LineChartBarData(
                        spots: s,
                        isCurved: true,
                        curveSmoothness: 0.3,
                        color: TraumColors.mintGreen,
                        barWidth: 2,
                        dotData: FlDotData(
                          getDotPainter: (spot, _, __, index) {
                            if (index != s.length - 1) {
                              return FlDotCirclePainter(
                                radius: 0,
                                color: Colors.transparent,
                                strokeColor: Colors.transparent,
                                strokeWidth: 0,
                              );
                            }
                            return FlDotCirclePainter(
                              radius: 5,
                              color: TraumColors.mintGreen,
                              strokeColor: TraumColors.background,
                              strokeWidth: 2,
                            );
                          },
                        ),
                        belowBarData: BarAreaData(
                          show: true,
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              TraumColors.mintGreen
                                  .withValues(alpha: 0.25),
                              TraumColors.mintGreen
                                  .withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      )
                    ],
                  ));
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.mintGreen),
                ),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ),
          ]),
    );
  }
}

// ─── 3. Konten Card ───────────────────────────────────────────────────────────

class _KontenCard extends StatelessWidget {
  const _KontenCard();

  @override
  Widget build(BuildContext context) {
    return const AccountsCard();
  }
}

// ─── 4. Schnellvorlagen Row ───────────────────────────────────────────────────

class _SchnellvorlagenRow extends ConsumerWidget {
  const _SchnellvorlagenRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: QuickTemplateRow(
        onTemplateTap: (t) => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => QuickEntryBottomSheet(initialTemplate: t),
        ),
        onNewTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (_) => const QuickEntryBottomSheet(),
        ),
      ),
    );
  }
}

// ─── 5. Budgetübersicht Card ──────────────────────────────────────────────────

class _BudgetUebersichtCard extends StatelessWidget {
  const _BudgetUebersichtCard();

  @override
  Widget build(BuildContext context) {
    return const BudgetOverviewCard();
  }
}

// ─── 6. Donut Chart Card ──────────────────────────────────────────────────────

class _DonutChartCard extends ConsumerWidget {
  const _DonutChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final cats = ref
        .watch(categoryExpensesProvider((month.year, month.month)));

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Ausgaben nach Kategorien',
                  style: _style(16, FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/budget/categories'),
                child: Text('Mehr ›',
                    style: _style(
                        13, FontWeight.w500, TraumColors.amberGold)),
              ),
            ]),
            const SizedBox(height: 16),
            cats.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Noch keine Ausgaben',
                          style: _style(13, FontWeight.w400,
                              TraumColors.onBackgroundMuted)),
                    ),
                  );
                }

                final total = list.fold(0.0, (s, c) => s + c.amount);

                return Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 150,
                            height: 150,
                            child: PieChart(PieChartData(
                              sectionsSpace: 2,
                              centerSpaceRadius: 46,
                              startDegreeOffset: -90,
                              sections: list.asMap().entries.map((entry) {
                                final cat = entry.value;
                                return PieChartSectionData(
                                  value: cat.amount,
                                  color: categoryColor(cat.category.id),
                                  radius: 42,
                                  showTitle: false,
                                  borderSide: BorderSide(
                                      color: TraumColors.surface,
                                      width: 2),
                                );
                              }).toList(),
                            )),
                          ),
                          Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('€${_fmtK(total)}',
                                    style: _style(16, FontWeight.w700)),
                                Text('Gesamt',
                                    style: _style(
                                        11,
                                        FontWeight.w400,
                                        TraumColors.onBackgroundMuted)),
                              ]),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: list.asMap().entries.map((entry) {
                            final cat = entry.value;
                            final percent = total > 0
                                ? (cat.amount / total * 100).round()
                                : 0;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: categoryColor(cat.category.id),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(cat.category.name,
                                      style:
                                          _style(12, FontWeight.w500)),
                                ),
                                Text('€${_fmtK(cat.amount)}',
                                    style: _style(12, FontWeight.w600)),
                                const SizedBox(width: 6),
                                SizedBox(
                                  width: 32,
                                  child: Text('$percent%',
                                      style: _style(
                                          12,
                                          FontWeight.w400,
                                          TraumColors.onBackgroundMuted),
                                      textAlign: TextAlign.right),
                                ),
                              ]),
                            );
                          }).toList(),
                        ),
                      ),
                    ]);
              },
              loading: () => const SizedBox(
                height: 150,
                child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.amberGold),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
    );
  }
}

// ─── 7. Kategorie Liste Card ──────────────────────────────────────────────────

class _KategorieListeCard extends ConsumerWidget {
  const _KategorieListeCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final cats = ref
        .watch(categoryExpensesProvider((month.year, month.month)));

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Kategorie-Detail',
                  style: _style(16, FontWeight.w600)),
              const Spacer(),
              Icon(Icons.more_horiz,
                  color: TraumColors.onBackgroundMuted, size: 20),
            ]),
            const SizedBox(height: 14),
            cats.when(
              data: (list) {
                if (list.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      child: Text('Noch keine Ausgaben',
                          style: _style(13, FontWeight.w400,
                              TraumColors.onBackgroundMuted)),
                    ),
                  );
                }
                final total = list.fold(0.0, (s, c) => s + c.amount);
                return Column(
                  children: list.asMap().entries.map((entry) {
                    final cat = entry.value;
                    final ratio = total > 0 ? cat.amount / total : 0.0;
                    final percent = (ratio * 100).round();
                    final color = categoryColor(cat.category.id);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              cat.category.emoji ?? '💰',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat.category.name,
                                  style: _style(13, FontWeight.w500)),
                              const SizedBox(height: 5),
                              ClipRRect(
                                borderRadius: BorderRadius.circular(3),
                                child: LinearProgressIndicator(
                                  value: ratio,
                                  minHeight: 3,
                                  backgroundColor:
                                      TraumColors.surfaceVariant,
                                  valueColor:
                                      AlwaysStoppedAnimation(color),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('€${_fmt(cat.amount)}',
                                style: _style(13, FontWeight.w600)),
                            Text('$percent%',
                                style: _style(11, FontWeight.w400,
                                    TraumColors.onBackgroundMuted)),
                          ],
                        ),
                      ]),
                    );
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.amberGold),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
    );
  }
}

// ─── 8. Verlauf Card ──────────────────────────────────────────────────────────

class _VerlaufCard extends ConsumerWidget {
  const _VerlaufCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const TrendBarChart();
  }
}

// ─── 9. Letzte Transaktionen Card ─────────────────────────────────────────────

class _LetzteTransaktionenCard extends ConsumerWidget {
  const _LetzteTransaktionenCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(recentTransactionItemsProvider(5));

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Letzte Transaktionen',
                  style: _style(16, FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/budget/transactions'),
                child: Text('Mehr ›',
                    style: _style(
                        13, FontWeight.w500, TraumColors.amberGold)),
              ),
            ]),
            const SizedBox(height: 8),
            txs.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Column(children: [
                        const Icon(Icons.receipt_long_outlined,
                            color: TraumColors.onBackgroundSubtle,
                            size: 32),
                        const SizedBox(height: 8),
                        Text('Noch keine Transaktionen',
                            style: _style(13, FontWeight.w400,
                                TraumColors.onBackgroundMuted)),
                        const SizedBox(height: 4),
                        Text('Tippe auf + Neu um eine einzutragen',
                            style: _style(12, FontWeight.w400,
                                TraumColors.onBackgroundSubtle)),
                      ]),
                    ),
                  );
                }

                return Column(
                  children: list.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    final isIncome = tx.type == 'income';
                    final amountColor = isIncome
                        ? TraumColors.mintGreen
                        : TraumColors.onBackground;
                    final prefix = isIncome ? '+' : '−';
                    final catColor = _catColor(tx.tx.categoryId);

                    return Column(children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              tx.category?.emoji ?? '💰',
                              style: const TextStyle(fontSize: 18),
                            ),
                          ),
                        ),
                        title: Text(tx.name,
                            style: _style(14, FontWeight.w600)),
                        subtitle: Text(tx.categoryName,
                            style: _style(12, FontWeight.w400,
                                TraumColors.onBackgroundMuted)),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                                '$prefix€${_fmt(tx.amount.abs())}',
                                style: _style(
                                    14, FontWeight.w700, amountColor)),
                            Text(_dateLabel(tx.date),
                                style: _style(12, FontWeight.w400,
                                    TraumColors.onBackgroundMuted)),
                          ],
                        ),
                        onTap: () => context
                            .go('/budget/transaction/${tx.tx.id}'),
                      ),
                      if (i < list.length - 1)
                        Divider(
                            height: 1,
                            color:
                                Colors.white.withValues(alpha: 0.06)),
                    ]);
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                height: 80,
                child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.amberGold),
                ),
              ),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ]),
    );
  }

  Color _catColor(int? categoryId) {
    if (categoryId == null) return TraumColors.amberGold;
    return categoryColor(categoryId % kBudgetCategoryColors.length);
  }

  String _dateLabel(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return 'Heute';
    if (d == today.subtract(const Duration(days: 1))) return 'Gestern';
    const m = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${date.day}. ${m[date.month - 1]}';
  }
}

// ─── Helper Widgets & Functions ───────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.08), width: 1),
        ),
        child: child,
      );
}

TextStyle _style(double size, FontWeight weight, [Color? color]) =>
    TextStyle(
      fontFamily: 'DMSans',
      fontSize: size,
      fontWeight: weight,
      color: color ?? TraumColors.onBackground,
    );

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _NavBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Icon(icon, color: TraumColors.onBackground, size: 24),
      );
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String value;
  final Color valueColor;
  final String label;
  const _Metric({
    required this.icon,
    required this.iconColor,
    required this.value,
    required this.valueColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) => Column(children: [
        Icon(icon, color: iconColor, size: 16),
        const SizedBox(height: 4),
        Text(value, style: _style(14, FontWeight.w700, valueColor)),
        Text(label,
            style:
                _style(11, FontWeight.w400, TraumColors.onBackgroundMuted)),
      ]);
}

String _fmt(double v) => v
    .abs()
    .toStringAsFixed(2)
    .replaceAll('.', ',')
    .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+,)'), (m) => '${m[1]}.');

String _fmtK(double v) => v >= 1000
    ? '${(v / 1000).toStringAsFixed(1).replaceAll('.', ',')}k'
    : v.toStringAsFixed(0);

