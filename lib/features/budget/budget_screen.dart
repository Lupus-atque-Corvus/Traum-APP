import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'budget_providers.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/budget_ampel.dart';
import 'widgets/budget_header_card.dart';
import 'widgets/category_grid.dart';
import 'widgets/donut_chart_card.dart';
import 'widgets/fixed_costs_card.dart';
import 'widgets/quick_template_row.dart';
import 'widgets/savings_card.dart';
import 'widgets/transaction_list.dart';
import 'widgets/trend_bar_chart.dart';
import 'package:go_router/go_router.dart';

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  void _openQuickEntry(BuildContext context, WidgetRef ref,
      {QuickTemplate? template}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => QuickEntryBottomSheet(initialTemplate: template),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final month = ref.watch(selectedBudgetMonthProvider);
    final ym = (month.year, month.month);
    final currency = ref.watch(currencySymbolProvider);

    final txAsync = ref.watch(transactionsForMonthProvider(ym));
    final catsAsync = ref.watch(allBudgetCategoriesStreamProvider);
    final summaryAsync = ref.watch(budgetSummaryProvider(ym));
    final categoryExpAsync = ref.watch(categoryExpensesProvider(ym));

    return Scaffold(
      backgroundColor: TraumColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openQuickEntry(context, ref),
        backgroundColor: TraumColors.amberGold,
        label: const Text(
          '+',
          style: TextStyle(
            fontFamily: 'DMSans',
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 24,
          ),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            backgroundColor: TraumColors.background,
            floating: true,
            snap: true,
            elevation: 0,
            title: const Text(
              'Finanzen',
              style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined,
                    color: TraumColors.amberGold),
                onPressed: () {},
              ),
              IconButton(
                icon: const Icon(Icons.savings_rounded,
                    color: TraumColors.mintGreen),
                onPressed: () => context.go('/budget/savings'),
              ),
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded,
                    color: TraumColors.amberGold),
                onPressed: () => context.go('/budget/stats'),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Header card with balance, sparkline, month navigation
                const BudgetHeaderCard(),
                const SizedBox(height: 12),

                // Budget Ampel
                summaryAsync.when(
                  data: (summary) {
                    return catsAsync.when(
                      data: (cats) {
                        final totalBudget = cats
                            .where(
                                (c) => c.isExpense && c.monthlyLimit != null)
                            .fold(0.0, (s, c) => s + c.monthlyLimit!);
                        if (totalBudget <= 0) return const SizedBox.shrink();
                        return Column(children: [
                          BudgetAmpel(
                            totalBudget: totalBudget,
                            totalSpent: summary.expenses,
                            currency: currency,
                          ),
                          const SizedBox(height: 12),
                        ]);
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),

                // Quick templates row
                QuickTemplateRow(
                  onTemplateTap: (t) =>
                      _openQuickEntry(context, ref, template: t),
                  onNewTap: () => _openQuickEntry(context, ref),
                ),
                const SizedBox(height: 16),

                // Category grid
                txAsync.when(
                  data: (txs) => catsAsync.when(
                    data: (cats) => CategoryGrid(
                      categories: cats,
                      transactions: txs,
                      currency: currency,
                      onShowAll: () => context.go('/budget/stats'),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Donut chart
                categoryExpAsync.when(
                  data: (expenses) => DonutChartCard(
                    expenses: expenses,
                    currency: currency,
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Trend bar chart
                const TrendBarChart(),
                const SizedBox(height: 16),

                // Transaction list
                txAsync.when(
                  data: (txs) => catsAsync.when(
                    data: (cats) => TransactionList(
                      transactions: txs,
                      categories: cats,
                      currency: currency,
                      onTransactionTap: (t) =>
                          context.go('/budget/transaction/${t.id}'),
                    ),
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // Fixed costs
                FixedCostsCard(currency: currency),
                const SizedBox(height: 16),

                // Savings & Debts
                SavingsCard(currency: currency),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
