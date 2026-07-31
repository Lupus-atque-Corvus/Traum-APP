import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';
import 'package:traum/features/training/exercise_icon_slug.dart';
import 'package:traum/features/training/widgets/exercise_icon.dart';
import 'package:traum/features/training/widgets/generated/exercise_icon_manifest.dart';

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

  testWidgets(
      'renders a precompiled VectorGraphic (not SvgPicture) for an exercise '
      'that has a bespoke icon', (tester) async {
    // Übungsname, dessen Slug im Manifest steht — nur dann greift der
    // bespoke-Pfad.
    const name = '2 Handed Kettlebell Swing';
    expect(kExerciseIconSlugs, contains(slugifyExerciseName(name)));

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExerciseIcon(muscleGroup: 'full_body', exerciseName: name),
        ),
      ),
    );

    // Hinweis: `SvgPicture` rendert intern ebenfalls ein `VectorGraphic`.
    // Aussagekräftig ist deshalb die Abwesenheit von `SvgPicture` — nur dann
    // wird die vorkompilierte .vec-Datei direkt geladen, ohne SVG-Parsing.
    expect(find.byType(VectorGraphic), findsOneWidget);
    expect(find.byType(SvgPicture), findsNothing);
  });

  testWidgets(
      'falls back to the generic muscle-group SVG when no bespoke icon exists',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ExerciseIcon(
              muscleGroup: 'chest', exerciseName: 'Völlig Erfundene Übung XYZ'),
        ),
      ),
    );

    // Kein `findsNothing` auf VectorGraphic: SvgPicture rendert intern selbst
    // eines. Entscheidend ist, dass hier überhaupt der SvgPicture-Zweig greift.
    expect(find.byType(SvgPicture), findsOneWidget);
  });

  test('für jeden Slug im Manifest existiert eine kompilierte .vec-Datei', () {
    // Schützt davor, dass ein neuer Übungs-Icon-Batch zwar ins Manifest
    // wandert, aber nie durch den vector_graphics_compiler gelaufen ist —
    // das würde zur Laufzeit als fehlendes Asset auffallen, nicht im Test.
    final missing = <String>[];
    for (final slug in kExerciseIconSlugs) {
      final f = File('assets/exercises/icons_exercise_vec/$slug.svg.vec');
      if (!f.existsSync()) missing.add(slug);
    }
    expect(missing, isEmpty,
        reason: 'Nicht kompilierte Icons: ${missing.take(5).join(', ')}');
  });

  test('muscleGroupColor returns correct color for chest', () {
    expect(ExerciseIcon.muscleGroupColor('chest'), const Color(0xFFFF6B6B));
  });

  test('muscleGroupColor returns fallback color for unknown group', () {
    expect(ExerciseIcon.muscleGroupColor('unknown'), const Color(0xFF94A3B8));
  });
}
