import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('findGroceryPriceByNormalized returns the seeded entry', () async {
    await db.into(db.groceryPrices).insert(GroceryPricesCompanion.insert(
        name: 'Milch', nameNormalized: 'milch', avgPrice: 1.19));
    final hit = await db.nutritionDao.findGroceryPriceByNormalized('milch');
    expect(hit, isNotNull);
    expect(hit!.avgPrice, 1.19);
  });

  test('upsertActualGroceryPrice updates moving average and flags', () async {
    await db.into(db.groceryPrices).insert(GroceryPricesCompanion.insert(
        name: 'Milch', nameNormalized: 'milch', avgPrice: 1.00));
    await db.nutritionDao
        .upsertActualGroceryPrice(name: 'Milch', actual: 2.00);
    final hit = await db.nutritionDao.findGroceryPriceByNormalized('milch');
    expect(hit!.avgPrice, closeTo(1.50, 0.001)); // (1.00*1 + 2.00)/2
    expect(hit.sampleCount, 2);
    expect(hit.isUserAdjusted, isTrue);
  });

  test('upsertActualGroceryPrice inserts when missing', () async {
    await db.nutritionDao.upsertActualGroceryPrice(
        name: 'Neuware', category: 'Vorrat', actual: 3.50);
    final hit = await db.nutritionDao.findGroceryPriceByNormalized('neuware');
    expect(hit, isNotNull);
    expect(hit!.avgPrice, 3.50);
    expect(hit.isUserAdjusted, isTrue);
  });

  test('saveTemplateFromItems + applyTemplate round-trips', () async {
    final tplId = await db.nutritionDao.saveTemplateFromItems('Woche', [
      ShoppingTemplateDraft(name: 'Brot', category: 'Backwaren'),
      ShoppingTemplateDraft(name: 'Milch', quantity: 2, unit: 'L'),
    ]);
    await db.nutritionDao.applyShoppingTemplate(tplId);
    final items = await db.nutritionDao.watchAllShoppingItems().first;
    expect(items.map((i) => i.name), containsAll(['Brot', 'Milch']));
  });

  test('deleteShoppingTemplate removes the template and its items', () async {
    final tplId = await db.nutritionDao.saveTemplateFromItems('Woche', [
      ShoppingTemplateDraft(name: 'Brot'),
      ShoppingTemplateDraft(name: 'Milch'),
    ]);
    await db.nutritionDao.deleteShoppingTemplate(tplId);
    final templates = await db.nutritionDao.watchShoppingTemplates().first;
    expect(templates, isEmpty);
    final items = await db.nutritionDao.getTemplateItems(tplId);
    expect(items, isEmpty);
  });

  test('upsertActualGroceryPrice accumulates multiple samples', () async {
    await db.into(db.groceryPrices).insert(GroceryPricesCompanion.insert(
        name: 'Milch', nameNormalized: 'milch', avgPrice: 1.00));
    await db.nutritionDao.upsertActualGroceryPrice(name: 'Milch', actual: 2.00);
    await db.nutritionDao.upsertActualGroceryPrice(name: 'Milch', actual: 3.00);
    final hit = await db.nutritionDao.findGroceryPriceByNormalized('milch');
    expect(hit!.sampleCount, 3);
    expect(hit.avgPrice, closeTo(2.00, 0.001));
  });
}
