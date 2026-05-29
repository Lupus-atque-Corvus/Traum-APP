import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'add_custom_product_screen.dart';
import 'barcode_scanner_screen.dart';
import 'nutrition_providers.dart';
import 'widgets/macro_ring_row.dart';
import 'widgets/meal_section.dart';
import 'widgets/weekly_bar_chart.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() =>
      _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final dateStr = formatDateStr(today);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, _) => [
          SliverToBoxAdapter(
            child: Column(children: [
              SizedBox(
                  height:
                      MediaQuery.of(ctx).padding.top + 8),
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(20, 0, 16, 0),
                child: Row(children: [
                  const Text('Ernährung',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          color: TraumColors.onBackground,
                          fontSize: 24)),
                ]),
              ),
              const SizedBox(height: 8),
              _PillTabs(controller: _tabs),
              const SizedBox(height: 4),
            ]),
          ),
        ],
        body: TabBarView(
          controller: _tabs,
          children: [
            _TodayTab(dateStr: dateStr),
            const _WeekTab(),
            const _ProductsTab(),
            const _ShoppingTab(),
          ],
        ),
      ),
    );
  }
}

// ─── Pill Tab Bar ─────────────────────────────────────────

class _PillTabs extends StatelessWidget {
  final TabController controller;
  const _PillTabs({required this.controller});

  @override
  Widget build(BuildContext context) {
    const labels = ['Heute', 'Woche', 'Produkte', 'Einkauf'];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(50),
      ),
      child: TabBar(
        controller: controller,
        indicator: BoxDecoration(
          color: TraumColors.mintGreen,
          borderRadius: BorderRadius.circular(50),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: TraumColors.onBackgroundMuted,
        labelStyle: const TextStyle(
            fontFamily: 'DMSans',
            fontSize: 13,
            fontWeight: FontWeight.w600),
        tabs: labels.map((l) => Tab(text: l)).toList(),
      ),
    );
  }
}

// ─── Tab 1: Heute ────────────────────────────────────────

class _TodayTab extends ConsumerWidget {
  final String dateStr;
  const _TodayTab({required this.dateStr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealsAsync = ref.watch(todaysMealsProvider(dateStr));
    final macrosAsync = ref.watch(todaysMacrosProvider(dateStr));
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);
    final proteinGoal = ref.watch(proteinGoalNotifierProvider);
    final now = DateTime.now();
    final todayDate =
        DateTime(now.year, now.month, now.day);
    final waterAsync =
        ref.watch(waterForDateProvider(todayDate));

    return ListView(
      padding: const EdgeInsets.only(bottom: 100),
      children: [
        // Macro header
        Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: macrosAsync.when(
            data: (macros) => Column(children: [
              Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_dayLabel(),
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w600,
                            color: TraumColors.onBackground,
                            fontSize: 14)),
                    Text(
                        '${macros.calories.toStringAsFixed(0)} / $kcalGoal kcal',
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.mintGreen,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                  ]),
              const SizedBox(height: 16),
              MacroRingRow(
                calories: macros.calories,
                caloriesGoal: kcalGoal.toDouble(),
                protein: macros.protein,
                proteinGoal: proteinGoal.toDouble(),
                carbs: macros.carbs,
                carbsGoal: 250,
                fat: macros.fat,
                fatGoal: 70,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value:
                      (macros.calories / kcalGoal)
                          .clamp(0.0, 1.0)
                          .toDouble(),
                  minHeight: 6,
                  backgroundColor: TraumColors.surfaceVariant,
                  valueColor: const AlwaysStoppedAnimation(
                      TraumColors.mintGreen),
                ),
              ),
            ]),
            loading: () => const SizedBox(
                height: 80,
                child: Center(
                    child: CircularProgressIndicator(
                        color: TraumColors.mintGreen,
                        strokeWidth: 2))),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ),

        // Meal sections
        mealsAsync.when(
          data: (meals) => Column(children: [
            for (final type in [
              'breakfast',
              'lunch',
              'dinner',
              'snack'
            ])
              MealSection(
                mealType: type,
                date: dateStr,
                entries: meals[type] ?? [],
              ),
          ]),
          loading: () => const SizedBox(
              height: 100,
              child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.mintGreen,
                      strokeWidth: 2))),
          error: (_, __) => const SizedBox.shrink(),
        ),

        // Water section
        Container(
          margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  const Text('WASSER',
                      style: TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: TraumColors.cyanBlue,
                          letterSpacing: 0.8)),
                  const Spacer(),
                  waterAsync.when(
                    data: (logs) {
                      final total = logs.fold(
                          0, (s, l) => s + l.amountMl);
                      return Text('$total / 2500 ml',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.cyanBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.w500));
                    },
                    loading: () => const SizedBox.shrink(),
                    error: (_, __) => const SizedBox.shrink(),
                  ),
                ]),
                const SizedBox(height: 8),
                waterAsync.when(
                  data: (logs) {
                    final total =
                        logs.fold(0, (s, l) => s + l.amountMl);
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value:
                            (total / 2500).clamp(0.0, 1.0),
                        minHeight: 8,
                        backgroundColor:
                            TraumColors.surfaceVariant,
                        valueColor:
                            const AlwaysStoppedAnimation(
                                TraumColors.cyanBlue),
                      ),
                    );
                  },
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 10),
                Row(children: [
                  for (final ml in [200, 300, 500])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: OutlinedButton(
                        onPressed: () =>
                            _addWater(ref, ml),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: TraumColors.cyanBlue,
                          side: const BorderSide(
                              color: TraumColors.cyanBlue),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(50)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        child: Text('+${ml}ml',
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                fontSize: 12)),
                      ),
                    ),
                ]),
              ]),
        ),
      ],
    );
  }

  String _dayLabel() {
    final d = DateTime.now();
    const weekdays = [
      'Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'
    ];
    const months = [
      'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
      'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]}';
  }

  Future<void> _addWater(WidgetRef ref, int ml) async {
    await ref.read(nutritionDaoProvider).insertWaterLog(
          WaterLogsCompanion.insert(
            logDate: DateTime.now(),
            amountMl: ml,
          ),
        );
    ref.invalidate(waterForDateProvider);
  }
}

// ─── Tab 2: Woche ────────────────────────────────────────

class _WeekTab extends ConsumerWidget {
  const _WeekTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weeklyAsync = ref.watch(weeklyCaloriesProvider);
    final kcalGoal = ref.watch(kcalGoalNotifierProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Wochenverlauf',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        color: TraumColors.onBackground,
                        fontSize: 16)),
                const SizedBox(height: 12),
                weeklyAsync.when(
                  data: (data) {
                    final avg = data.isEmpty
                        ? 0.0
                        : data.fold(0.0,
                                (s, d) => s + d.calories) /
                            data.length;
                    return Column(children: [
                      WeeklyBarChart(
                          data: data, kcalGoal: kcalGoal),
                      const SizedBox(height: 12),
                      Text(
                          'Ø ${avg.toStringAsFixed(0)} kcal / Tag',
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color:
                                  TraumColors.onBackgroundMuted,
                              fontSize: 13)),
                    ]);
                  },
                  loading: () => const Center(
                      child: CircularProgressIndicator(
                          color: TraumColors.mintGreen,
                          strokeWidth: 2)),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ]),
        ),
      ],
    );
  }
}

// ─── Tab 3: Produkte ─────────────────────────────────────

class _ProductsTab extends ConsumerStatefulWidget {
  const _ProductsTab();

  @override
  ConsumerState<_ProductsTab> createState() =>
      _ProductsTabState();
}

class _ProductsTabState extends ConsumerState<_ProductsTab> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() {
      ref.read(productSearchQueryProvider.notifier).state =
          _searchCtrl.text.trim();
    });
  }

  @override
  void dispose() {
    ref.read(productSearchQueryProvider.notifier).state = '';
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final productsAsync = ref.watch(productSearchProvider);

    return Column(children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: _searchCtrl,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackground,
                  fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Lebensmittel suchen...',
                hintStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundSubtle),
                prefixIcon: const Icon(Icons.search,
                    color: TraumColors.onBackgroundMuted),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner,
                color: TraumColors.mintGreen),
            onPressed: () async {
              await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          const BarcodeScannerScreen()));
              ref.invalidate(productSearchProvider);
            },
          ),
        ]),
      ),
      Expanded(
        child: productsAsync.when(
          data: (products) {
            if (products.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.search_off,
                        color: TraumColors.onBackgroundSubtle,
                        size: 48),
                    const SizedBox(height: 12),
                    const Text('Keine Produkte gefunden',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color:
                                TraumColors.onBackgroundMuted)),
                    const SizedBox(height: 16),
                    TextButton.icon(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const AddCustomProductScreen())).then((_) =>
                          ref.invalidate(productSearchProvider)),
                      icon: const Icon(Icons.add,
                          color: TraumColors.mintGreen),
                      label: const Text(
                          'Eigenes Produkt anlegen',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.mintGreen)),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              itemCount: products.length,
              itemBuilder: (_, i) {
                final p = products[i];
                return ListTile(
                  title: Text(p.name,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackground,
                          fontWeight: FontWeight.w500)),
                  subtitle: Text(
                      '${p.caloriesPer100g.toStringAsFixed(0)} kcal · '
                      '${p.proteinPer100g.toStringAsFixed(0)}g P · '
                      '${p.carbsPer100g.toStringAsFixed(0)}g C · '
                      '${p.fatPer100g.toStringAsFixed(0)}g F / 100g',
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          color: TraumColors.onBackgroundMuted,
                          fontSize: 11)),
                );
              },
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: TraumColors.mintGreen,
                  strokeWidth: 2)),
          error: (_, __) => const SizedBox.shrink(),
        ),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) =>
                        const AddCustomProductScreen())).then(
                (_) => ref.invalidate(productSearchProvider)),
            icon: const Icon(Icons.add,
                color: TraumColors.mintGreen),
            label: const Text('Eigenes Produkt anlegen',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.mintGreen)),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(
                  color: TraumColors.mintGreen),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(50)),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ),
    ]);
  }
}

// ─── Tab 4: Einkauf ─────────────────────────────────────

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync =
        ref.watch(allShoppingItemsStreamProvider);

    return itemsAsync.when(
      data: (items) {
        if (items.isEmpty) {
          return const Center(
            child: Text('Einkaufsliste ist leer',
                style: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundMuted)),
          );
        }

        final grouped = <String, List<ShoppingListItem>>{};
        for (final item in items) {
          final cat = item.category ?? 'Sonstiges';
          grouped.putIfAbsent(cat, () => []).add(item);
        }

        return ListView(
          padding:
              const EdgeInsets.fromLTRB(16, 8, 16, 100),
          children: grouped.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    entry.key.toUpperCase(),
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: TraumColors.mintGreen,
                        letterSpacing: 0.8),
                  ),
                ),
                ...entry.value.map((item) => Dismissible(
                      key: ValueKey(item.id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding:
                            const EdgeInsets.only(right: 16),
                        color: TraumColors.roseRed
                            .withValues(alpha: 0.15),
                        child: const Icon(
                            Icons.delete_outline,
                            color: TraumColors.roseRed),
                      ),
                      onDismissed: (_) => ref
                          .read(nutritionDaoProvider)
                          .deleteShoppingItem(item.id),
                      child: CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: item.checked,
                        activeColor: TraumColors.mintGreen,
                        checkColor: Colors.white,
                        title: Text(item.name,
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                color: item.checked
                                    ? TraumColors
                                        .onBackgroundSubtle
                                    : TraumColors.onBackground,
                                decoration: item.checked
                                    ? TextDecoration
                                        .lineThrough
                                    : null)),
                        subtitle: item.quantity != null
                            ? Text(
                                '${item.quantity} ${item.unit ?? 'g'}',
                                style: const TextStyle(
                                    fontFamily: 'DMSans',
                                    color: TraumColors
                                        .onBackgroundMuted,
                                    fontSize: 12))
                            : null,
                        onChanged: (_) => ref
                            .read(nutritionDaoProvider)
                            .updateShoppingItem(
                              ShoppingListItemsCompanion(
                                id: Value(item.id),
                                checked: Value(!item.checked),
                              ),
                            ),
                      ),
                    )),
              ],
            );
          }).toList(),
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen, strokeWidth: 2)),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}
