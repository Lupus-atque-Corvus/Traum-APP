import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../data/database/traum_database.dart';

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

// ─── Helper ───────────────────────────────────────────────────────────────────

String formatDateStr(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
