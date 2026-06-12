import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/shopping/shopping_mode_screen.dart';

void main() {
  testWidgets('checking an item and typing a price updates the real total',
      (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    final id = await db.into(db.shoppingListItems).insert(
        ShoppingListItemsCompanion.insert(
            name: 'Bananen', priceEstimated: const Value(1.99)));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(home: ShoppingModeScreen()),
    ));
    await tester.pumpAndSettle();

    // Put in cart.
    await db.nutritionDao.updateShoppingItem(ShoppingListItemsCompanion(
        id: Value(id), checked: const Value(true)));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(Key('price_field_$id')), '2,15');
    await tester.pumpAndSettle();

    expect(find.text('2,15 €'), findsOneWidget); // hero real total

    // Close DB before widget tree teardown so that Drift's StreamQueryStore
    // sets _isShuttingDown=true, causing markAsClosed to be a no-op during
    // widget disposal — prevents the "pending timer" test assertion failure.
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
