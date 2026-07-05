import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/training/muscle_groups.dart';
import 'package:traum/l10n/app_localizations_de.dart';
import 'package:traum/l10n/app_localizations_en.dart';

void main() {
  test('german and english keys normalize identically', () {
    expect(canonicalMuscleGroup('Brust'), 'chest');
    expect(canonicalMuscleGroup('chest'), 'chest');
    expect(canonicalMuscleGroup('Rücken'), 'back');
    expect(canonicalMuscleGroup('Gesäß'), 'glutes');
    expect(canonicalMuscleGroup('Waden'), 'calves');
    expect(canonicalMuscleGroup('Ganzkörper'), 'full_body');
    expect(canonicalMuscleGroup('unbekannt'), 'full_body');
  });

  test('body map mapping covers every canonical group', () {
    for (final g in kAllMuscleGroups) {
      expect(bodyMapMusclesFor(g), isNotEmpty, reason: g);
    }
  });

  test('additional german/english normalize cases', () {
    expect(canonicalMuscleGroup('Bizeps'), 'biceps');
    expect(canonicalMuscleGroup('biceps'), 'biceps');
    expect(canonicalMuscleGroup('Ganzkörper'), 'full_body');
    expect(canonicalMuscleGroup('Trizeps'), 'triceps');
    expect(canonicalMuscleGroup('triceps'), 'triceps');
    expect(canonicalMuscleGroup('Schulter'), 'shoulders');
    expect(canonicalMuscleGroup('shoulders'), 'shoulders');
    expect(canonicalMuscleGroup('Bauch'), 'core');
    expect(canonicalMuscleGroup('core'), 'core');
    expect(canonicalMuscleGroup('Beine'), 'legs');
    expect(canonicalMuscleGroup('legs'), 'legs');
    expect(canonicalMuscleGroup('Unterarme'), 'forearms');
    expect(canonicalMuscleGroup('forearms'), 'forearms');
    expect(canonicalMuscleGroup('cardio'), 'cardio');
    expect(canonicalMuscleGroup('stretching'), 'full_body');
    // casing shouldn't matter
    expect(canonicalMuscleGroup('CHEST'), 'chest');
    expect(canonicalMuscleGroup('  chest  '), 'chest');
  });

  test('canonicalMuscleGroup is idempotent for every canonical key', () {
    for (final g in kAllMuscleGroups) {
      expect(canonicalMuscleGroup(g), g, reason: g);
    }
  });

  test('muscleGroupLabel returns a non-empty label for every canonical group (de+en)', () {
    final de = AppLocalizationsDe();
    final en = AppLocalizationsEn();
    for (final g in kAllMuscleGroups) {
      expect(muscleGroupLabel(g, de), isNotEmpty, reason: 'de:$g');
      expect(muscleGroupLabel(g, en), isNotEmpty, reason: 'en:$g');
    }
  });
}
