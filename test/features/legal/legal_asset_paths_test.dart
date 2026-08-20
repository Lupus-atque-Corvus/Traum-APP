import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/legal/legal_asset_paths.dart';

void main() {
  /// Wraps [child] in a bare [Localizations] ancestor reporting exactly
  /// [locale] — deliberately not going through `MaterialApp`'s locale
  /// *resolution* (which would remap an unsupported locale to one of
  /// `supportedLocales` before `legalAssetPath` ever saw it). This isolates
  /// `legalAssetPath`'s own fallback logic from that unrelated resolution
  /// step.
  Future<String> resolve(WidgetTester tester, Locale locale, String baseName) async {
    late String result;
    await tester.pumpWidget(
      Localizations(
        locale: locale,
        delegates: const [DefaultWidgetsLocalizations.delegate],
        child: Builder(
          builder: (context) {
            result = legalAssetPath(context, baseName);
            return const SizedBox();
          },
        ),
      ),
    );
    return result;
  }

  testWidgets('resolves to the _de asset for German locale', (tester) async {
    final path = await resolve(tester, const Locale('de'), 'privacy_policy');
    expect(path, 'assets/legal/privacy_policy_de.md');
  });

  testWidgets('resolves to the _en asset for English locale', (tester) async {
    final path = await resolve(tester, const Locale('en'), 'terms');
    expect(path, 'assets/legal/terms_en.md');
  });

  testWidgets('falls back to _en for any locale that is not German', (tester) async {
    final path = await resolve(tester, const Locale('fr'), 'medical_disclaimer');
    expect(path, 'assets/legal/medical_disclaimer_en.md');
  });
}
