import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/nutrition_providers.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('productMicrosPer100g merges extended columns + panel json', () async {
    final id = await db.foodProductsDao.insertProduct(
      FoodProductsCompanion.insert(
        name: 'X',
        caloriesPer100g: 0,
        proteinPer100g: 0,
        carbsPer100g: 0,
        fatPer100g: 0,
        sugarPer100g: const Value(9),
        saltPer100g: const Value(1.2),
        microsJson: const Value('{"vitC":60.0,"iron":2.0}'),
        createdAt: DateTime.now(),
      ),
    );
    final product = await db.foodProductsDao.getById(id);
    final micros = productMicrosPer100g(product!);
    expect(micros.values['sugar'], 9);
    expect(micros.values['salt'], 1.2);
    expect(micros.values['vitC'], 60);
    expect(micros.values['iron'], 2);

    final scaled = micros.scale(2); // 200 g
    expect(scaled.values['vitC'], 120);
  });
}
