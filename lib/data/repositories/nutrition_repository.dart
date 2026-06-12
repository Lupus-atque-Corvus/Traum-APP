import '../database/traum_database.dart';

class NutritionRepository {
  final NutritionDao _dao;
  NutritionRepository(this._dao);

  Stream<List<NutritionLog>> watchLogsForDate(DateTime date) =>
      _dao.watchLogsForDate(date);
  Future<int> addLog(NutritionLogsCompanion e) => _dao.insertLog(e);
  Future<int> deleteLog(int id) => _dao.deleteLog(id);

  Stream<List<MealTemplate>> watchAllTemplates() => _dao.watchAllTemplates();
  Future<List<MealTemplate>> searchTemplates(String query) =>
      _dao.searchTemplates(query);
  Future<int> addTemplate(MealTemplatesCompanion e) => _dao.insertTemplate(e);
  Future<int> deleteTemplate(int id) => _dao.deleteTemplate(id);

  Stream<List<WaterLog>> watchWaterForDate(DateTime date) =>
      _dao.watchWaterForDate(date);
  Future<List<WaterLog>> getWaterLogsLast7Days() => _dao.getWaterLogsLast7Days();
  Future<int> addWaterLog(WaterLogsCompanion e) => _dao.insertWaterLog(e);
  Future<int> deleteWaterLog(int id) => _dao.deleteWaterLog(id);

  Stream<List<ShoppingListItem>> watchAllShoppingItems() =>
      _dao.watchAllShoppingItems();
  Future<int> addShoppingItem(ShoppingListItemsCompanion e) =>
      _dao.insertShoppingItem(e);
  Future<int> updateShoppingItem(ShoppingListItemsCompanion e) =>
      _dao.updateShoppingItem(e);
  Future<int> deleteShoppingItem(int id) => _dao.deleteShoppingItem(id);
  Future<int> deleteCheckedShoppingItems() => _dao.deleteCheckedShoppingItems();
}
