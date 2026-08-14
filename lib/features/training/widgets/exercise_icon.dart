import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vector_graphics/vector_graphics.dart';

import '../exercise_icon_slug.dart';
import 'generated/exercise_icon_manifest.dart';

class ExerciseIcon extends StatelessWidget {
  final String muscleGroup;
  final double size;

  /// Exercise display name, if this icon represents one specific exercise
  /// (as opposed to a bare muscle-group icon, e.g. the heatmap legend).
  /// When set and a bespoke illustration exists for it, that is rendered
  /// instead of the generic muscle-group icon.
  final String? exerciseName;

  const ExerciseIcon({
    super.key,
    required this.muscleGroup,
    this.size = 44,
    this.exerciseName,
  });

  /// Vorkompilierte Vektorgrafiken (.vec) der 838 bespoke Übungs-Icons.
  /// Die .svg-Quellen liegen weiterhin unter `assets/exercises/icons_exercise/`
  /// im Repo, werden aber nicht mit ausgeliefert: das Binärformat ist bereits
  /// geparst, wodurch beim Scrollen durch die Übungsliste kein XML- und
  /// Pfad-Parsing mehr pro Zeile anfällt (die SVGs sind im Schnitt ~24 KB groß).
  static const String _bespokeDir = 'assets/exercises/icons_exercise_vec';

  static const Map<String, String> _assetMap = {
    'chest': 'assets/exercises/icons/chest.svg',
    'back': 'assets/exercises/icons/back.svg',
    'shoulders': 'assets/exercises/icons/shoulders.svg',
    'biceps': 'assets/exercises/icons/biceps.svg',
    'triceps': 'assets/exercises/icons/triceps.svg',
    'legs': 'assets/exercises/icons/legs.svg',
    'core': 'assets/exercises/icons/core.svg',
    'cardio': 'assets/exercises/icons/cardio.svg',
    'full_body': 'assets/exercises/icons/full_body.svg',
  };

  static const Map<String, Color> _colorMap = {
    'chest': Color(0xFFFF6B6B),
    'back': Color(0xFF4ECDC4),
    'shoulders': Color(0xFFA78BFA),
    'biceps': Color(0xFFF59E0B),
    'triceps': Color(0xFFFB923C),
    'legs': Color(0xFF60A5FA),
    'core': Color(0xFF34D399),
    'cardio': Color(0xFFF472B6),
    'full_body': Color(0xFF94A3B8),
  };

  static Color muscleGroupColor(String muscleGroup) =>
      _colorMap[muscleGroup] ?? const Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context) {
    String? bespokeAsset;
    final name = exerciseName;
    if (name != null) {
      final slug = slugifyExerciseName(name);
      if (kExerciseIconSlugs.contains(slug)) {
        // Der Compiler hängt `.vec` an den vollständigen Quellnamen an,
        // daher `<slug>.svg.vec`.
        bespokeAsset = '$_bespokeDir/$slug.svg.vec';
      }
    }
    final color = muscleGroupColor(muscleGroup);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        // Bespoke Übungs-Icons als vorkompilierte Vektorgrafik, die generischen
        // Muskelgruppen-Icons (9 Stück, sehr klein) weiterhin als SVG.
        child: bespokeAsset != null
            ? VectorGraphic(loader: AssetBytesLoader(bespokeAsset))
            : SvgPicture.asset(
                _assetMap[muscleGroup] ?? _assetMap['full_body']!,
              ),
      ),
    );
  }
}
