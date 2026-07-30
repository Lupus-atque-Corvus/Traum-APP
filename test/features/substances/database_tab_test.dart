// test/features/substances/database_tab_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/providers/database_provider.dart';
import 'package:traum/data/models/substance_record.dart';
import 'package:traum/features/substances/database_tab.dart';
import 'package:traum/l10n/app_localizations.dart';

SubstanceRecord _record({required String name, DatenStatus status = DatenStatus.vollstaendig}) =>
    SubstanceRecord(
      id: 1,
      substance: name,
      folder: name.toLowerCase(),
      klasse: SubstanceKlasse.medikament,
      kategorie: 'Schmerzmittel',
      pflanzlich: false,
      datenStatus: status,
      dosierung: const DosierungNachAltersgruppe(),
    );

void main() {
  testWidgets('shows the category grid when the query is empty', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        substanceCategoriesProvider.overrideWith((ref) async => ['Schmerzmittel', 'Herz-Kreislauf']),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DatabaseTab()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Schmerzmittel'), findsOneWidget);
    expect(find.text('Herz-Kreislauf'), findsOneWidget);
  });

  testWidgets('shows search results with a status badge after typing', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        substanceCategoriesProvider.overrideWith((ref) async => []),
        substanceSearchProvider('ibu').overrideWith((ref) async => [_record(name: 'Ibuprofen')]),
      ],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DatabaseTab()),
      ),
    ));
    await tester.enterText(find.byType(TextField), 'ibu');
    await tester.pump(const Duration(milliseconds: 350));
    await tester.pumpAndSettle();

    expect(find.text('Ibuprofen'), findsOneWidget);
  });

  testWidgets('does not render an offline-count banner', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [substanceCategoriesProvider.overrideWith((ref) async => [])],
      child: const MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: DatabaseTab()),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('offline verfügbar'), findsNothing);
  });
}
