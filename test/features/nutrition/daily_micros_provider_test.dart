import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/nutrition_providers.dart';

void main() {
  late TraumDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = TraumDatabase.forTesting(NativeDatabase.memory());
    container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
  });
  tearDown(() {
    container.dispose();
    db.close();
  });

  test('dailyMicros sums meal entries + checked supplements', () async {
    final date = formatDateStr(DateTime.now());

    // Meal entry with micros
    final pid = await db.foodProductsDao.insertProduct(
      FoodProductsCompanion.insert(
        name: 'P', caloriesPer100g: 0, proteinPer100g: 0,
        carbsPer100g: 0, fatPer100g: 0,
        microsJson: const Value('{"vitC":30.0,"iron":2.0}'),
        createdAt: DateTime.now(),
      ),
    );
    await db.mealEntriesDao.insertEntry(MealEntriesCompanion.insert(
      date: date, mealType: 'snack', productId: pid, amountGrams: 100,
      calories: 0, protein: 0, carbs: 0, fat: 0, loggedAt: DateTime.now(),
      microsJson: const Value('{"vitC":30.0,"iron":2.0}'),
    ));

    // Supplement mapped to vitC, checked today
    final sid = await db.supplementDao.insertSupplement(
      SupplementsCompanion.insert(
        name: 'Vitamin C', nutrientKey: const Value('vitC'),
        dosageAmount: const Value('500'), dosageUnit: const Value('mg'),
      ),
    );
    await db.supplementDao.insertLog(SupplementLogsCompanion.insert(
      supplementId: sid, takenAt: DateTime.now(),
    ));

    // Inactive-for-contribution supplement: not checked → no contribution
    await db.supplementDao.insertSupplement(SupplementsCompanion.insert(
      name: 'Magnesium', nutrientKey: const Value('magnesium'),
      dosageAmount: const Value('400'), dosageUnit: const Value('mg'),
    ));

    final micros = await container.read(dailyMicrosProvider(date).future);
    expect(micros.values['vitC'], 30 + 500); // meal + supplement
    expect(micros.values['iron'], 2);
    expect(micros.values.containsKey('magnesium'), isFalse);
  });
}
