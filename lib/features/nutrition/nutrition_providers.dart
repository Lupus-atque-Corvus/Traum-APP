import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../data/database/traum_database.dart';
import 'food_api/food_source.dart';
import 'food_api/multi_source_search_service.dart';
import 'food_api/open_food_facts_source.dart';
import 'food_api/usda_source.dart';
import 'micro_nutrients.dart';

// ─── Models ──────────────────────────────────────────────────────────────────

class MacroSummary {
  final double calories;
  final double protein;
  final double carbs;
  final double fat;

  const MacroSummary({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  static const empty =
      MacroSummary(calories: 0, protein: 0, carbs: 0, fat: 0);
}

class DailyCalories {
  final DateTime date;
  final double calories;
  const DailyCalories({required this.date, required this.calories});
}

// ─── Selected Date ────────────────────────────────────────────────────────────

final selectedNutritionDateProvider =
    StateProvider<DateTime>((_) => DateTime.now());

// ─── Water Today ──────────────────────────────────────────────────────────────

final waterTodayProvider = StreamProvider.autoDispose<int>((ref) {
  final today = DateTime.now();
  return ref
      .watch(nutritionDaoProvider)
      .watchWaterForDate(today)
      .map((logs) => logs.fold<int>(0, (sum, l) => sum + l.amountMl));
});

// ─── Today's Meals Grouped ───────────────────────────────────────────────────

final todaysMealsProvider = FutureProvider.autoDispose
    .family<Map<String, List<MealEntry>>, String>((ref, dateStr) async {
  final entries =
      await ref.watch(mealEntriesDaoProvider).getForDate(dateStr);
  return {
    'breakfast':
        entries.where((e) => e.mealType == 'breakfast').toList(),
    'lunch': entries.where((e) => e.mealType == 'lunch').toList(),
    'dinner': entries.where((e) => e.mealType == 'dinner').toList(),
    'snack': entries.where((e) => e.mealType == 'snack').toList(),
  };
});

// ─── Today's Macros ──────────────────────────────────────────────────────────

final todaysMacrosProvider = FutureProvider.autoDispose
    .family<MacroSummary, String>((ref, dateStr) async {
  final meals = await ref.watch(todaysMealsProvider(dateStr).future);
  final all = meals.values.expand((e) => e).toList();
  return MacroSummary(
    calories: all.fold(0.0, (s, e) => s + e.calories),
    protein: all.fold(0.0, (s, e) => s + e.protein),
    carbs: all.fold(0.0, (s, e) => s + e.carbs),
    fat: all.fold(0.0, (s, e) => s + e.fat),
  );
});

// ─── Weekly Calories ─────────────────────────────────────────────────────────

final weeklyCaloriesProvider =
    FutureProvider.autoDispose<List<DailyCalories>>((ref) async {
  final dao = ref.watch(mealEntriesDaoProvider);
  final now = DateTime.now();
  final result = <DailyCalories>[];
  for (int i = 6; i >= 0; i--) {
    final day = now.subtract(Duration(days: i));
    final dateStr =
        '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
    final entries = await dao.getForDate(dateStr);
    final total = entries.fold(0.0, (s, e) => s + e.calories);
    result.add(DailyCalories(date: day, calories: total));
  }
  return result;
});

// ─── Product Search ───────────────────────────────────────────────────────────

final productSearchQueryProvider = StateProvider<String>((_) => '');

final productSearchProvider =
    FutureProvider.autoDispose<List<FoodProduct>>((ref) async {
  final query = ref.watch(productSearchQueryProvider);
  final dao = ref.watch(foodProductsDaoProvider);
  if (query.isEmpty) return dao.getRecent(limit: 20);
  return dao.search(query);
});

// ─── Recent Products ──────────────────────────────────────────────────────────

final recentProductsProvider =
    FutureProvider.autoDispose<List<FoodProduct>>((ref) =>
        ref.watch(foodProductsDaoProvider).getRecent(limit: 10));

// ─── All Products ─────────────────────────────────────────────────────────────

final allProductsProvider =
    FutureProvider.autoDispose<List<FoodProduct>>((ref) async {
  final dao = ref.watch(foodProductsDaoProvider);
  final custom = await dao.getAllCustom();
  final recent = await dao.getRecent(limit: 50);
  final customIds = custom.map((p) => p.id).toSet();
  final others =
      recent.where((p) => !customIds.contains(p.id)).toList();
  return [...custom, ...others];
});

// ─── Multi-Source Search ─────────────────────────────────────────────────────

/// Service, der die lokale Produkt-DB + alle externen [FoodSource]s
/// (OpenFoodFacts, USDA) zusammen abfragt und rankt (Task 6.4).
final multiSourceSearchServiceProvider =
    Provider<MultiSourceSearchService>((ref) {
  final prefs = ref.watch(preferencesRepositoryProvider);
  return MultiSourceSearchService(
    [OpenFoodFactsSource(), UsdaSource(prefs)],
    ref.watch(foodProductsDaoProvider),
  );
});

/// Debounced (400ms, siehe UI) Suchbegriff für die Multi-Source-Suche.
final multiSourceSearchQueryProvider =
    StateProvider.autoDispose<String>((_) => '');

final multiSourceSearchProvider =
    FutureProvider.autoDispose<List<FoodSearchResult>>((ref) async {
  final query = ref.watch(multiSourceSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  return ref.watch(multiSourceSearchServiceProvider).search(query);
});

/// Live-Konnektivitätsstatus (true = offline). Erster Wert kommt aus einer
/// einmaligen Prüfung, danach folgen Änderungen über den Connectivity-Stream.
final isOfflineProvider = StreamProvider.autoDispose<bool>((ref) async* {
  final connectivity = Connectivity();
  yield _isOffline(await connectivity.checkConnectivity());
  yield* connectivity.onConnectivityChanged.map(_isOffline);
});

bool _isOffline(List<ConnectivityResult> results) =>
    results.isEmpty || results.every((r) => r == ConnectivityResult.none);

// ─── Home Widget Helpers ────────────────────────────────────────────────────

/// Today's meal entries (one-shot query, ordered asc by loggedAt).
final todaysMealEntriesProvider =
    FutureProvider.autoDispose<List<MealEntry>>((ref) {
  final dateStr = formatDateStr(DateTime.now());
  return ref.watch(mealEntriesDaoProvider).getForDate(dateStr);
});

/// Today's nutrition totals derived from today's meal entries.
final todaysTotalsProvider =
    FutureProvider.autoDispose<MacroSummary>((ref) async {
  final entries = await ref.watch(todaysMealEntriesProvider.future);
  if (entries.isEmpty) return MacroSummary.empty;
  return MacroSummary(
    calories: entries.fold(0.0, (s, e) => s + e.calories),
    protein: entries.fold(0.0, (s, e) => s + e.protein),
    carbs: entries.fold(0.0, (s, e) => s + e.carbs),
    fat: entries.fold(0.0, (s, e) => s + e.fat),
  );
});

/// Name + time of the most recent meal entry logged today.
class LastMealInfo {
  final String name;
  final DateTime loggedAt;
  const LastMealInfo({required this.name, required this.loggedAt});
}

final lastMealProvider =
    FutureProvider.autoDispose<LastMealInfo?>((ref) async {
  final entries = await ref.watch(todaysMealEntriesProvider.future);
  if (entries.isEmpty) return null;
  // Ordered asc by loggedAt → last element is most recent.
  final latest = entries.last;
  final product =
      await ref.watch(foodProductsDaoProvider).getById(latest.productId);
  return LastMealInfo(
    name: product?.name ?? '—',
    loggedAt: latest.loggedAt,
  );
});

/// Count of supplements taken today (one-shot query).
final supplementsTakenTodayProvider =
    FutureProvider.autoDispose<int>((ref) {
  return ref.watch(supplementDaoProvider).getTakenCountToday();
});

/// Today's total water in ml as a one-shot query. Unlike [waterTodayProvider]
/// (a live drift `.watch()` stream used on the nutrition screen), this avoids a
/// lingering query-stream close timer — safe for home widgets and tests.
final waterTodaySnapshotProvider =
    FutureProvider.autoDispose<int>((ref) async {
  final logs = await ref
      .watch(nutritionDaoProvider)
      .getWaterLogsAfter(DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      ));
  return logs.fold<int>(0, (sum, l) => sum + l.amountMl);
});

// ─── Micros ───────────────────────────────────────────────────────────────────

/// Mikros eines Produkts pro 100 g (erweiterte Spalten + Panel-JSON).
MicroNutrients productMicrosPer100g(FoodProduct p) {
  final base = <String, double>{};
  if (p.sugarPer100g != null) base['sugar'] = p.sugarPer100g!;
  if (p.fiberPer100g != null) base['fiber'] = p.fiberPer100g!;
  if (p.saturatedFatPer100g != null) base['satFat'] = p.saturatedFatPer100g!;
  if (p.saltPer100g != null) base['salt'] = p.saltPer100g!;
  return MicroNutrients(base) + MicroNutrients.fromJson(p.microsJson);
}

// ─── Supplement-Logs heute ────────────────────────────────────────────────────

final supplementLogsTodayProvider =
    StreamProvider.autoDispose<List<SupplementLog>>((ref) {
  return ref.watch(supplementDaoProvider).watchLogsForDate(DateTime.now());
});

// ─── Tages-Mikronährstoffe ────────────────────────────────────────────────────

/// Σ Mikros aller heutigen Meal-Einträge + Σ Beiträge heute abgehakter Supplements.
final dailyMicrosProvider = FutureProvider.autoDispose
    .family<MicroNutrients, String>((ref, dateStr) async {
  // Meal entries
  final entries =
      await ref.watch(mealEntriesDaoProvider).getForDate(dateStr);
  var total = MicroNutrients.empty;
  for (final e in entries) {
    total = total + MicroNutrients.fromJson(e.microsJson);
  }

  // Checked supplements (today)
  final logs = await ref.watch(supplementLogsTodayProvider.future);
  if (logs.isNotEmpty) {
    final supps =
        await ref.watch(supplementDaoProvider).watchAllSupplements().first;
    final byId = {for (final s in supps) s.id: s};
    final countedIds = <int>{};
    for (final log in logs) {
      if (!countedIds.add(log.supplementId)) continue; // pro Supplement 1×
      final s = byId[log.supplementId];
      if (s == null) continue;
      total = total +
          supplementContribution(
            nutrientKey: s.nutrientKey,
            dosageAmount: s.dosageAmount,
            dosageUnit: s.dosageUnit,
          );
    }
  }
  return total;
});

/// Name eines Produkts per ID (für Meal-Eintragszeilen).
final productNameProvider =
    FutureProvider.autoDispose.family<String, int>((ref, productId) async {
  final p = await ref.watch(foodProductsDaoProvider).getById(productId);
  return p?.name ?? 'Unbekannt';
});

// ─── Helper ───────────────────────────────────────────────────────────────────

String formatDateStr(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
