import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'budget_providers.dart';
import 'quick_entry_bottom_sheet.dart';
import 'widgets/accounts_card.dart';
import 'widgets/balance_card.dart';
import 'widgets/budget_header_card.dart';
import 'widgets/budget_overview_card.dart';
import 'widgets/category_list_card.dart';
import 'widgets/donut_chart_card.dart';
import 'widgets/fixed_costs_card.dart';
import 'widgets/quick_template_row.dart';
import 'widgets/recent_transactions_card.dart';
import 'widgets/savings_card.dart';
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
                // 1. Month navigation + transaction-based balance
                const BudgetHeaderCard(),
                const SizedBox(height: 12),

                // 2. Gesamtsaldo (account totals + area chart)
                const BalanceCard(),
                const SizedBox(height: 12),

                // 3. Konten
                const AccountsCard(),
                const SizedBox(height: 16),

                // 4. Quick templates
                QuickTemplateRow(
                  onTemplateTap: (t) =>
                      _openQuickEntry(context, ref, template: t),
                  onNewTap: () => _openQuickEntry(context, ref),
                ),
                const SizedBox(height: 16),

                // 5. Budgetübersicht mit Fortschrittsbalken
                const BudgetOverviewCard(),
                const SizedBox(height: 16),

                // 6. Donut chart
                categoryExpAsync.when(
                  data: (expenses) => DonutChartCard(
                    expenses: expenses,
                    currency: currency,
                    onSegmentTap: (catName) {
                      ref.read(selectedCategoryNameProvider.notifier).state =
                          catName;
                      ref.read(trendBarDateRangeProvider.notifier).state =
                          null;
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 16),

                // 7. Kategorie-Listen-Ansicht
                const CategoryListCard(),
                const SizedBox(height: 16),

                // 8. Verlaufs-Diagramm
                const TrendBarChart(),
                const SizedBox(height: 16),

                // 9. Letzte Transaktionen
                const RecentTransactionsCard(),
                const SizedBox(height: 16),

                // 10. Fixkosten
                FixedCostsCard(currency: currency),
                const SizedBox(height: 16),

                // 11. Sparziele & Schulden
                SavingsCard(currency: currency),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
