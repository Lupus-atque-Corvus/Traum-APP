import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/database/traum_database.dart';
import 'package:traum/features/training/exercise_search.dart';

Exercise _ex(int id, String name, {String muscleGroup = 'chest'}) => Exercise(
      id: id,
      name: name,
      muscleGroup: muscleGroup,
      primaryMuscles: '[]',
      secondaryMuscles: '[]',
      isBookmarked: false,
      isCustom: false,
    );

void main() {
  group('filterExercisesByQuery', () {
    final exercises = [
      _ex(1, 'Bankdrücken'),
      _ex(2, 'Kniebeuge', muscleGroup: 'legs'),
      _ex(3, 'Klimmzug', muscleGroup: 'back'),
    ];

    test('returns all exercises for an empty query', () {
      expect(filterExercisesByQuery(exercises, ''), exercises);
    });

    test('returns all exercises for a whitespace-only query', () {
      expect(filterExercisesByQuery(exercises, '   '), exercises);
    });

    test('matches case-insensitively as a substring', () {
      final result = filterExercisesByQuery(exercises, 'bank');
      expect(result.map((e) => e.name), ['Bankdrücken']);
    });

    test('matches a substring in the middle of the name', () {
      final result = filterExercisesByQuery(exercises, 'iebeu');
      expect(result.map((e) => e.name), ['Kniebeuge']);
    });

    test('returns an empty list when nothing matches', () {
      expect(filterExercisesByQuery(exercises, 'xyz'), isEmpty);
    });
  });
}
