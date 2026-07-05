import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:traum/features/training/widgets/body_map_widget.dart';

void main() {
  testWidgets('renders SvgPicture for front view', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BodyMapWidget(primaryMuscles: ['pectorals'], secondaryMuscles: []),
      ),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('renders back view when showBack is true', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: BodyMapWidget(
          primaryMuscles: ['lats'],
          secondaryMuscles: [],
          showBack: true,
        ),
      ),
    ));
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('musclesForGroup maps Brust to pectorals', () {
    expect(BodyMapWidget.musclesForGroup('Brust'), contains('pectorals'));
  });

  test('musclesForGroup maps Rücken to lats', () {
    expect(BodyMapWidget.musclesForGroup('Rücken'), contains('lats'));
  });

  test('musclesForGroup falls back to full-body muscles for unknown group', () {
    // Post-fix behavior (Bugfix Audit 6.1): an unrecognized group now
    // normalizes to 'full_body' (same fallback ExerciseIcon already used)
    // instead of silently returning [] (which was the heatmap bug).
    expect(BodyMapWidget.musclesForGroup('Unbekannt'), isNotEmpty);
    expect(BodyMapWidget.musclesForGroup('Unbekannt'), contains('pectorals'));
  });

  test('musclesForGroup understands English seeder keys too', () {
    expect(BodyMapWidget.musclesForGroup('chest'), contains('pectorals'));
    expect(BodyMapWidget.musclesForGroup('back'), contains('lats'));
  });
}
