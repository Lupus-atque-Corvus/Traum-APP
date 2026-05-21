import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'body_map_svg_data.dart';

class BodyMapWidget extends StatelessWidget {
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
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
    this.showBack = false,
    this.height = 260,
  });

  static List<String> musclesForGroup(String group) {
    switch (group.toLowerCase().trim()) {
      case 'brust':      return ['pectorals'];
      case 'rücken':     return ['lats', 'rhomboids', 'lower_back', 'trapezes'];
      case 'schulter':   return ['deltoids'];
      case 'bizeps':     return ['biceps'];
      case 'trizeps':    return ['triceps'];
      case 'bauch':      return ['abdominals', 'obliques'];
      case 'beine':      return ['quadriceps', 'hamstrings', 'hip_adductors', 'hip_abductors'];
      case 'gesäß':      return ['glutes'];
      case 'waden':      return ['calves'];
      case 'unterarme':  return ['forearms'];
      case 'ganzkörper': return allMuscles;
      default:           return [];
    }
  }

  String _buildSvg() {
    var svg = showBack ? BodyMapSvgData.maleBack : BodyMapSvgData.maleFront;
    for (final entry in _muscleDefaultColors.entries) {
      final muscle = entry.key;
      final defaultHex = entry.value;
      final String targetHex;
      if (primaryMuscles.contains(muscle)) {
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
