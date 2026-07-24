import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/data/models/substance_record.dart';
import 'package:traum/features/substances/substance_add_flow.dart';
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
}
