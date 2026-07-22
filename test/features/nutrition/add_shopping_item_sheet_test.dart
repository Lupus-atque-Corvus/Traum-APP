import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/l10n/app_localizations.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/shopping/add_shopping_item_sheet.dart';

void main() {
  testWidgets('typing a known name fills the suggested price', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.into(db.groceryPrices).insert(GroceryPricesCompanion.insert(
        name: 'Milch', nameNormalized: 'milch', avgPrice: 1.19, unit: const Value('L')));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('de'),
        home: Scaffold(body: AddShoppingItemSheet()),
      ),
    ));
    // Let groceryPriceEntriesProvider resolve.
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const Key('add_item_name')), 'Milch');
    await tester.pump();
    await tester.pumpAndSettle();

    final priceField = tester.widget<TextField>(
        find.byKey(const Key('add_item_price')));
    expect(priceField.controller!.text, '1,19');
    expect(find.text('≈ Milch'), findsOneWidget);
  });
}
