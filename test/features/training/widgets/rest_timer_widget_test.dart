import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/training/widgets/rest_timer_widget.dart';

void main() {
  testWidgets('RestTimerWidget shows duration and skip button', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RestTimerWidget(
          durationSeconds: 90,
          onFinished: () {},
          onSkip: () {},
        ),
      ),
    ));
    expect(find.text('01:30'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
  });

  testWidgets('RestTimerWidget calls onSkip when Skip pressed', (tester) async {
    bool skipped = false;
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: RestTimerWidget(
          durationSeconds: 90,
          onFinished: () {},
          onSkip: () => skipped = true,
        ),
      ),
    ));
    await tester.tap(find.text('Skip'));
    expect(skipped, true);
  });
}
