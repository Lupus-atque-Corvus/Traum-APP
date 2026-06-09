import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/l10n/app_localizations.dart';
import 'package:traum/features/onboarding/widgets/showcase_page.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('de'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('zeigt Titel, Untertitel und 3 Features', (tester) async {
    await tester.pumpWidget(_wrap(
      ShowcasePage(moduleKey: 'diary', onNext: () {}),
    ));
    await tester.pumpAndSettle();
    expect(find.text('Tagebuch'), findsOneWidget);
    expect(find.text('Verstanden'), findsOneWidget);
    expect(find.byIcon(Icons.check_circle_rounded), findsNWidgets(3));
  });

  testWidgets('onNext wird bei Button-Tap aufgerufen', (tester) async {
    var tapped = false;
    await tester.pumpWidget(_wrap(
      ShowcasePage(moduleKey: 'notes', onNext: () => tapped = true),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Verstanden'));
    expect(tapped, isTrue);
  });
}
