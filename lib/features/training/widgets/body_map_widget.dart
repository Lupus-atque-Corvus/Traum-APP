import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../muscle_groups.dart';
import 'body_map_svg_data.dart';

class BodyMapWidget extends StatelessWidget {
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final Map<String, DateTime>? heatMap;
  final bool showBack;
  final double height;

  static const Map<String, String> _muscleDefaultColors = {
    'pectorals':     '#e9252f',
    'lower_back':    '#8b8ddf',
    'rhomboids':     '#67368e',
    'lats':          '#404bb4',
    'trapezes':      '#9f4b9f',
    'deltoids':      '#e96325',
    'triceps':       '#fff74c',
    'biceps':        '#ffd34c',
    'forearms':      '#f5ef73',
    'abdominals':    '#5a8fc3',
    'obliques':      '#215d97',
    'glutes':        '#309f97',
    'quadriceps':    '#36b574',
    'hip_adductors': '#7de0ae',
    'hip_abductors': '#78d7d0',
    'hamstrings':    '#51ac7e',
    'calves':        '#9dc643',
  };

  static const List<String> allMuscles = [
    'pectorals', 'lower_back', 'rhomboids', 'lats', 'trapezes',
    'deltoids', 'triceps', 'biceps', 'forearms', 'abdominals',
    'obliques', 'glutes', 'quadriceps', 'hip_adductors',
    'hip_abductors', 'hamstrings', 'calves',
  ];

  const BodyMapWidget({
    super.key,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    this.heatMap,
    this.showBack = false,
    this.height = 260,
  });

  /// Delegates to the canonical normalization + body-map mapping in
  /// `muscle_groups.dart` (Bugfix Audit 6.1: this used to only understand
  /// German keys, so it returned [] for the English keys the
  /// ExerciseSeeder actually stores). Still accepts whatever it accepted
  /// before (German or English, any casing) — canonicalization is
  /// backward-compatible.
  static List<String> musclesForGroup(String group) =>
      bodyMapMusclesFor(canonicalMuscleGroup(group));

  // Heat-map hex colors by recency
  static String _heatHex(DateTime? lastTrained) {
    if (lastTrained == null) return '#2A2A3D';
    final hours = DateTime.now().difference(lastTrained).inHours;
    if (hours <= 24) return '#E97B4A';  // bright orange
    if (hours <= 48) return '#A0442A';  // medium
    if (hours <= 72) return '#5C2116';  // dark red-brown
    return '#2A2A3D';
  }

  String _buildSvg() {
    var svg = showBack ? BodyMapSvgData.maleBack : BodyMapSvgData.maleFront;
    for (final entry in _muscleDefaultColors.entries) {
      final muscle = entry.key;
      final defaultHex = entry.value;
      final String targetHex;
      if (heatMap != null) {
        targetHex = _heatHex(heatMap![muscle]);
      } else if (primaryMuscles.contains(muscle)) {
        targetHex = '#FF4D4D';
      } else if (secondaryMuscles.contains(muscle)) {
        targetHex = '#FFD34C';
      } else {
        targetHex = '#2A2A3D';
      }
      svg = svg.replaceAll('fill:$defaultHex', 'fill:$targetHex');
    }
    return svg;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: SvgPicture.string(
        _buildSvg(),
        fit: BoxFit.contain,
      ),
    );
  }
}
