import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/onboarding/onboarding_models.dart';
import 'package:traum/features/onboarding/widgets/phase_progress_bar.dart';

void main() {
  testWidgets('rendert vier Segmente', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: PhaseProgressBar(
          current: OnboardingPhase.interests,
          phaseProgress: 0.5,
        ),
      ),
    ));
    expect(find.byKey(const ValueKey('phase-segment')), findsNWidgets(4));
  });
}
