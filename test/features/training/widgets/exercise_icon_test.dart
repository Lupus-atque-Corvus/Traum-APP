import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:traum/features/training/widgets/exercise_icon.dart';

void main() {
  testWidgets('renders SvgPicture for known muscle group', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseIcon(muscleGroup: 'chest'))),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  testWidgets('renders SvgPicture for unknown muscle group (fallback)', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ExerciseIcon(muscleGroup: 'unknown_group'))),
    );
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('muscleGroupColor returns correct color for chest', () {
    expect(ExerciseIcon.muscleGroupColor('chest'), const Color(0xFFFF6B6B));
  });

  test('muscleGroupColor returns fallback color for unknown group', () {
    expect(ExerciseIcon.muscleGroupColor('unknown'), const Color(0xFF94A3B8));
  });
}
