import '../../data/database/traum_database.dart';

/// Case-insensitive substring match on the exercise name — the single
/// definition shared by the library, picker, and wizard exercise search UIs
/// (previously three near-identical copies of the same `.where(...)`).
List<Exercise> filterExercisesByQuery(List<Exercise> exercises, String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return exercises;
  return exercises.where((e) => e.name.toLowerCase().contains(q)).toList();
}
