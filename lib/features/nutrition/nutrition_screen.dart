import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'add_custom_product_screen.dart';
import 'amount_entry_sheet.dart';
import 'barcode_scanner_screen.dart';
import 'food_api/food_source.dart';
import 'nutrition_providers.dart';
import 'widgets/macro_ring_row.dart';
import 'widgets/meal_section.dart';
import 'widgets/micro_nutrient_panel.dart';
import 'shopping/shopping_list_view.dart';
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
              MicroNutrientPanel(dateStr: dateStr),
            ]),
            loading: () => const SizedBox(
                height: 80,
                child: Center(
                    child: CircularProgressIndicator(
                        color: TraumColors.mintGreen,
                        strokeWidth: 2))),
            error: (_, _) => const SizedBox.shrink(),
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
          error: (_, _) => const SizedBox.shrink(),
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
                    error: (_, _) => const SizedBox.shrink(),
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
                  error: (_, _) => const SizedBox.shrink(),
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
                  error: (_, _) => const SizedBox.shrink(),
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

class _ProductsTabState extends ConsumerState<_ProductsTab>
    with AutomaticKeepAliveClientMixin {
  final _searchCtrl = TextEditingController();
  Timer? _debounce;

  // TabBarView disposes off-screen tabs by default — ohne KeepAlive würde ein
  // Tab-Wechsel weg von "Produkte" und zurück die Sucheingabe/den Controller
  // zerstören.
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final text = _searchCtrl.text.trim();
    // Lokale Liste reagiert sofort (billige SQLite-Query, kein Debounce
    // nötig); die Multi-Source-Suche (Netzwerk) wird debounced (400ms).
    ref.read(productSearchQueryProvider.notifier).state = text;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      ref.read(multiSourceSearchQueryProvider.notifier).state = text;
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    ref.read(productSearchQueryProvider.notifier).state = '';
    ref.read(multiSourceSearchQueryProvider.notifier).state = '';
    _searchCtrl.removeListener(_onSearchChanged);
    _searchCtrl.dispose();
    super.dispose();
  }

  String _defaultMealType() {
    final h = DateTime.now().hour;
    if (h < 10) return 'breakfast';
    if (h < 15) return 'lunch';
    if (h < 21) return 'dinner';
    return 'snack';
  }

  FoodProductsCompanion _toCompanion(FoodSearchResult r) =>
      FoodProductsCompanion.insert(
        name: r.name,
        brand: Value(r.brand),
        barcode: Value(r.barcode),
        imageUrl: Value(r.imageUrl),
        caloriesPer100g: r.kcalPer100g,
        proteinPer100g: r.proteinPer100g,
        carbsPer100g: r.carbsPer100g,
        fatPer100g: r.fatPer100g,
        sugarPer100g: Value(r.sugarPer100g),
        fiberPer100g: Value(r.fiberPer100g),
        saltPer100g: Value(r.saltPer100g),
        sourceApi: Value(r.source),
        sourceId: Value(r.sourceId),
        createdAt: DateTime.now(),
      );

  Future<void> _openAmountEntry(FoodProduct product) async {
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AmountEntrySheet(
        product: product,
        mealType: _defaultMealType(),
        date: formatDateStr(DateTime.now()),
      ),
    );
    ref.invalidate(productSearchProvider);
    ref.invalidate(recentProductsProvider);
    ref.invalidate(multiSourceSearchProvider);
  }

  /// Tap auf einen lokalen Produkt-Datensatz (Browse-Modus, kein Suchtext).
  void _handleLocalProductTap(FoodProduct product) {
    _openAmountEntry(product);
  }

  /// Tap auf einen Multi-Source-Suchtreffer: Treffer mit lokalem Ursprung
  /// (auch gemergte, siehe [FoodSearchResult.localId]) werden per ID
  /// zurückgeholt statt neu angelegt/upsertet — sonst würde ein gemergtes
  /// Ergebnis ohne Barcode (source='merged') fälschlich einen doppelten
  /// Datensatz erzeugen, statt das bestehende lokale Produkt zu verwenden.
  /// Rein online-basierte Treffer (kein `localId`) werden wie zuvor erst in
  /// der DB gecached (Task 6.4).
  Future<void> _handleSearchResultTap(FoodSearchResult result) async {
    final dao = ref.read(foodProductsDaoProvider);
    FoodProduct? product;
    if (result.localId != null) {
      product = await dao.getById(result.localId!);
    }
    product ??= await dao.upsertFromSource(_toCompanion(result));
    if (result.localId == null) {
      ref.invalidate(allProductsProvider);
    }
    await _openAmountEntry(product);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final l10n = AppLocalizations.of(context)!;
    final query = ref.watch(productSearchQueryProvider);
    final searchActive = query.trim().isNotEmpty;

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
        child: searchActive
            ? _MultiSourceResults(
                l10n: l10n,
                onTapResult: _handleSearchResultTap,
              )
            : _LocalProductsBrowse(
                onTapProduct: _handleLocalProductTap,
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

/// Browse-Modus (kein Suchtext): bekannte/zuletzt verwendete lokale
/// Produkte, unverändert gegenüber dem bisherigen Verhalten — jetzt mit
/// Tap-Handler, der den Mengen-Flow öffnet (vorher totes ListTile).
class _LocalProductsBrowse extends ConsumerWidget {
  final void Function(FoodProduct) onTapProduct;
  const _LocalProductsBrowse({required this.onTapProduct});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productsAsync = ref.watch(productSearchProvider);
    return productsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off,
                    color: TraumColors.onBackgroundSubtle, size: 48),
                const SizedBox(height: 12),
                const Text('Keine Produkte gefunden',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted)),
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
              trailing: const Icon(Icons.add_circle_outline,
                  color: TraumColors.mintGreen),
              onTap: () => onTapProduct(p),
            );
          },
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen, strokeWidth: 2)),
      error: (_, _) => const SizedBox.shrink(),
    );
  }
}

/// Aktiver Suchmodus (Task 6.4): Multi-Source-Ergebnisse zweigeteilt in
/// "Meine Lebensmittel" (lokal) und "Online gefunden" (OFF/USDA/Kombiniert)
/// mit Source-Badge, plus Offline-Hinweis.
class _MultiSourceResults extends ConsumerWidget {
  final AppLocalizations l10n;
  final Future<void> Function(FoodSearchResult) onTapResult;

  const _MultiSourceResults({
    required this.l10n,
    required this.onTapResult,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(multiSourceSearchProvider);
    final isOffline = ref.watch(isOfflineProvider).value ?? false;

    return resultsAsync.when(
      data: (results) {
        final local = results.where((r) => r.source == 'local').toList();
        final online = results.where((r) => r.source != 'local').toList();

        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_off,
                    color: TraumColors.onBackgroundSubtle, size: 48),
                const SizedBox(height: 12),
                const Text('Keine Produkte gefunden',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted)),
                if (isOffline) ...[
                  const SizedBox(height: 8),
                  Text(l10n.searchOffline,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontSize: 12,
                          color: TraumColors.onBackgroundSubtle)),
                ],
              ],
            ),
          );
        }

        return ListView(
          children: [
            if (isOffline)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 4, 16, 4),
                child: Row(children: [
                  const Icon(Icons.cloud_off,
                      size: 14, color: TraumColors.onBackgroundSubtle),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(l10n.searchOffline,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            color: TraumColors.onBackgroundSubtle)),
                  ),
                ]),
              ),
            if (local.isNotEmpty) ...[
              _SectionHeader(l10n.myFoodsSection),
              for (final r in local)
                _SearchResultTile(
                  result: r,
                  l10n: l10n,
                  onTap: () => onTapResult(r),
                ),
            ],
            if (online.isNotEmpty) ...[
              _SectionHeader(l10n.searchOnlineSection),
              for (final r in online)
                _SearchResultTile(
                  result: r,
                  l10n: l10n,
                  onTap: () => onTapResult(r),
                ),
            ],
          ],
        );
      },
      loading: () => const Center(
          child: CircularProgressIndicator(
              color: TraumColors.mintGreen, strokeWidth: 2)),
      error: (_, _) => Center(
        child: Text(l10n.searchOffline,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted)),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: TraumColors.onBackgroundSubtle,
              letterSpacing: 0.8),
        ),
      );
}

class _SearchResultTile extends StatelessWidget {
  final FoodSearchResult result;
  final AppLocalizations l10n;
  final VoidCallback onTap;

  const _SearchResultTile({
    required this.result,
    required this.l10n,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Row(children: [
        Expanded(
          child: Text(result.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackground,
                  fontWeight: FontWeight.w500)),
        ),
        if (result.source != 'local') ...[
          const SizedBox(width: 8),
          _SourceBadge(source: result.source, l10n: l10n),
        ],
      ]),
      subtitle: Text(
          '${result.kcalPer100g.toStringAsFixed(0)} kcal · '
          '${result.proteinPer100g.toStringAsFixed(0)}g P · '
          '${result.carbsPer100g.toStringAsFixed(0)}g C · '
          '${result.fatPer100g.toStringAsFixed(0)}g F / 100g'
          '${result.brand != null ? " · ${result.brand}" : ""}',
          style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 11)),
      trailing: const Icon(Icons.add_circle_outline,
          color: TraumColors.mintGreen),
      onTap: onTap,
    );
  }
}

/// Kompakter Farb-Chip je Quelle: `OFF` / `USDA` / `Kombiniert`, in der
/// cyanBlue/cyanDim-Farbfamilie (TraumColors).
class _SourceBadge extends StatelessWidget {
  final String source; // 'off' | 'usda' | 'merged'
  final AppLocalizations l10n;

  const _SourceBadge({required this.source, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final label = switch (source) {
      'off' => 'OFF',
      'usda' => 'USDA',
      'merged' => l10n.sourceMerged,
      _ => source.toUpperCase(),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: TraumColors.cyanDim,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: TraumColors.cyanBlue.withValues(alpha: 0.4)),
      ),
      child: Text(label,
          style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: TraumColors.cyanBlue)),
    );
  }
}

// ─── Tab 4: Einkauf ─────────────────────────────────────

class _ShoppingTab extends ConsumerWidget {
  const _ShoppingTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return const ShoppingListView();
  }
}
