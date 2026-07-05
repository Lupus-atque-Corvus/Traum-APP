/// Canonical muscle-group keys used across the training feature.
///
/// Root-cause fix (Audit 6.1): `ExerciseSeeder` stores ENGLISH muscle keys
/// (chest/back/shoulders/…) while several read-side consumers (body map,
/// heatmap, session/plan detail icons) expected GERMAN keys
/// (brust/rücken/…) — or vice-versa — causing silent lookup misses (empty
/// heatmap, wrong/generic icons). This module is the single normalization
/// point: every raw muscle-group string (however it entered the DB — from
/// the seeder in English, or from legacy/custom German-keyed data) is
/// converted to one of the canonical English keys below before it is used
/// for counting, body-map lookups, icons or labels.
library;

import '../../l10n/app_localizations.dart';

/// Canonical keys, in display order.
const List<String> kAllMuscleGroups = [
  'chest',
  'back',
  'shoulders',
  'biceps',
  'triceps',
  'core',
  'legs',
  'glutes',
  'calves',
  'forearms',
  'cardio',
  'full_body',
];

/// Raw (German legacy + English seeder) keys → canonical English key.
/// Lower-cased lookup; canonical keys map to themselves (idempotent).
const Map<String, String> _rawToCanonical = {
  // Canonical (identity) — keeps canonicalMuscleGroup idempotent.
  'chest': 'chest',
  'back': 'back',
  'shoulders': 'shoulders',
  'biceps': 'biceps',
  'triceps': 'triceps',
  'core': 'core',
  'legs': 'legs',
  'glutes': 'glutes',
  'calves': 'calves',
  'forearms': 'forearms',
  'cardio': 'cardio',
  'full_body': 'full_body',

  // English seeder extras.
  'stretching': 'full_body',

  // German legacy keys (see former body_map_widget.dart:48-63 switch and
  // the local `_muscleGroupKey` helpers in session/plan detail screens).
  'brust': 'chest',
  'rücken': 'back',
  'schulter': 'shoulders',
  'schultern': 'shoulders',
  'bizeps': 'biceps',
  'trizeps': 'triceps',
  'bauch': 'core',
  'beine': 'legs',
  'gesäß': 'glutes',
  'gesaess': 'glutes',
  'waden': 'calves',
  'unterarme': 'forearms',
  'ganzkörper': 'full_body',
  'ganzkoerper': 'full_body',
};

/// Normalizes any raw muscle-group string (German or English, any casing)
/// to a canonical English key. Unknown values fall back to 'full_body'
/// (matching the existing "generic/whole-body icon" fallback behavior of
/// [ExerciseIcon] rather than silently matching nothing).
String canonicalMuscleGroup(String raw) {
  final key = raw.toLowerCase().trim();
  return _rawToCanonical[key] ?? 'full_body';
}

/// All muscle names known to the body-map SVG (front + back), taken from
/// `BodyMapWidget.allMuscles`. Duplicated here (rather than imported) to
/// avoid a dependency from this pure-logic module onto the widget layer.
const List<String> _allBodyMapMuscles = [
  'pectorals', 'lower_back', 'rhomboids', 'lats', 'trapezes',
  'deltoids', 'triceps', 'biceps', 'forearms', 'abdominals',
  'obliques', 'glutes', 'quadriceps', 'hip_adductors',
  'hip_abductors', 'hamstrings', 'calves',
];

/// Canonical muscle-group key → body-map SVG muscle names to highlight.
/// Re-keyed (English) version of the legacy German switch that used to
/// live in `body_map_widget.dart:48-63`. Every entry in [kAllMuscleGroups]
/// resolves to a non-empty list — groups without a distinct body-map
/// region (cardio has no single muscle region; it's a whole-body/heart
/// activity) fall back to the full-body region set rather than [].
const Map<String, List<String>> _canonicalToBodyMapMuscles = {
  'chest': ['pectorals'],
  'back': ['lats', 'rhomboids', 'lower_back', 'trapezes'],
  'shoulders': ['deltoids'],
  'biceps': ['biceps'],
  'triceps': ['triceps'],
  'core': ['abdominals', 'obliques'],
  'legs': ['quadriceps', 'hamstrings', 'hip_adductors', 'hip_abductors'],
  'glutes': ['glutes'],
  'calves': ['calves'],
  'forearms': ['forearms'],
  // No distinct cardio region on the body map — highlight the whole body.
  'cardio': _allBodyMapMuscles,
  'full_body': _allBodyMapMuscles,
};

/// Body-map muscle names for a canonical muscle-group key. If [canonical]
/// isn't already canonical, it is normalized first, so this is safe to
/// call with raw (German/English) input too.
List<String> bodyMapMusclesFor(String canonical) {
  final key = canonicalMuscleGroup(canonical);
  return _canonicalToBodyMapMuscles[key] ?? _allBodyMapMuscles;
}

/// Localized display label for a canonical muscle-group key.
String muscleGroupLabel(String canonical, AppLocalizations l10n) {
  final key = canonicalMuscleGroup(canonical);
  switch (key) {
    case 'chest': return l10n.muscleBrust;
    case 'back': return l10n.muscleRuecken;
    case 'shoulders': return l10n.muscleSchulter;
    case 'biceps': return l10n.muscleBizeps;
    case 'triceps': return l10n.muscleTrizeps;
    case 'core': return l10n.muscleBauch;
    case 'legs': return l10n.muscleBeine;
    case 'glutes': return l10n.muscleGesaess;
    case 'calves': return l10n.muscleWaden;
    case 'forearms': return l10n.muscleForearms;
    case 'cardio': return l10n.muscleCardio;
    case 'full_body': default: return l10n.muscleGanzkoerper;
  }
}
