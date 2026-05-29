import 'package:drift/drift.dart';
import '../traum_database.dart';

part 'food_products_dao.g.dart';

@DriftAccessor(tables: [FoodProducts])
class FoodProductsDao extends DatabaseAccessor<TraumDatabase>
    with _$FoodProductsDaoMixin {
  FoodProductsDao(super.db);

  Future<FoodProduct?> getByBarcode(String barcode) =>
      (select(foodProducts)
            ..where((t) => t.barcode.equals(barcode))
            ..limit(1))
          .getSingleOrNull();

  Future<FoodProduct?> getById(int id) =>
      (select(foodProducts)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<FoodProduct>> search(String query) =>
      (select(foodProducts)
            ..where((t) =>
                t.name.like('%$query%') | t.brand.like('%$query%'))
            ..orderBy([(t) => OrderingTerm.desc(t.useCount)]))
          .get();

  Future<List<FoodProduct>> getRecent({int limit = 10}) =>
      (select(foodProducts)
            ..where((t) => t.lastUsed.isNotNull())
            ..orderBy([(t) => OrderingTerm.desc(t.lastUsed)])
            ..limit(limit))
          .get();

  Future<int> insertProduct(FoodProductsCompanion entry) =>
      into(foodProducts).insert(entry);

  Future<void> incrementUseCount(int id) async {
    final product = await getById(id);
    if (product == null) return;
    await (update(foodProducts)..where((t) => t.id.equals(id))).write(
      FoodProductsCompanion(
        useCount: Value(product.useCount + 1),
        lastUsed: Value(DateTime.now()),
      ),
    );
  }

  Future<int> deleteProduct(int id) =>
      (delete(foodProducts)..where((t) => t.id.equals(id))).go();

  Future<List<FoodProduct>> getAllCustom() =>
      (select(foodProducts)..where((t) => t.isCustom)).get();

  Future<List<FoodProduct>> getAll() =>
      (select(foodProducts)
            ..orderBy([
              (t) => OrderingTerm.desc(t.isCustom),
              (t) => OrderingTerm.desc(t.useCount),
            ]))
          .get();
}
