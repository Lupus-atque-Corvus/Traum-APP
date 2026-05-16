import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class HealthScoreResult {
  final int gesamtScore;
  final List<FaktorScore> faktoren;

  const HealthScoreResult({
    required this.gesamtScore,
    required this.faktoren,
  });

  FaktorScore get weakestFactor =>
      faktoren.reduce((a, b) => a.score < b.score ? a : b);

  FaktorScore get strongestFactor =>
      faktoren.reduce((a, b) => a.score > b.score ? a : b);
}

class FaktorScore {
  final String name;
  final int score;
  final double gewichtung;

  const FaktorScore({
    required this.name,
    required this.score,
    required this.gewichtung,
  });
}

String scoreLabel(int score) {
  if (score >= 85) return 'Sehr gut';
  if (score >= 70) return 'Gut';
  if (score >= 55) return 'Mittel';
  if (score >= 40) return 'Verbesserungsbedarf';
  return 'Kritisch';
}

Color scoreLabelColor(int score) {
  if (score >= 85) return TraumColors.mintGreen;
  if (score >= 70) return TraumColors.amberGold;
  if (score >= 55) return TraumColors.coralOrange;
  return TraumColors.roseRed;
}

String faktorBewertung(int score) {
  if (score >= 85) return 'Optimal';
  if (score >= 70) return 'Gut';
  if (score >= 55) return 'Mittel';
  return 'Schwach';
}

Color faktorFarbe(int score) {
  if (score >= 85) return TraumColors.mintGreen;
  if (score >= 70) return TraumColors.amberGold;
  if (score >= 55) return TraumColors.coralOrange;
  return TraumColors.roseRed;
}

String motivationstext(int score) {
  if (score >= 85) return 'Ausgezeichnet! Dein Koerper ist in Topform.';
  if (score >= 70) return 'Gut unterwegs! Kleine Optimierungen bringen dich weiter.';
  if (score >= 55) return 'Solide Basis. Fokussiere dich auf deine schwaechsten Bereiche.';
  if (score >= 40) return 'Es gibt Verbesserungspotenzial. Schau dir die Empfehlungen an.';
  return 'Dein Koerper braucht Aufmerksamkeit. Starte mit kleinen Schritten.';
}

IconData faktorIcon(String name) {
  switch (name) {
    case 'Training':        return Icons.fitness_center_rounded;
    case 'Ernährung':       return Icons.apple_rounded;
    case 'Regeneration':    return Icons.nightlight_round;
    case 'Supplemente':     return Icons.science_outlined;
    case 'Medikamente':     return Icons.medical_services_outlined;
    case 'Stress & Mental': return Icons.psychology_outlined;
    default:                return Icons.circle;
  }
}

Color faktorModulFarbe(String name) {
  switch (name) {
    case 'Training':        return TraumColors.coralOrange;
    case 'Ernährung':       return TraumColors.mintGreen;
    case 'Regeneration':    return TraumColors.cyanBlue;
    case 'Supplemente':     return TraumColors.indigoBlue;
    case 'Medikamente':     return TraumColors.roseRed;
    case 'Stress & Mental': return TraumColors.lavender;
    default:                return TraumColors.coralOrange;
  }
}

String faktorHinweis(String name) {
  switch (name) {
    case 'Training':        return 'Plane dein naechstes Workout und bleib aktiv.';
    case 'Ernährung':       return 'Tracke deine Mahlzeiten und triff dein Kalorienziel.';
    case 'Regeneration':    return 'Achte auf 7-9 Stunden Schlaf pro Nacht.';
    case 'Supplemente':     return 'Nimm deine heutigen Supplemente ein.';
    case 'Medikamente':     return 'Vergiss nicht, deine Medikamente zu nehmen.';
    case 'Stress & Mental': return 'Notiere deine heutige Stimmung und mach eine Pause.';
    default:                return 'Schaue dir die Details an.';
  }
}
