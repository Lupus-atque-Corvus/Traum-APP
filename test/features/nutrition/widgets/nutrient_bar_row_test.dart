import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/nutrition/widgets/nutrient_bar_row.dart';

void main() {
  testWidgets('renders label and current/goal with unit', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: NutrientBarRow(
          label: 'Vitamin C', current: 72, goal: 90, unit: 'mg',
        ),
      ),
    ));
    expect(find.text('Vitamin C'), findsOneWidget);
    expect(find.text('72 / 90 mg'), findsOneWidget);
    expect(find.byType(LinearProgressIndicator), findsOneWidget);
  });

  testWidgets('shows "—" when not tracked', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: NutrientBarRow(
          label: 'Eisen', current: null, goal: 14, unit: 'mg',
        ),
      ),
    ));
    expect(find.text('— / 14 mg'), findsOneWidget);
  });
}
