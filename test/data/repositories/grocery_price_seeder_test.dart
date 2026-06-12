import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/repositories/grocery_price_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('seedIfNeeded fills grocery_prices once and is idempotent', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    await GroceryPriceSeeder.seedIfNeeded(db, prefs);
    final afterFirst = await db.select(db.groceryPrices).get();
    expect(afterFirst.length, greaterThan(300));
    expect(afterFirst.first.nameNormalized, isNotEmpty);

    // Second run must not duplicate.
    await GroceryPriceSeeder.seedIfNeeded(db, prefs);
    final afterSecond = await db.select(db.groceryPrices).get();
    expect(afterSecond.length, afterFirst.length);
  });

  test('does not set the flag when seeding fails', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    // Drop the table so the seeder's DB read throws a real SQL error,
    // exercising the catch block and the "flag stays unset" invariant.
    await db.customStatement('DROP TABLE grocery_prices');

    await GroceryPriceSeeder.seedIfNeeded(db, prefs);

    expect(prefs.getBool('grocery_prices_seeded_v1'), isNull);
  });
}
