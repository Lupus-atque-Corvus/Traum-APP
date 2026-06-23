import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import 'budget_category_colors.dart';
import 'budget_category_icons.dart';
import 'budget_providers.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/accounts_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/hidden_amount.dart';
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
          const SliverPersistentHeader(
            pinned: true,
            delegate: _BudgetHeaderDelegate(),
          ),
          const SliverToBoxAdapter(child: _BudgetHeaderCard()),
          const SliverToBoxAdapter(child: _QuickActionChips()),
          const SliverToBoxAdapter(child: _KontenCard()),
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
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
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
    final currency = ref.watch(currencySymbolProvider);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 2, 16, 9),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [TraumColors.surfaceElevated, TraumColors.surface],
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: TraumColors.amberGold.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verfügbar + Verbergen-Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verfügbar diesen Monat',
                  style: _style(
                      11, FontWeight.w400, TraumColors.onBackgroundMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () => ref
                    .read(budgetBalanceVisibleProvider.notifier)
                    .state = !visible,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: TraumColors.onBackgroundMuted,
                      size: 11,
                    ),
                    const SizedBox(width: 4),
                    Text(visible ? 'Verbergen' : 'Anzeigen',
                        style: _style(10, FontWeight.w600,
                            TraumColors.onBackgroundMuted)),
                  ]),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          summary.when(
            data: (s) => HiddenAmount(
              child: Text(
                '${s.balance < 0 ? '−' : ''}${_fmt(s.balance)} $currency',
                style: _style(
                  34,
                  FontWeight.w700,
                  s.balance >= 0
                      ? TraumColors.mintGreen
                      : TraumColors.roseRed,
                ),
              ),
            ),
            loading: () => Text('— $currency',
                style: _style(
                    34, FontWeight.w700, TraumColors.onBackgroundMuted)),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 3),
          summary.when(
            data: (s) => _prognoseRow(s, month, currency),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          // Einnahmen / Ausgaben / Sparquote
          summary.when(
            data: (s) => Row(children: [
              _MiniStat(
                dotColor: TraumColors.mintGreen,
                label: 'Einnahmen',
                value: '${_fmt(s.income)} $currency',
                valueColor: TraumColors.mintGreen,
              ),
              const SizedBox(width: 5),
              _MiniStat(
                dotColor: TraumColors.roseRed,
                label: 'Ausgaben',
                value: '${_fmt(s.expenses)} $currency',
                valueColor: TraumColors.roseRed,
              ),
              const SizedBox(width: 5),
              _MiniStat(
                dotColor: TraumColors.amberGold,
                label: 'Sparquote',
                value: s.income > 0
                    ? '${((s.income - s.expenses) / s.income * 100).toStringAsFixed(0)} %'
                    : '0 %',
                valueColor: TraumColors.amberGold,
              ),
            ]),
            loading: () => const SizedBox(height: 48),
            error: (_, _) => const SizedBox.shrink(),
          ),
          const SizedBox(height: 10),
          // Gesamtsaldo-Footer
          const _GesamtsaldoFooter(),
        ],
      ),
    );
  }

  Widget _prognoseRow(BudgetSummary s, DateTime month, String currency) {
    final now = DateTime.now();
    if (now.month != month.month || now.year != month.year) {
      return const SizedBox.shrink();
    }
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (now.day < 5) {
      return Text('Tag ${now.day} von $daysInMonth',
          style: _style(10, FontWeight.w400, TraumColors.onBackgroundMuted));
    }
    final daily = s.expenses / now.day;
    final forecast = s.balance - daily * (daysInMonth - now.day);
    return Row(children: [
      Text('Tag ${now.day} von $daysInMonth · Prognose ',
          style: _style(10, FontWeight.w400, TraumColors.onBackgroundMuted)),
      HiddenAmount(
        child: Text('~${_fmt(forecast)} $currency übrig',
            style: _style(10, FontWeight.w600, TraumColors.onBackground)),
      ),
    ]);
  }

}

String _monthYear(DateTime d) {
  const m = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
  ];
  return '${m[d.month - 1]} ${d.year}';
}

// ─── Sticky Monats-Pille ──────────────────────────────────────────────────────

class _BudgetHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _BudgetHeaderDelegate();

  @override
  double get minExtent => 44;
  @override
  double get maxExtent => 52;
  @override
  bool shouldRebuild(_BudgetHeaderDelegate oldDelegate) => false;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    // Titel blendet aus, je mehr gescrollt wird
    final titleOpacity =
        (1.0 - shrinkOffset / (maxExtent - minExtent)).clamp(0.0, 1.0);

    return Container(
      color: TraumColors.background,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Titel scrollt weg
          Opacity(
            opacity: titleOpacity,
            child: Text('Budget', style: _style(24, FontWeight.w700)),
          ),
          const Spacer(),
          // Pille bleibt immer sichtbar, rechts ausgerichtet
          const _MonthPill(),
        ],
      ),
    );
  }
}

class _MonthPill extends ConsumerWidget {
  const _MonthPill();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _NavBtn(
          icon: Icons.chevron_left,
          onTap: () => ref.read(selectedBudgetMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(_monthYear(month), style: _style(13, FontWeight.w600)),
        ),
        _NavBtn(
          icon: Icons.chevron_right,
          onTap: () => ref.read(selectedBudgetMonthProvider.notifier).state =
              DateTime(month.year, month.month + 1),
        ),
      ]),
    );
  }
}

// ─── Gesamtsaldo-Footer (in Hero integriert) ──────────────────────────────────

class _GesamtsaldoFooter extends ConsumerWidget {
  const _GesamtsaldoFooter();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final balance = ref.watch(totalAccountBalanceProvider);
    final change = ref.watch(monthlyBalanceChangeProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final spots =
        ref.watch(dailyBalanceSpotsProvider((month.year, month.month)));
    final currency = ref.watch(currencySymbolProvider);

    return Container(
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Gesamtsaldo · alle Konten',
                  style: _style(
                      9, FontWeight.w400, TraumColors.onBackgroundMuted)),
              const SizedBox(height: 1),
              Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                balance.when(
                  data: (b) => HiddenAmount(
                    child: Text(
                      '${b < 0 ? '−' : ''}${_fmt(b)} $currency',
                      style: _style(15, FontWeight.w700),
                    ),
                  ),
                  loading: () => Text('— $currency',
                      style: _style(
                          15, FontWeight.w700, TraumColors.onBackgroundMuted)),
                  error: (_, _) => const SizedBox.shrink(),
                ),
                const SizedBox(width: 6),
                change.when(
                  data: (c) {
                    if (c == null) return const SizedBox.shrink();
                    final pos = c >= 0;
                    final color =
                        pos ? TraumColors.mintGreen : TraumColors.roseRed;
                    return HiddenAmount(
                      child: Text(
                        '${pos ? '▲' : '▼'} ${c.abs().toStringAsFixed(1)} %',
                        style: _style(9, FontWeight.w600, color),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, _) => const SizedBox.shrink(),
                ),
              ]),
            ],
          ),
          SizedBox(
            width: 68,
            height: 26,
            child: spots.when(
              data: (s) => _MiniSparkline(spots: s),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniSparkline extends StatelessWidget {
  final List<FlSpot> spots;
  const _MiniSparkline({required this.spots});

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty || spots.every((p) => p.y == 0)) {
      return const SizedBox.shrink();
    }
    final minY = spots.map((p) => p.y).reduce(min);
    final maxY = spots.map((p) => p.y).reduce(max);
    final pad = (maxY - minY) * 0.15;
    return LineChart(LineChartData(
      gridData: const FlGridData(show: false),
      borderData: FlBorderData(show: false),
      titlesData: const FlTitlesData(show: false),
      lineTouchData: const LineTouchData(enabled: false),
      minY: minY - pad,
      maxY: maxY + pad,
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: true,
          curveSmoothness: 0.3,
          color: TraumColors.mintGreen,
          barWidth: 1.8,
          dotData: FlDotData(
            getDotPainter: (spot, _, _, index) => index == spots.length - 1
                ? FlDotCirclePainter(
                    radius: 2.5,
                    color: TraumColors.mintGreen,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  )
                : FlDotCirclePainter(
                    radius: 0,
                    color: Colors.transparent,
                    strokeWidth: 0,
                    strokeColor: Colors.transparent,
                  ),
          ),
        ),
      ],
    ));
  }
}

// ─── Quick-Action-Chips ───────────────────────────────────────────────────────

class _QuickActionChips extends StatelessWidget {
  const _QuickActionChips();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(children: [
        _QuickChip(
          label: 'Sparziele',
          icon: Icons.layers_rounded,
          color: TraumColors.amberGold,
          onTap: () => context.push(Routes.savings),
        ),
        const SizedBox(width: 6),
        _QuickChip(
          label: 'Transaktionen',
          icon: Icons.receipt_long_rounded,
          color: TraumColors.cyanBlue,
          onTap: () => context.push(Routes.transactionList),
        ),
        const SizedBox(width: 6),
        _QuickChip(
          label: 'Wiederkehrend',
          icon: Icons.repeat_rounded,
          color: TraumColors.indigoBlue,
          onTap: () => context.push(Routes.recurring),
        ),
        const SizedBox(width: 6),
        _QuickChip(
          label: 'Schulden',
          icon: Icons.shield_rounded,
          color: TraumColors.roseRed,
          onTap: () => context.push(Routes.debts),
        ),
      ]),
    );
  }
}

class _QuickChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _QuickChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 8),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: 14),
            const SizedBox(width: 5),
            Text(label, style: _style(11, FontWeight.w600)),
          ]),
        ),
      );
}

class _MiniStat extends StatelessWidget {
  final Color dotColor;
  final String label;
  final String value;
  final Color valueColor;
  const _MiniStat({
    required this.dotColor,
    required this.label,
    required this.value,
    required this.valueColor,
  });

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
          decoration: BoxDecoration(
            color: TraumColors.background,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(label,
                      style: _style(
                          9, FontWeight.w400, TraumColors.onBackgroundMuted),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              const SizedBox(height: 2),
              HiddenAmount(
                child: Text(value,
                    style: _style(12, FontWeight.w700, valueColor),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
        ),
      );
}

// ─── 3. Konten Card ───────────────────────────────────────────────────────────

class _KontenCard extends StatelessWidget {
  const _KontenCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: AccountsCard(),
    );
  }
}



// ─── 5. Budgetübersicht Card ──────────────────────────────────────────────────

class _BudgetUebersichtCard extends StatelessWidget {
  const _BudgetUebersichtCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: BudgetOverviewCard(),
    );
  }
}

// ─── 6. Donut Chart Card ──────────────────────────────────────────────────────

class _DonutChartCard extends ConsumerWidget {
  const _DonutChartCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final cats = ref.watch(categoryExpensesProvider((month.year, month.month)));
    final currency = ref.watch(currencySymbolProvider);

    return _Card(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text('Ausgaben nach Kategorien', style: _style(16, FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: () => context.go('/budget/categories'),
            child: Text('Mehr ›',
                style: _style(13, FontWeight.w500, TraumColors.amberGold)),
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
                      style: _style(
                          13, FontWeight.w400, TraumColors.onBackgroundMuted)),
                ),
              );
            }

            final total = list.fold(0.0, (s, c) => s + c.amount);

            return Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 140,
                  height: 140,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 44,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(enabled: false),
                        sections: list.asMap().entries.map((entry) {
                          final cat = entry.value;
                          return PieChartSectionData(
                            value: cat.amount,
                            color: colorForCategory(cat.category, entry.key),
                            radius: 40,
                            showTitle: false,
                            borderSide: BorderSide(
                                color: TraumColors.surface, width: 1.5),
                          );
                        }).toList(),
                      )),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        HiddenAmount(
                          child: Text('$currency${_fmtShort(total)}',
                              style: _style(15, FontWeight.w700),
                              textAlign: TextAlign.center),
                        ),
                        Text('Gesamt',
                            style: _style(10, FontWeight.w400,
                                TraumColors.onBackgroundMuted),
                            textAlign: TextAlign.center),
                      ]),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: list.asMap().entries.map((entry) {
                      final cat = entry.value;
                      final percent = total > 0
                          ? (cat.amount / total * 100).round()
                          : 0;
                      final color = colorForCategory(cat.category, entry.key);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 7),
                        child: Row(children: [
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                                color: color, shape: BoxShape.circle),
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(cat.category.name,
                                style: _style(11, FontWeight.w500),
                                overflow: TextOverflow.ellipsis),
                          ),
                          HiddenAmount(
                            child: Text('$currency${_fmtShort(cat.amount)}',
                                style: _style(11, FontWeight.w600)),
                          ),
                          const SizedBox(width: 4),
                          SizedBox(
                            width: 28,
                            child: Text('$percent%',
                                style: _style(11, FontWeight.w400,
                                    TraumColors.onBackgroundMuted),
                                textAlign: TextAlign.right),
                          ),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
              ],
            );
          },
          loading: () => const SizedBox(
            height: 140,
            child: Center(
              child: CircularProgressIndicator(
                  color: TraumColors.amberGold, strokeWidth: 2),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
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
    final currency = ref.watch(currencySymbolProvider);

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text('Kategorie-Detail',
                  style: _style(16, FontWeight.w600)),
              const Spacer(),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_horiz,
                    color: TraumColors.onBackgroundMuted, size: 20),
                color: TraumColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                onSelected: (value) {
                  switch (value) {
                    case 'categories':
                      context.go('/budget/categories');
                      break;
                    case 'stats':
                      context.go('/budget/stats');
                      break;
                  }
                },
                itemBuilder: (_) => [
                  _menuItem('categories', Icons.category_outlined,
                      'Kategorien verwalten'),
                  _menuItem(
                      'stats', Icons.bar_chart_outlined, 'Statistik'),
                ],
              ),
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
                    final color = colorForCategory(cat.category, entry.key);

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
                            child: _catIcon(
                                cat.category.emoji, color, 18),
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
                            HiddenAmount(
                              child: Text('$currency${_fmt(cat.amount)}',
                                  style: _style(13, FontWeight.w600)),
                            ),
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
              error: (_, _) => const SizedBox.shrink(),
            ),
          ]),
    );
  }
}

// ─── 8. Verlauf Card ──────────────────────────────────────────────────────────

class _VerlaufCard extends StatelessWidget {
  const _VerlaufCard();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: TrendBarChart(),
    );
  }
}

// ─── 9. Letzte Transaktionen Card ─────────────────────────────────────────────

class _LetzteTransaktionenCard extends ConsumerWidget {
  const _LetzteTransaktionenCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final txs = ref.watch(recentTransactionItemsProvider(5));
    final currency = ref.watch(currencySymbolProvider);

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
                    final isTransfer = tx.type == 'transfer';
                    final amountColor = isIncome
                        ? TraumColors.mintGreen
                        : isTransfer
                            ? TraumColors.cyanBlue
                            : TraumColors.onBackground;
                    final prefix = isIncome ? '+' : (isTransfer ? '' : '−');
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
                            child: _catIcon(
                                tx.category?.emoji, catColor, 20),
                          ),
                        ),
                        title: Text(tx.name,
                            style: _style(14, FontWeight.w600)),
                        subtitle: Text(tx.categoryName,
                            style: _style(12, FontWeight.w400,
                                TraumColors.onBackgroundMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                HiddenAmount(
                                  child: Text(
                                      '$prefix$currency${_fmt(tx.amount.abs())}',
                                      style: _style(
                                          14, FontWeight.w700, amountColor)),
                                ),
                                Text(_dateLabel(tx.date),
                                    style: _style(12, FontWeight.w400,
                                        TraumColors.onBackgroundMuted)),
                              ],
                            ),
                            const SizedBox(width: 2),
                            const Icon(Icons.chevron_right_rounded,
                                size: 16,
                                color: TraumColors.onBackgroundSubtle),
                          ],
                        ),
                        onTap: () => context
                            .go('/budget/transaction/${tx.tx.id}'),
                      ),
                      if (i < list.length - 1)
                        Divider(
                            height: 1,
                            color: Colors.white.withValues(alpha: 0.06)),
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
              error: (_, _) => const SizedBox.shrink(),
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

PopupMenuItem<String> _menuItem(String value, IconData icon, String label) =>
    PopupMenuItem<String>(
      value: value,
      height: 44,
      child: Row(children: [
        Icon(icon, color: TraumColors.onBackgroundMuted, size: 18),
        const SizedBox(width: 10),
        Text(label, style: _style(13, FontWeight.w500)),
      ]),
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

String _fmt(double v) => v
    .abs()
    .toStringAsFixed(2)
    .replaceAll('.', ',')
    .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+,)'), (m) => '${m[1]}.');

String _fmtShort(double v) {
  if (v >= 1000) {
    return v
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+$)'), (m) => '${m[1]}.');
  }
  return v.toStringAsFixed(0);
}

Widget _catIcon(String? emojiOrIcon, Color color, double size) =>
    budgetCategoryGlyph(emojiOrIcon, color: color, size: size);

