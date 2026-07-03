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

  /// Zwischengespeichertes Produkt aus einer externen Quelle (per
  /// `sourceApi` + `sourceId`) finden — für Dedupe beim erneuten Cachen
  /// eines Online-Suchtreffers.
  Future<FoodProduct?> getBySource(String sourceApi, String sourceId) =>
      (select(foodProducts)
            ..where((t) =>
                t.sourceApi.equals(sourceApi) &
                t.sourceId.equals(sourceId))
            ..limit(1))
          .getSingleOrNull();

  /// Cached ein Online-Suchergebnis in der lokalen DB: aktualisiert ein
  /// bereits vorhandenes Produkt (gefunden per Barcode, sonst per
  /// `sourceApi`+`sourceId`) mit den frischen Werten, oder legt ein neues
  /// an. `FoodProducts` hat keinen DB-Unique-Index auf `barcode`/`sourceId`
  /// (kein Schema-Constraint dafür) — der Lookup passiert daher hier auf
  /// DAO-Ebene statt über `insertOnConflictUpdate`.
  Future<FoodProduct> upsertFromSource(FoodProductsCompanion entry) async {
    FoodProduct? existing;
    final barcode = entry.barcode.present ? entry.barcode.value : null;
    if (barcode != null && barcode.isNotEmpty) {
      existing = await getByBarcode(barcode);
    }
    if (existing == null &&
        entry.sourceApi.present &&
        entry.sourceId.present &&
        entry.sourceId.value != null) {
      existing =
          await getBySource(entry.sourceApi.value!, entry.sourceId.value!);
    }
    if (existing != null) {
      await (update(foodProducts)..where((t) => t.id.equals(existing!.id)))
          .write(entry);
      return (await getById(existing.id))!;
    }
    final id = await insertProduct(entry);
    return (await getById(id))!;
  }

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
