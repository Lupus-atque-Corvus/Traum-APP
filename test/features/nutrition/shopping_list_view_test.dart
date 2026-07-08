import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/l10n/app_localizations.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/nutrition/shopping/shopping_list_view.dart';

void main() {
  testWidgets('hero shows estimated total of open items', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    await db.into(db.shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        name: 'Bananen',
        category: const Value('Obst & Gemüse'),
        priceEstimated: const Value(1.99)));
    await db.into(db.shoppingListItems).insert(ShoppingListItemsCompanion.insert(
        name: 'Milch', priceEstimated: const Value(1.20)));

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('de'),
          home: Scaffold(body: ShoppingListView())),
    ));
    await tester.pumpAndSettle();

    expect(find.text('3,19 €'), findsOneWidget);
    expect(find.text('Bananen'), findsOneWidget);
    expect(find.text('🛒  Einkaufen starten'), findsOneWidget);

    // Close DB before widget teardown to prevent drift's StreamQueryStore from
    // leaving a pending timer that causes the test framework assertion failure.
    await db.close();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });
}
