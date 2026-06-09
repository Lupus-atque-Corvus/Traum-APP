import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/l10n/app_localizations.dart';
import 'package:traum/features/onboarding/widgets/interests_page.dart';

final _delegates = AppLocalizations.localizationsDelegates;
final _locales = AppLocalizations.supportedLocales;

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: _delegates,
      supportedLocales: _locales,
      locale: const Locale('de'),
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('Tippen auf Kachel toggelt Auswahl', (tester) async {
    final selected = <String>{};
    await tester.pumpWidget(_wrap(InterestsPage(
      sex: 'male',
      selected: selected,
      onToggle: (m) => selected.contains(m) ? selected.remove(m) : selected.add(m),
      onNext: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('Budget'), findsOneWidget);
    await tester.tap(find.text('Budget'));
    expect(selected, contains('budget'));
  });

  testWidgets('period-Kachel nur bei weiblich', (tester) async {
    await tester.pumpWidget(_wrap(InterestsPage(
      sex: 'male', selected: const {}, onToggle: (_) {}, onNext: () {},
    )));
    await tester.pumpAndSettle();
    expect(find.text('Zyklus'), findsNothing);
  });
}
