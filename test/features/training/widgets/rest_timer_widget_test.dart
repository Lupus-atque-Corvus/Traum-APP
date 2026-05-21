import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/training/widgets/rest_timer_widget.dart';
import 'package:traum/l10n/app_localizations.dart';

Widget _wrap(Widget child) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(body: child),
    );

void main() {
  testWidgets('RestTimerWidget shows formatted duration and skip button',
      (tester) async {
    await tester.pumpWidget(_wrap(RestTimerWidget(
      durationSeconds: 90,
      onFinished: () {},
      onSkip: () {},
    )));
    await tester.pump(); // settle localization
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('RestTimerWidget calls onSkip when Skip tapped', (tester) async {
    bool skipped = false;
    await tester.pumpWidget(_wrap(RestTimerWidget(
      durationSeconds: 90,
      onFinished: () {},
      onSkip: () => skipped = true,
    )));
    await tester.pump();
    await tester.tap(find.text('Skip'));
    expect(skipped, isTrue);
  });

  testWidgets('RestTimerWidget calls onFinished when timer expires',
      (tester) async {
    bool finished = false;
    await tester.pumpWidget(_wrap(RestTimerWidget(
      durationSeconds: 2,
      onFinished: () => finished = true,
      onSkip: () {},
    )));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    expect(finished, isTrue);
  });
}
