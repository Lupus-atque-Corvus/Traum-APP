import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'nutrition_dao.g.dart';

@DriftAccessor(
    tables: [NutritionLogs, MealTemplates, WaterLogs, ShoppingListItems])
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
}
