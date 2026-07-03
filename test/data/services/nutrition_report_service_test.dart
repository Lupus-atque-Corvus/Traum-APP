import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/services/nutrition_report_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('mapToReportEntry (pure mapper)', () {
    test('reads the already-scaled macros straight off the entry', () {
      final entry = MealEntry(
        id: 1,
        date: '2026-07-01',
        mealType: 'lunch',
        productId: 42,
        amountGrams: 200,
        calories: 330,
        protein: 62,
        carbs: 0,
        fat: 8,
        loggedAt: DateTime(2026, 7, 1, 12, 30),
      );
      final product = FoodProduct(
        id: 42,
        name: 'Hähnchenbrust',
        caloriesPer100g: 165,
        proteinPer100g: 31,
        carbsPer100g: 0,
        fatPer100g: 4,
        isCustom: false,
        useCount: 0,
        createdAt: DateTime(2026, 1, 1),
      );

      final mapped = mapToReportEntry(entry, product);

      expect(mapped.day, DateTime(2026, 7, 1));
      expect(mapped.meal, 'lunch');
      expect(mapped.foodName, 'Hähnchenbrust');
      expect(mapped.grams, 200);
      // Macros come from the entry (already amountGrams-scaled at log time),
      // NOT recomputed from product.xPer100g * grams / 100.
      expect(mapped.kcal, 330);
      expect(mapped.protein, 62);
      expect(mapped.carbs, 0);
      expect(mapped.fat, 8);
    });

    test('falls back to a placeholder name for an orphaned product', () {
      final entry = MealEntry(
        id: 2,
        date: '2026-07-01',
        mealType: 'snack',
        productId: 999,
        amountGrams: 30,
        calories: 120,
        protein: 2,
        carbs: 15,
        fat: 5,
        loggedAt: DateTime(2026, 7, 1, 16, 0),
      );

      final mapped = mapToReportEntry(entry, null);

      expect(mapped.foodName, 'Unbekanntes Produkt');
      expect(mapped.kcal, 120);
    });
  });

  group('MealEntriesDao.getEntriesBetween (in-memory DB)', () {
    // NutritionReportService.generatePdf() itself is intentionally NOT
    // exercised end-to-end here: assets/fonts/DMSans-*.ttf in this
    // checkout are 12-byte placeholder stubs (not real TTF data — see
    // task-5.2-report.md), so pw.Font.ttf() throws on any environment
    // that hasn't had the real font binaries restored. That is a
    // pre-existing repo condition unrelated to this task, not something
    // this test should paper over. The date-range query + join/mapping
    // logic (the actual non-trivial part of _loadEntries) is covered
    // below and by the pure mapToReportEntry tests above.
    test('filters to the requested range and joins the right product name',
        () async {
      final db = TraumDatabase.forTesting(NativeDatabase.memory());
      final productId = await db.foodProductsDao.insertProduct(
        FoodProductsCompanion.insert(
          name: 'Haferflocken',
          caloriesPer100g: 370,
          proteinPer100g: 13.5,
          carbsPer100g: 59,
          fatPer100g: 7,
          createdAt: DateTime(2026, 1, 1),
        ),
      );
      await db.mealEntriesDao.insertEntry(
        MealEntriesCompanion.insert(
          date: '2026-07-01',
          mealType: 'breakfast',
          productId: productId,
          amountGrams: 80,
          calories: 296,
          protein: 10.8,
          carbs: 47.2,
          fat: 5.6,
          loggedAt: DateTime(2026, 7, 1, 8, 0),
        ),
      );
      // Outside the requested range — must not show up in the report.
      await db.mealEntriesDao.insertEntry(
        MealEntriesCompanion.insert(
          date: '2026-08-15',
          mealType: 'dinner',
          productId: productId,
          amountGrams: 100,
          calories: 370,
          protein: 13.5,
          carbs: 59,
          fat: 7,
          loggedAt: DateTime(2026, 8, 15, 19, 0),
        ),
      );

      final entriesInRange = await db.mealEntriesDao
          .getEntriesBetween(DateTime(2026, 7, 1), DateTime(2026, 7, 31));
      expect(entriesInRange, hasLength(1));
      expect(entriesInRange.single.calories, 296);

      final products = await db.foodProductsDao.getAll();
      final productById = {for (final p in products) p.id: p};
      final reportEntries = entriesInRange
          .map((e) => mapToReportEntry(e, productById[e.productId]))
          .toList();
      expect(reportEntries.single.foodName, 'Haferflocken');
      expect(reportEntries.single.meal, 'breakfast');
      expect(reportEntries.single.day, DateTime(2026, 7, 1));

      await db.close();
    });
  });

  group('NutritionReportService.generatePdf empty-range guard', () {
    test('throws EmptyReportException when the range has no entries',
        () async {
      final db = TraumDatabase.forTesting(NativeDatabase.memory());
      final service = NutritionReportService(db);

      // No mealEntries inserted at all -> the range is guaranteed empty.
      // This exercises the guard added ahead of pw.Font.ttf()/PDF
      // rendering, so it does not depend on the (stubbed) font assets.
      expect(
        () => service.generatePdf(
          from: DateTime(2026, 1, 1),
          to: DateTime(2026, 1, 31),
        ),
        throwsA(isA<EmptyReportException>()),
      );

      await db.close();
    });
  });
}
