import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/substances/my_substances_tab.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(TraumDatabase db) => ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: const MySubstancesTab(),
      ),
    );

/// Unmounts the widget tree and flushes Drift's stream-close timers so the
/// test does not trip the "Timer still pending" teardown check (see
/// test/features/budget/debts_screen_test.dart for the established pattern).
Future<void> _flushAndUnmount(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox());
  await tester.pump(const Duration(seconds: 1));
}

void main() {
  testWidgets('does not show an interaction banner in the widget tree', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.medicationDao.insertMedication(MedicationsCompanion.insert(
      name: 'Ibuprofen',
      dosage: const Value('400 mg'),
      form: const Value('Tablette'),
      timings: const Value('["08:00"]'),
    ));

    await tester.pumpWidget(_wrap(db));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.textContaining('Interaktion'), findsNothing);
    expect(find.byIcon(Icons.warning_rounded), findsNothing);

    await _flushAndUnmount(tester);
  });

  testWidgets('long-press on a medication card opens the context menu with Löschen', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.medicationDao.insertMedication(MedicationsCompanion.insert(
      name: 'Ibuprofen',
      dosage: const Value('400 mg'),
      form: const Value('Tablette'),
      timings: const Value('["08:00"]'),
    ));

    await tester.pumpWidget(_wrap(db));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Löschen'), findsNothing);

    // "Ibuprofen" also appears in the today-status dot row (the medication is
    // active by default), so target the card via its unique subtitle text
    // ("400 mg · Tablette") instead of the ambiguous name text.
    await tester.longPress(find.text('400 mg · Tablette'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Löschen'), findsOneWidget);
    expect(find.text('Deaktivieren'), findsOneWidget);

    await _flushAndUnmount(tester);
  });

  testWidgets('confirming Löschen in the context menu deletes the medication', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.medicationDao.insertMedication(MedicationsCompanion.insert(
      name: 'Ibuprofen',
      dosage: const Value('400 mg'),
      form: const Value('Tablette'),
      timings: const Value('["08:00"]'),
    ));

    await tester.pumpWidget(_wrap(db));
    await tester.pump(const Duration(milliseconds: 100));

    await tester.longPress(find.text('400 mg · Tablette'));
    await tester.pump(const Duration(milliseconds: 300));

    await tester.tap(find.text('Löschen'));
    await tester.pump(const Duration(milliseconds: 300));

    // Confirmation dialog. The context-menu's "Löschen" ListTile is still in
    // the tree at this point (its closing animation hasn't fully removed it),
    // so target the dialog's TextButton specifically rather than the
    // now-ambiguous plain text match.
    expect(find.text('Wirklich löschen?'), findsOneWidget);
    await tester.tap(find.widgetWithText(TextButton, 'Löschen'));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Ibuprofen'), findsNothing);

    await _flushAndUnmount(tester);
  });
}
