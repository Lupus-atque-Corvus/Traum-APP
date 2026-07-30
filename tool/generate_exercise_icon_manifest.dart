// Dev tool (not part of the app runtime / build_runner) — regenerates
// lib/features/training/widgets/generated/exercise_icon_manifest.dart from
// whatever bespoke SVGs currently sit in assets/exercises/icons_exercise/.
//
// Run from the traum_app directory:
//   dart run tool/generate_exercise_icon_manifest.dart
// ignore_for_file: avoid_print
import 'dart:convert';
import 'dart:io';

import 'package:traum/features/training/exercise_icon_slug.dart';

const _seedFiles = [
  'assets/exercises/chest.json',
  'assets/exercises/back.json',
  'assets/exercises/shoulders.json',
  'assets/exercises/biceps.json',
  'assets/exercises/triceps.json',
  'assets/exercises/legs.json',
  'assets/exercises/core.json',
  'assets/exercises/cardio.json',
  'assets/exercises/full_body.json',
  'assets/exercises/stretching.json',
  'assets/exercises/exercises_extended.json',
];

const _iconDir = 'assets/exercises/icons_exercise';
const _manifestPath =
    'lib/features/training/widgets/generated/exercise_icon_manifest.dart';

void main() {
  final names = <String>{};
  for (final path in _seedFiles) {
    final file = File(path);
    if (!file.existsSync()) {
      stderr.writeln('Warning: seed file not found: $path');
      continue;
    }
    final list = jsonDecode(file.readAsStringSync()) as List;
    for (final entry in list) {
      names.add((entry as Map<String, dynamic>)['name'] as String);
    }
  }

  final slugToNames = <String, List<String>>{};
  for (final n in names) {
    slugToNames.putIfAbsent(slugifyExerciseName(n), () => []).add(n);
  }
  // Non-fatal: two names collapsing to the same slug is usually the same
  // exercise spelled two ways across the curated + wger-extended seed data
  // (e.g. "Klimmzuege"/"Klimmzüge") — sharing one bespoke icon between them
  // is correct, not a bug. Warn so it's visible, but don't block the run.
  final collisions = slugToNames.entries.where((e) => e.value.length > 1);
  for (final c in collisions) {
    stderr.writeln('Note: slug "${c.key}" shared by multiple names: ${c.value}');
  }

  final iconDir = Directory(_iconDir);
  final produced = iconDir.existsSync()
      ? iconDir
          .listSync()
          .whereType<File>()
          .where((f) => f.path.endsWith('.svg'))
          .map((f) => f.uri.pathSegments.last.replaceAll('.svg', ''))
          .toSet()
      : <String>{};

  final knownSlugs = slugToNames.keys.toSet();
  final orphans = produced.difference(knownSlugs);
  if (orphans.isNotEmpty) {
    stderr.writeln(
        'Warning: icon files with no matching current exercise name '
        '(renamed/removed exercise?): $orphans');
  }

  final done = produced.intersection(knownSlugs).toList()..sort();

  final buf = StringBuffer()
    ..writeln('// GENERATED FILE — do not hand-edit.')
    ..writeln(
        '// Regenerate with: dart run tool/generate_exercise_icon_manifest.dart')
    ..writeln('//')
    ..writeln('// Slugs (see exercise_icon_slug.dart) of exercises that have a bespoke')
    ..writeln('// hand-illustrated icon at assets/exercises/icons_exercise/<slug>.svg.')
    ..writeln('// Empty until the first illustration batch lands — ExerciseIcon falls back')
    ..writeln('// to the generic per-muscle-group icon for any slug not in this set.')
    ..writeln('const Set<String> kExerciseIconSlugs = {')
    ..writeAll(done.map((s) => "  '$s',\n"))
    ..writeln('};');

  File(_manifestPath).writeAsStringSync(buf.toString());

  print('Bespoke icons: ${done.length} / ${knownSlugs.length} exercises done '
      '(${knownSlugs.length - done.length} pending).');
}
