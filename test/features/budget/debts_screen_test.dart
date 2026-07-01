// test/features/budget/debts_screen_test.dart
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/budget/debts_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(TraumDatabase db, SharedPreferences prefs) => ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(db),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('de'),
        home: DebtsScreen(),
      ),
    );

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  testWidgets('tapping a debt card expands it and shows its positions',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final debtId = await db.budgetDao.insertDebt(
      DebtsCompanion.insert(
          creditor: 'Mama', originalAmount: 0, remainingAmount: 0),
    );
    await db.budgetDao.insertDebtItem(DebtItemsCompanion.insert(
        debtId: debtId, description: 'Tankfüllung', amount: 60));

    await tester.pumpWidget(_wrap(db, prefs));
    // Let stream-backed providers deliver their first value.
    await tester.pump(const Duration(milliseconds: 100));

    // Collapsed: position not visible yet.
    expect(find.text('Tankfüllung'), findsNothing);

    await tester.tap(find.text('Mama'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Expanded: position now visible.
    expect(find.text('Tankfüllung'), findsOneWidget);

    // Unmount and flush Drift stream-close timers so the test does not trip
    // the "Timer still pending" teardown check.
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('tapping a position opens the edit sheet with the edit title',
      (tester) async {
    final prefs = await SharedPreferences.getInstance();
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);

    final debtId = await db.budgetDao.insertDebt(
      DebtsCompanion.insert(
          creditor: 'Mama', originalAmount: 0, remainingAmount: 0),
    );
    await db.budgetDao.insertDebtItem(DebtItemsCompanion.insert(
        debtId: debtId, description: 'Tankfüllung', amount: 60));

    await tester.pumpWidget(_wrap(db, prefs));
    await tester.pump(const Duration(milliseconds: 100));

    // Expand the card, then tap the position to open its edit sheet.
    await tester.tap(find.text('Mama'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.tap(find.text('Tankfüllung'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Edit variant shows "Position bearbeiten", not the add title.
    expect(find.text('Position bearbeiten'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
  });
}
