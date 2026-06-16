import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/period_tracking/cycle_history_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

void main() {
  testWidgets('history can end an active period', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.periodDao.insertPeriodEntry(
        PeriodEntriesCompanion.insert(startDate: DateTime(2026, 6, 1)));
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('de'),
        home: CycleHistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();
    // "Periode beenden" is the DE value of l10n.endPeriod
    final endBtn = find.text('Periode beenden');
    expect(endBtn, findsOneWidget);
    await tester.tap(endBtn);
    await tester.pumpAndSettle();
    final entries = await db.periodDao.getAllPeriodEntries();
    expect(entries.single.endDate, isNotNull);
  });

  testWidgets('history swipe-to-delete removes a period entry', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.periodDao.insertPeriodEntry(
        PeriodEntriesCompanion.insert(
          startDate: DateTime(2026, 5, 1),
          endDate: Value(DateTime(2026, 5, 5)),
        ));
    final container = ProviderContainer(
        overrides: [databaseProvider.overrideWithValue(db)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: Locale('de'),
        home: CycleHistoryScreen(),
      ),
    ));
    await tester.pumpAndSettle();

    // Swipe the Dismissible from right to left
    await tester.drag(
        find.byType(Dismissible).first, const Offset(-500, 0));
    await tester.pumpAndSettle();

    final entries = await db.periodDao.getAllPeriodEntries();
    expect(entries, isEmpty);
  });
}
