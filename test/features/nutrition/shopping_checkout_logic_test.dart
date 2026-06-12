import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/shopping/shopping_checkout_sheet.dart';

void main() {
  late TraumDatabase db;
  setUp(() => db = TraumDatabase.forTesting(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('finalizeShopping books one transaction and updates price DB', () async {
    final catId = await db.into(db.budgetCategories).insert(
        BudgetCategoriesCompanion.insert(name: 'Lebensmittel'));
    await db.into(db.shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        name: 'Bananen',
        checked: const Value(true),
        priceActual: const Value(2.15)));
    await db.into(db.shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        name: 'Milch',
        checked: const Value(true),
        priceActual: const Value(1.25)));

    final total = await finalizeShopping(
      db,
      categoryId: catId,
      description: 'REWE',
      date: DateTime(2026, 6, 11),
      receiptImagePath: null,
    );

    expect(total, closeTo(3.40, 0.001));

    final txns = await db.select(db.transactions).get();
    expect(txns, hasLength(1));
    expect(txns.single.amount, closeTo(3.40, 0.001));
    expect(txns.single.type, 'expense');
    expect(txns.single.categoryId, catId);
    expect(txns.single.description, 'REWE');

    final milk = await db.nutritionDao.findGroceryPriceByNormalized('milch');
    expect(milk, isNotNull);
    expect(milk!.avgPrice, 1.25);
    expect(milk.isUserAdjusted, isTrue);
  });

  test('finalizeShopping books nothing when cart is empty', () async {
    await db.into(db.budgetCategories).insert(
        BudgetCategoriesCompanion.insert(name: 'Lebensmittel'));
    // An item that is checked but has no actual price → not in cart.
    await db.into(db.shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        name: 'Brot', checked: const Value(true)));

    final total = await finalizeShopping(
      db,
      categoryId: null,
      description: 'REWE',
      date: DateTime(2026, 6, 11),
      receiptImagePath: null,
    );

    expect(total, 0.0);
    final txns = await db.select(db.transactions).get();
    expect(txns, isEmpty);
  });
}
