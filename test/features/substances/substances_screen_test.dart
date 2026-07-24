import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:traum/core/providers/preferences_provider.dart';
import 'package:traum/features/substances/substances_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(SharedPreferences prefs) => ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(
        locale: Locale('de'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: SubstancesScreen(),
      ),
    );

void main() {
  testWidgets('shows the disclaimer gate before acceptance', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsNothing);
    // Exact match for the title: the disclaimer body's markdown also starts
    // with an H1 "# Bevor es losgeht" heading, so a substring match would
    // ambiguously find both the title and the body text.
    expect(find.text('Bevor es losgeht'), findsOneWidget);
  });

  testWidgets('accepting the disclaimer reveals the tabs and persists', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('substances_disclaimer_accept')));
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsOneWidget);
    expect(prefs.getBool('substances_disclaimer_accepted_v1'), isTrue);
  });

  testWidgets('skips the gate on subsequent opens once accepted', (tester) async {
    SharedPreferences.setMockInitialValues(
        {'substances_disclaimer_accepted_v1': true});
    final prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(_wrap(prefs));
    await tester.pumpAndSettle();

    expect(find.byType(TabBarView), findsOneWidget);
  });
}
