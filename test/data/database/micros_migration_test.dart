import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('FoodProducts and MealEntries persist microsJson', () async {
    final pid = await db.foodProductsDao.insertProduct(
      FoodProductsCompanion.insert(
        name: 'Test',
        caloriesPer100g: 100,
        proteinPer100g: 1,
        carbsPer100g: 2,
        fatPer100g: 3,
        microsJson: const Value('{"vitC":60.0}'),
        createdAt: DateTime.now(),
      ),
    );
    final product = await db.foodProductsDao.getById(pid);
    expect(product!.microsJson, '{"vitC":60.0}');

    await db.mealEntriesDao.insertEntry(MealEntriesCompanion.insert(
      date: '2026-06-10',
      mealType: 'snack',
      productId: pid,
      amountGrams: 100,
      calories: 100,
      protein: 1,
      carbs: 2,
      fat: 3,
      loggedAt: DateTime.now(),
      microsJson: const Value('{"vitC":60.0}'),
    ));
    final entries = await db.mealEntriesDao.getForDate('2026-06-10');
    expect(entries.single.microsJson, '{"vitC":60.0}');
  });

  test('Supplements persist nutrientKey', () async {
    final id = await db.supplementDao.insertSupplement(
      SupplementsCompanion.insert(
        name: 'Vitamin D3',
        nutrientKey: const Value('vitD'),
        dosageAmount: const Value('1000'),
        dosageUnit: const Value('IU'),
      ),
    );
    final supps = await db.supplementDao.watchAllSupplements().first;
    expect(supps.firstWhere((s) => s.id == id).nutrientKey, 'vitD');
  });
}
