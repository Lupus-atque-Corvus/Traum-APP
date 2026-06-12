import 'package:drift/drift.dart';
import '../traum_database.dart';
import '../../../core/services/grocery_price_service.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(tables: [
  NutritionLogs,
  MealTemplates,
  WaterLogs,
  ShoppingListItems,
  GroceryPrices,
  ShoppingTemplates,
  ShoppingTemplateItems,
])
class NutritionDao extends DatabaseAccessor<TraumDatabase>
    with _$NutritionDaoMixin {
  NutritionDao(super.db);

  // NutritionLogs
  Stream<List<NutritionLog>> watchLogsForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(nutritionLogs)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .watch();
  }

  Future<int> insertLog(NutritionLogsCompanion entry) =>
      into(nutritionLogs).insert(entry);

  Future<int> deleteLog(int id) =>
      (delete(nutritionLogs)..where((t) => t.id.equals(id))).go();

  Future<List<NutritionLog>> getNutritionLogsAfter(DateTime date) =>
      (select(nutritionLogs)..where((t) => t.logDate.isBiggerOrEqualValue(date)))
          .get();

  Future<List<WaterLog>> getWaterLogsAfter(DateTime date) =>
      (select(waterLogs)..where((t) => t.logDate.isBiggerOrEqualValue(date)))
          .get();

  // MealTemplates
  Stream<List<MealTemplate>> watchAllTemplates() =>
      select(mealTemplates).watch();

  Future<List<MealTemplate>> searchTemplates(String query) =>
      (select(mealTemplates)
            ..where((t) => t.name.like('%$query%')))
          .get();

  Future<int> insertTemplate(MealTemplatesCompanion entry) =>
      into(mealTemplates).insert(entry);

  Future<int> deleteTemplate(int id) =>
      (delete(mealTemplates)..where((t) => t.id.equals(id))).go();

  // WaterLogs
  Stream<List<WaterLog>> watchWaterForDate(DateTime date) {
    final start = DateTime(date.year, date.month, date.day);
    final end = start.add(const Duration(days: 1));
    return (select(waterLogs)
          ..where((t) =>
              t.logDate.isBiggerOrEqualValue(start) &
              t.logDate.isSmallerThanValue(end)))
        .watch();
  }

  Future<List<WaterLog>> getWaterLogsLast7Days() {
    final cutoff = DateTime.now().subtract(const Duration(days: 7));
    return (select(waterLogs)
          ..where((t) => t.logDate.isBiggerOrEqualValue(cutoff)))
        .get();
  }

  Future<int> insertWaterLog(WaterLogsCompanion entry) =>
      into(waterLogs).insert(entry);

  Future<int> deleteWaterLog(int id) =>
      (delete(waterLogs)..where((t) => t.id.equals(id))).go();

  // ShoppingListItems
  Stream<List<ShoppingListItem>> watchAllShoppingItems() =>
      select(shoppingListItems).watch();

  Future<int> insertShoppingItem(ShoppingListItemsCompanion entry) =>
      into(shoppingListItems).insert(entry);

  Future<bool> updateShoppingItem(ShoppingListItemsCompanion entry) =>
      update(shoppingListItems).replace(entry);

  Future<int> deleteShoppingItem(int id) =>
      (delete(shoppingListItems)..where((t) => t.id.equals(id))).go();

  Future<int> deleteCheckedShoppingItems() =>
      (delete(shoppingListItems)..where((t) => t.checked.equals(true))).go();

  // ── GroceryPrices ──────────────────────────────────────────────────────────
  Future<List<GroceryPrice>> getAllGroceryPrices() =>
      select(groceryPrices).get();

  Future<GroceryPrice?> findGroceryPriceByNormalized(String normalized) =>
      (select(groceryPrices)..where((t) => t.nameNormalized.equals(normalized)))
          .getSingleOrNull();

  /// Records a real price: updates the moving average if the item exists,
  /// otherwise inserts a new user-adjusted entry.
  Future<void> upsertActualGroceryPrice({
    required String name,
    String? category,
    String? unit,
    required double actual,
  }) async {
    final normalized = GroceryPriceService.normalizeName(name);
    final existing = await (select(groceryPrices)
          ..where((t) => t.nameNormalized.equals(normalized)))
        .getSingleOrNull();
    if (existing == null) {
      await into(groceryPrices).insert(GroceryPricesCompanion.insert(
        name: name,
        nameNormalized: normalized,
        category: Value(category),
        avgPrice: actual,
        unit: Value(unit),
        isUserAdjusted: const Value(true),
      ));
      return;
    }
    final newCount = existing.sampleCount + 1;
    final newAvg =
        (existing.avgPrice * existing.sampleCount + actual) / newCount;
    await (update(groceryPrices)..where((t) => t.id.equals(existing.id)))
        .write(GroceryPricesCompanion(
      avgPrice: Value(newAvg),
      sampleCount: Value(newCount),
      isUserAdjusted: const Value(true),
    ));
  }

  // ── Shopping templates ─────────────────────────────────────────────────────
  Stream<List<ShoppingTemplate>> watchShoppingTemplates() =>
      select(shoppingTemplates).watch();

  Future<List<ShoppingTemplateItem>> getTemplateItems(int templateId) =>
      (select(shoppingTemplateItems)
            ..where((t) => t.templateId.equals(templateId)))
          .get();

  Future<int> saveTemplateFromItems(
      String name, List<ShoppingTemplateDraft> items) async {
    final tplId = await into(shoppingTemplates)
        .insert(ShoppingTemplatesCompanion.insert(name: name));
    await batch((b) {
      for (final it in items) {
        b.insert(
          shoppingTemplateItems,
          ShoppingTemplateItemsCompanion.insert(
            templateId: tplId,
            name: it.name,
            category: Value(it.category),
            quantity: Value(it.quantity),
            unit: Value(it.unit),
          ),
        );
      }
    });
    return tplId;
  }

  Future<void> applyShoppingTemplate(int templateId) async {
    final items = await getTemplateItems(templateId);
    final prices = await getAllGroceryPrices();
    final entries = prices
        .map((p) => PriceEntry(
            name: p.name,
            normalized: p.nameNormalized,
            price: p.avgPrice,
            unit: p.unit))
        .toList();
    await batch((b) {
      for (final it in items) {
        final est = GroceryPriceService.match(it.name, entries);
        b.insert(
          shoppingListItems,
          ShoppingListItemsCompanion.insert(
            name: it.name,
            category: Value(it.category),
            quantity: Value(it.quantity),
            unit: Value(it.unit),
            priceEstimated: Value(est?.price),
          ),
        );
      }
    });
  }

  Future<int> deleteShoppingTemplate(int id) async {
    await (delete(shoppingTemplateItems)
          ..where((t) => t.templateId.equals(id)))
        .go();
    return (delete(shoppingTemplates)..where((t) => t.id.equals(id))).go();
  }
}

/// Lightweight draft used when persisting a shopping template.
class ShoppingTemplateDraft {
  final String name;
  final String? category;
  final double? quantity;
  final String? unit;
  ShoppingTemplateDraft({
    required this.name,
    this.category,
    this.quantity,
    this.unit,
  });
}
