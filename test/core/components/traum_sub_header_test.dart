import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/components/traum_sub_header.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: Scaffold(body: child),
);

void main() {
  testWidgets('scale multiplies layout dimensions but never the font size', (
    tester,
  ) async {
    // Regression test for a subtlety found while extracting this from
    // Budget's original BudgetSubHeader: Budget applies its 1.12x
    // kBudgetScale to structural measures via a raw multiplier, but relies
    // on an ambient MediaQuery text scaler (BudgetTextScale) for font size —
    // baking `scale` into the font size here as well would double-apply it
    // wherever both are present.
    await tester.pumpWidget(
      _wrap(const TraumSubHeader(title: 'Test', scale: 2.0)),
    );

    final text = tester.widget<Text>(find.text('Test'));
    expect(text.style!.fontSize, 15);

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration! as BoxDecoration;
    expect(container.constraints!.maxWidth, 48); // 24 * 2.0
    expect(
      (decoration.borderRadius! as BorderRadius).topLeft.x,
      24,
    ); // 12 * 2.0
  });

  testWidgets('default scale of 1.0 matches the original unscaled spec', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(const TraumSubHeader(title: 'Test')));

    final container = tester.widget<Container>(find.byType(Container).first);
    expect(container.constraints!.maxWidth, 24);
    expect(container.constraints!.maxHeight, 24);
  });

  testWidgets('tapping back pops the route', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) =>
                        const Scaffold(body: TraumSubHeader(title: 'Detail')),
                  ),
                ),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();
    expect(find.text('Detail'), findsNothing);
  });
}
