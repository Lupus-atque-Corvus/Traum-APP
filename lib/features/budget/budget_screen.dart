import 'dart:math';

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/navigation/routes.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'budget_category_colors.dart';
import 'budget_category_icons.dart';
import 'budget_providers.dart';
import 'budget_scale.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/accounts_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/hidden_amount.dart';
import 'widgets/trend_bar_chart.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return BudgetTextScale(
      child: Scaffold(
      backgroundColor: TraumColors.background,
      // Der Monats-Pillen-Header lebt bewusst AUSSERHALB des CustomScrollView
      // (nicht als SliverPersistentHeader) — ein pinned Sliver-Header geriet
      // während Navigations-Übergängen wiederholt in einen ungültigen
      // Geometrie-Zustand (SliverGeometry: layoutExtent > paintExtent), der
      // die gesamte Scrollview leer rendern ließ. Ein normaler, nicht in die
      // Sliver-Geometrie eingebundener Header ist davon nicht betroffen.
      body: Column(
        children: [
          SizedBox(height: MediaQuery.of(context).padding.top + 8),
          const _BudgetHeader(),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                const SliverToBoxAdapter(child: _BudgetHeaderCard()),
                const SliverToBoxAdapter(child: _QuickActionChips()),
                const SliverToBoxAdapter(child: _KontenCard()),
                const SliverToBoxAdapter(child: _BudgetUebersichtCard()),
                const SliverToBoxAdapter(child: _VerlaufCard()),
                const SliverToBoxAdapter(child: _LetzteTransaktionenCard()),
                SliverPadding(
                  padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).padding.bottom + 90,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
        ),
        child: SizedBox(
          width: bs(48),
          height: bs(48),
          child: FloatingActionButton(
            onPressed: () => showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (_) => const QuickEntryBottomSheet(),
            ),
            backgroundColor: TraumColors.amberGold,
            elevation: 6,
            shape: const CircleBorder(),
            child: Icon(Icons.add,
                size: bs(22), color: TraumColors.background),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}

// ─── 1. Header Card ───────────────────────────────────────────────────────────

class _BudgetHeaderCard extends ConsumerWidget {
  const _BudgetHeaderCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final month = ref.watch(selectedBudgetMonthProvider);
    final summary =
        ref.watch(budgetSummaryProvider((month.year, month.month)));
    final rollover =
        ref.watch(budgetRolloverBalanceProvider((month.year, month.month)));
    final visible = ref.watch(budgetBalanceVisibleProvider);
    final currency = ref.watch(currencySymbolProvider);

    return Container(
      margin: EdgeInsets.fromLTRB(bs(16), bs(2), bs(16), bs(9)),
      padding: EdgeInsets.all(bs(14)),
      decoration: BoxDecoration(
        gradient: TraumColors.gradientHero,
        borderRadius: BorderRadius.circular(bs(18)),
        border: Border.all(
            color: TraumColors.amberGold.withValues(alpha: 0.18), width: bs(1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Verfügbar + Verbergen-Pill
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n.budgetAvailableThisMonth,
                  style: _style(
                      11, FontWeight.w400, TraumColors.onBackgroundMuted)),
              const Spacer(),
              GestureDetector(
                onTap: () => ref
                    .read(budgetBalanceVisibleProvider.notifier)
                    .state = !visible,
                child: Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: bs(8), vertical: bs(5)),
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(bs(16)),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(
                      visible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: TraumColors.onBackgroundMuted,
                      size: bs(11),
                    ),
                    SizedBox(width: bs(4)),
                    Text(
                        visible
                            ? l10n.budgetHideAmountAction
                            : l10n.budgetShowAmountAction,
                        style: _style(10, FontWeight.w600,
                            TraumColors.onBackgroundMuted)),
                  ]),
                ),
              ),
            ],
          ),
          SizedBox(height: bs(4)),
          rollover.when(
            data: (balance) => HiddenAmount(
              child: Text(
                '${balance < 0 ? '−' : ''}${_fmt(balance)} $currency',
                style: _style(
                  34,
                  FontWeight.w700,
                  balance >= 0
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
          SizedBox(height: bs(3)),
          summary.when(
            data: (s) => rollover.when(
              data: (balance) => _prognoseRow(s, balance, month, currency, l10n),
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
            loading: () => const SizedBox.shrink(),
            error: (_, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: bs(10)),
          // Einnahmen / Ausgaben / Sparquote
          summary.when(
            data: (s) => Row(children: [
              _MiniStat(
                dotColor: TraumColors.mintGreen,
                label: l10n.budgetIncome,
                value: '${_fmt(s.income)} $currency',
                valueColor: TraumColors.mintGreen,
              ),
              SizedBox(width: bs(5)),
              _MiniStat(
                dotColor: TraumColors.roseRed,
                label: l10n.budgetExpenses,
                value: '${_fmt(s.expenses)} $currency',
                valueColor: TraumColors.roseRed,
              ),
              SizedBox(width: bs(5)),
              _MiniStat(
                dotColor: TraumColors.amberGold,
                label: l10n.budgetSavingsRate,
                value: s.income > 0
                    ? '${((s.income - s.expenses) / s.income * 100).toStringAsFixed(0)} %'
                    : '0 %',
                valueColor: TraumColors.amberGold,
              ),
            ]),
            loading: () => SizedBox(height: bs(48)),
            error: (_, _) => const SizedBox.shrink(),
          ),
          SizedBox(height: bs(10)),
          // Gesamtsaldo-Footer
          const _GesamtsaldoFooter(),
        ],
      ),
    );
  }

  Widget _prognoseRow(BudgetSummary s, double balance, DateTime month,
      String currency, AppLocalizations l10n) {
    final now = DateTime.now();
    if (now.month != month.month || now.year != month.year) {
      return const SizedBox.shrink();
    }
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    if (now.day < 5) {
      return Text(l10n.budgetDayOfMonth(now.day, daysInMonth),
          style: _style(10, FontWeight.w400, TraumColors.onBackgroundMuted));
    }
    final daily = s.expenses / now.day;
    final forecast = balance - daily * (daysInMonth - now.day);
    return Row(children: [
      Text(l10n.budgetDayOfMonthForecast(now.day, daysInMonth),
          style: _style(10, FontWeight.w400, TraumColors.onBackgroundMuted)),
      HiddenAmount(
        child: Text(
            l10n.budgetForecastRemaining('${_fmt(forecast)} $currency'),
            style: _style(10, FontWeight.w600, TraumColors.textBright)),
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

// ─── Monats-Pillen-Header (fix, KEIN Sliver — siehe Kommentar in build()) ─────

class _BudgetHeader extends StatelessWidget {
  const _BudgetHeader();

  @override
  Widget build(BuildContext context) {
    return Padding( // ← Padding statt Container — KEIN Hintergrund!
      padding: EdgeInsets.fromLTRB(bs(16), bs(8), bs(16), bs(4)),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            AppLocalizations.of(context)!.budget,
            style: _style(20, FontWeight.w700), // ← 20px wie im HTML
          ),
          const Spacer(),
          // Pille hat eigenen Hintergrund — schwebt transparent über Content
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
      padding: EdgeInsets.symmetric(horizontal: bs(5), vertical: bs(4)),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(bs(20)),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        _NavBtn(
          icon: Icons.chevron_left,
          onTap: () => ref.read(selectedBudgetMonthProvider.notifier).state =
              DateTime(month.year, month.month - 1),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: bs(10)),
          child: SizedBox(
            width: bs(56),
            child: Text(
              _monthYear(month),
              style: _style(12, FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ),
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
    final l10n = AppLocalizations.of(context)!;
    final balance = ref.watch(totalAccountBalanceProvider);
    final change = ref.watch(monthlyBalanceChangeProvider);
    final month = ref.watch(selectedBudgetMonthProvider);
    final spots =
        ref.watch(dailyBalanceSpotsProvider((month.year, month.month)));
    final currency = ref.watch(currencySymbolProvider);

    return Container(
      padding: EdgeInsets.only(top: bs(10)),
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
              Text(l10n.budgetTotalBalanceAllAccounts,
                  style: _style(
                      9, FontWeight.w400, TraumColors.onBackgroundMuted)),
              SizedBox(height: bs(1)),
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
                SizedBox(width: bs(6)),
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
            width: bs(68),
            height: bs(26),
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
          barWidth: bs(1.8),
          dotData: FlDotData(
            getDotPainter: (spot, _, _, index) => index == spots.length - 1
                ? FlDotCirclePainter(
                    radius: bs(2.5),
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
    final l10n = AppLocalizations.of(context)!;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: EdgeInsets.fromLTRB(bs(16), 0, bs(16), bs(8)),
      child: Row(children: [
        _QuickChip(
          label: l10n.budgetSavingGoals,
          icon: Icons.layers_rounded,
          color: TraumColors.amberGold,
          onTap: () => context.push(Routes.savings),
        ),
        SizedBox(width: bs(6)),
        _QuickChip(
          label: l10n.budgetTransactions,
          icon: Icons.receipt_long_rounded,
          color: TraumColors.cyanBlue,
          onTap: () => context.push(Routes.transactionList),
        ),
        SizedBox(width: bs(6)),
        _QuickChip(
          label: l10n.budgetRecurringLabel,
          icon: Icons.repeat_rounded,
          color: TraumColors.indigoBlue,
          onTap: () => context.push(Routes.recurring),
        ),
        SizedBox(width: bs(6)),
        _QuickChip(
          label: l10n.budgetDebts,
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
          padding: EdgeInsets.symmetric(horizontal: bs(10), vertical: bs(7)),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(bs(10)),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, color: color, size: bs(12)),
            SizedBox(width: bs(5)),
            Text(label, style: _style(10, FontWeight.w600)),
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
          padding: EdgeInsets.symmetric(horizontal: bs(9), vertical: bs(8)),
          decoration: BoxDecoration(
            color: TraumColors.heroInner,
            borderRadius: BorderRadius.circular(bs(10)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(
                  width: bs(5),
                  height: bs(5),
                  decoration:
                      BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                SizedBox(width: bs(4)),
                Flexible(
                  child: Text(label,
                      style: _style(
                          9, FontWeight.w400, TraumColors.onBackgroundMuted),
                      overflow: TextOverflow.ellipsis),
                ),
              ]),
              SizedBox(height: bs(2)),
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
    final l10n = AppLocalizations.of(context)!;
    final txs = ref.watch(recentTransactionItemsProvider(5));
    final currency = ref.watch(currencySymbolProvider);

    return _Card(
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Text(l10n.budgetRecentTransactions,
                  style: _style(13, FontWeight.w600)),
              const Spacer(),
              GestureDetector(
                onTap: () => context.go('/budget/transactions'),
                child: Text(l10n.budgetSeeAll,
                    style: _style(
                        11, FontWeight.w500, TraumColors.amberGold)),
              ),
            ]),
            SizedBox(height: bs(8)),
            txs.when(
              data: (list) {
                if (list.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.symmetric(vertical: bs(20)),
                    child: Center(
                      child: Column(children: [
                        Icon(Icons.receipt_long_outlined,
                            color: TraumColors.onBackgroundSubtle,
                            size: bs(32)),
                        SizedBox(height: bs(8)),
                        Text(l10n.budgetNoTransactionsYet,
                            style: _style(13, FontWeight.w400,
                                TraumColors.onBackgroundMuted)),
                        SizedBox(height: bs(4)),
                        Text(l10n.budgetNoTransactionsHint,
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

                    final timeLabel = _dateLabel(tx.date, l10n);
                    return Column(children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Container(
                          width: bs(34),
                          height: bs(34),
                          decoration: BoxDecoration(
                            color: catColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(bs(9)),
                          ),
                          child: Center(
                            child: _catIcon(
                                tx.category?.emoji, catColor, bs(14)),
                          ),
                        ),
                        title: Text(tx.name,
                            style: _style(11, FontWeight.w600)),
                        subtitle: Text(
                            '${tx.categoryName} · $timeLabel',
                            style: _style(9, FontWeight.w400,
                                TraumColors.onBackgroundMuted)),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            HiddenAmount(
                              child: Text(
                                  '$prefix$currency${_fmt(tx.amount.abs())}',
                                  style: _style(
                                      11, FontWeight.w700, amountColor)),
                            ),
                            SizedBox(width: bs(2)),
                            Icon(Icons.chevron_right_rounded,
                                size: bs(12),
                                color: TraumColors.onBackgroundSubtle),
                          ],
                        ),
                        onTap: () => context
                            .go('/budget/transaction/${tx.tx.id}'),
                      ),
                      if (i < list.length - 1)
                        Divider(
                            height: bs(1),
                            color: Colors.white.withValues(alpha: 0.05)),
                    ]);
                  }).toList(),
                );
              },
              loading: () => SizedBox(
                height: bs(80),
                child: const Center(
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

  String _dateLabel(DateTime date, AppLocalizations l10n) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = DateTime(date.year, date.month, date.day);
    if (d == today) return l10n.today;
    if (d == today.subtract(const Duration(days: 1))) return l10n.yesterday;
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
        margin: EdgeInsets.symmetric(horizontal: bs(16), vertical: bs(6)),
        padding: EdgeInsets.all(bs(13)),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(bs(16)),
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
        child: Container(
          width: bs(26),
          height: bs(26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(bs(13)),
          ),
          child: Icon(icon, color: Colors.white, size: bs(14)),
        ),
      );
}

String _fmt(double v) => v
    .abs()
    .toStringAsFixed(2)
    .replaceAll('.', ',')
    .replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+,)'), (m) => '${m[1]}.');

Widget _catIcon(String? emojiOrIcon, Color color, double size) =>
    budgetCategoryGlyph(emojiOrIcon, color: color, size: size);

