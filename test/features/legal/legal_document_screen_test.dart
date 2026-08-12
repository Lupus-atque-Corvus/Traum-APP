import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/legal/legal_document_screen.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(String assetPath, String title) => MaterialApp(
      locale: const Locale('de'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: LegalDocumentScreen(assetPath: assetPath, title: title),
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('shows the title and renders markdown from a real asset',
      (tester) async {
    await tester
        .pumpWidget(_wrap('assets/legal/privacy_policy_de.md', 'Datenschutz'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Datenschutz'), findsOneWidget);
    // The markdown body rendered something beyond just the loading spinner.
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows a friendly error instead of crashing for a missing asset',
      (tester) async {
    await tester
        .pumpWidget(_wrap('assets/legal/does_not_exist.md', 'Fehlt'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Fehlt'), findsOneWidget);
    expect(find.text('Dokument konnte nicht geladen werden'), findsOneWidget);
  });
}
