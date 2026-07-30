import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/models/substance_record.dart';
import 'package:traum/features/substances/substance_add_flow.dart';
import 'package:traum/features/substances/substance_detail_sheet.dart';
import 'package:traum/l10n/app_localizations.dart';
import 'package:drift/native.dart';

void main() {
  testWidgets('opens the medication sheet prefilled for klasse=medikament', (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final record = SubstanceRecord(
      id: 1,
      substance: 'Ibuprofen',
      folder: 'ibuprofen',
      klasse: SubstanceKlasse.medikament,
      pflanzlich: false,
      datenStatus: DatenStatus.vollstaendig,
      dosierung: const DosierungNachAltersgruppe(erwachseneDe: '200-400 mg alle 6-8h'),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => openAddFlowForRecord(context, ref, record),
              child: const Text('open'),
            );
          }),
        ),
      ),
    ));
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsWidgets); // prefilled in the name field
    expect(find.textContaining('200-400 mg alle 6-8h'), findsOneWidget);
  });

  testWidgets(
      'saving a cross-tab-added medication from the real detail sheet persists it '
      'and closes the sheet (regression test for the stale-context Save hang)',
      (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final record = SubstanceRecord(
      id: 1,
      substance: 'Ibuprofen',
      folder: 'ibuprofen',
      klasse: SubstanceKlasse.medikament,
      pflanzlich: false,
      datenStatus: DatenStatus.vollstaendig,
      dosierung: const DosierungNachAltersgruppe(erwachseneDe: '200-400 mg alle 6-8h'),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              // Mirrors the real call site (database_tab.dart): the detail
              // sheet is opened via showSubstanceDetailSheet, which itself
              // calls Navigator.pop(context) before openAddFlowForRecord —
              // exactly the sequence that made the caller's ref/context
              // stale in the two bugs this test guards against.
              onPressed: () => showSubstanceDetailSheet(context, ref, record),
              child: const Text('open detail'),
            );
          }),
        ),
      ),
    ));
    await tester.tap(find.text('open detail'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Zu meinen Mitteln hinzufügen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zu meinen Mitteln hinzufügen'));
    // Bounded pumps, not pumpAndSettle: the detail sheet's close transition
    // and the add sheet's open transition overlap here, which doesn't
    // reliably converge under pumpAndSettle in the test harness (same
    // pattern used elsewhere in this suite for modal-sheet transitions).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Medikament hinzufügen'), findsOneWidget);

    await tester.tap(find.text('Speichern'));
    // The save is async (DB insert); give it real time to complete instead
    // of pumpAndSettle, which would hang forever if the regression returns.
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    // The sheet must have closed (Navigator.pop reached) — not stuck on
    // "Speichern…" as it was before the ProviderScope.containerOf(ctx) fix.
    expect(find.text('Medikament hinzufügen'), findsNothing);

    // One-shot query, not the watch() stream — avoids any lingering Drift
    // stream-notification Timer at test teardown.
    final saved = await db.select(db.medications).get();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Ibuprofen');
    expect(saved.single.dosage, '200-400 mg alle 6-8h');
  });

  testWidgets(
      'saving a cross-tab-added supplement auto-fills nutrientKey from the '
      'prefilled name (regression test for the nutrition-integration gap)',
      (tester) async {
    final db = TraumDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final record = SubstanceRecord(
      id: 2,
      substance: 'Vitamin D3',
      folder: 'vitamin-d3',
      klasse: SubstanceKlasse.supplement,
      kategorie: 'Vitamine',
      pflanzlich: false,
      datenStatus: DatenStatus.vollstaendig,
      dosierung: const DosierungNachAltersgruppe(erwachseneDe: '2000 IE täglich'),
    );

    await tester.pumpWidget(ProviderScope(
      overrides: [databaseProvider.overrideWithValue(db)],
      child: MaterialApp(
        locale: const Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => showSubstanceDetailSheet(context, ref, record),
              child: const Text('open detail'),
            );
          }),
        ),
      ),
    ));
    await tester.tap(find.text('open detail'));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Zu meinen Mitteln hinzufügen'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Zu meinen Mitteln hinzufügen'));
    // Bounded pumps, not pumpAndSettle: the detail sheet's close transition
    // and the add sheet's open transition overlap here, which doesn't
    // reliably converge under pumpAndSettle in the test harness (same
    // pattern used elsewhere in this suite for modal-sheet transitions).
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Supplement hinzufügen'), findsOneWidget);

    await tester.tap(find.text('Speichern'));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Supplement hinzufügen'), findsNothing);

    // One-shot query, not the watch() stream — avoids any lingering Drift
    // stream-notification Timer at test teardown.
    final saved = await db.select(db.supplements).get();
    expect(saved, hasLength(1));
    expect(saved.single.name, 'Vitamin D3');
    // This is the field that stayed null before the initState fix: without
    // it, today's intake of a DB-added "Vitamin D3" never contributes to
    // the nutrition tab's micronutrient sums.
    expect(saved.single.nutrientKey, 'vitD');
  });
}
