/// Deterministic identifier for an exercise's bespoke icon asset, derived
/// purely from its display name. Used both at render time ([ExerciseIcon])
/// and by `tool/generate_exercise_icon_manifest.dart` — keeping this pure
/// (no Flutter import) lets the dev tool run under plain `dart run`.
library;

const Map<String, String> _transliterations = {
  'ä': 'ae',
  'ö': 'oe',
  'ü': 'ue',
  'ß': 'ss',
  'á': 'a',
  'à': 'a',
  'â': 'a',
  'é': 'e',
  'è': 'e',
  'ê': 'e',
  'í': 'i',
  'î': 'i',
  'ó': 'o',
  'ô': 'o',
  'ú': 'u',
  'û': 'u',
  'ñ': 'n',
  'ç': 'c',
};

/// Slugifies an exercise name into the key used to look up its bespoke SVG
/// asset (`assets/exercises/icons_exercise/<slug>.svg`). Stable for a given
/// name, but not guaranteed to survive a rename — see the dev tool's
/// orphan-detection step for that case.
String slugifyExerciseName(String name) {
  var s = name.toLowerCase().trim();
  _transliterations.forEach((raw, ascii) => s = s.replaceAll(raw, ascii));
  s = s.replaceAll(RegExp(r'[^a-z0-9]+'), '_');
  s = s.replaceAll(RegExp(r'^_+|_+$'), '');
  return s;
}
