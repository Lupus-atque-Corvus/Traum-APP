import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';

void main() {
  test('v15 schema exposes new shopping columns and tables', () async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    // New columns on shopping_list_items
    final itemId = await db.into(db.shoppingListItems).insert(
          ShoppingListItemsCompanion.insert(
            name: 'Milch',
            priceEstimated: const Value(1.20),
            isUrgent: const Value(true),
          ),
        );
    final item =
        await (db.select(db.shoppingListItems)..where((t) => t.id.equals(itemId)))
            .getSingle();
    expect(item.priceEstimated, 1.20);
    expect(item.isUrgent, isTrue);
    expect(item.priceActual, equals(null));

    // New grocery_prices table
    await db.into(db.groceryPrices).insert(
          GroceryPricesCompanion.insert(
            name: 'Milch',
            nameNormalized: 'milch',
            avgPrice: 1.20,
          ),
        );
    final prices = await db.select(db.groceryPrices).get();
    expect(prices, hasLength(1));
    expect(prices.first.sampleCount, 1);

    // Template tables
    final tplId = await db.into(db.shoppingTemplates).insert(
          ShoppingTemplatesCompanion.insert(name: 'Wocheneinkauf'),
        );
    await db.into(db.shoppingTemplateItems).insert(
          ShoppingTemplateItemsCompanion.insert(templateId: tplId, name: 'Brot'),
        );
    final tplItems = await db.select(db.shoppingTemplateItems).get();
    expect(tplItems.single.name, 'Brot');
  });
}
