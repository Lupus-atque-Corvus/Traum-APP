// test/features/substances/substance_detail_sheet_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/models/substance_record.dart';
import 'package:traum/features/substances/substance_detail_sheet.dart';
import 'package:traum/l10n/app_localizations.dart';

SubstanceRecord _record({String? beschreibungDe, String? wechselwirkungenDe}) =>
    SubstanceRecord(
      id: 1,
      substance: 'Ibuprofen',
      folder: 'ibuprofen',
      klasse: SubstanceKlasse.medikament,
      kategorie: 'Schmerzmittel',
      pflanzlich: false,
      datenStatus: DatenStatus.teilweise,
      dosierung: const DosierungNachAltersgruppe(),
      beschreibungDe: beschreibungDe,
      wechselwirkungenDe: wechselwirkungenDe,
    );

Widget _wrap(Widget child) => ProviderScope(
  child: MaterialApp(
    locale: const Locale('de'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(body: Builder(builder: (ctx) => child)),
  ),
);

void main() {
  testWidgets('null fields render as "keine Angabe", not blank', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () =>
                  showSubstanceDetailSheet(context, ref, _record()),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.textContaining('keine Angabe'), findsWidgets);
  });

  testWidgets('shows the free-text Wechselwirkungen block when present', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        Consumer(
          builder: (context, ref, _) {
            return ElevatedButton(
              onPressed: () => showSubstanceDetailSheet(
                context,
                ref,
                _record(
                  wechselwirkungenDe: 'Erhöhtes Blutungsrisiko mit Warfarin.',
                ),
              ),
              child: const Text('open'),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Erhöhtes Blutungsrisiko mit Warfarin.'),
      findsOneWidget,
    );
  });

  testWidgets(
    'shows Wikipedia attribution footer when quellenTags contains wikipedia:ww',
    (tester) async {
      final record = SubstanceRecord(
        id: 1,
        substance: 'TestSubstanz',
        folder: 'test',
        klasse: SubstanceKlasse.medikament,
        pflanzlich: false,
        datenStatus: DatenStatus.teilweise,
        quellenTags: const ['wikipedia:ww'],
        dosierung: const DosierungNachAltersgruppe(),
      );
      await tester.pumpWidget(
        _wrap(
          Consumer(
            builder: (context, ref, _) {
              return ElevatedButton(
                onPressed: () => showSubstanceDetailSheet(context, ref, record),
                child: const Text('open'),
              );
            },
          ),
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The attribution footer sits below the fold of the sheet's initial
      // extent, so scroll the sheet's ListView until it comes into view.
      await tester.scrollUntilVisible(
        find.textContaining('CC BY-SA'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.textContaining('CC BY-SA'), findsOneWidget);
    },
  );
}
