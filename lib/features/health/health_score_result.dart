import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

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

String scoreLabel(int score, [AppLocalizations? l10n]) {
  if (score >= 85) return l10n?.healthScoreLabelSehrGut ?? 'Sehr gut';
  if (score >= 70) return l10n?.healthScoreLabelGut ?? 'Gut';
  if (score >= 55) return l10n?.healthScoreLabelMittel ?? 'Mittel';
  if (score >= 40) return l10n?.healthScoreLabelVerbesserung ?? 'Verbesserungsbedarf';
  return l10n?.healthScoreLabelKritisch ?? 'Kritisch';
}

Color scoreLabelColor(int score) {
  if (score >= 85) return TraumColors.mintGreen;
  if (score >= 70) return TraumColors.amberGold;
  if (score >= 55) return TraumColors.coralOrange;
  return TraumColors.roseRed;
}

String faktorBewertung(int score, [AppLocalizations? l10n]) {
  if (score >= 85) return l10n?.healthScoreBewertungOptimal ?? 'Optimal';
  if (score >= 70) return l10n?.healthScoreBewertungGut ?? 'Gut';
  if (score >= 55) return l10n?.healthScoreBewertungMittel ?? 'Mittel';
  return l10n?.healthScoreBewertungSchwach ?? 'Schwach';
}

Color faktorFarbe(int score) {
  if (score >= 85) return TraumColors.mintGreen;
  if (score >= 70) return TraumColors.amberGold;
  if (score >= 55) return TraumColors.coralOrange;
  return TraumColors.roseRed;
}

String motivationstext(int score, [AppLocalizations? l10n]) {
  if (score >= 85) return l10n?.motivationExcellent ?? 'Ausgezeichnet! Dein Körper ist in Topform.';
  if (score >= 70) return l10n?.motivationGood ?? 'Gut unterwegs! Kleine Optimierungen bringen dich weiter.';
  if (score >= 55) return l10n?.motivationSolid ?? 'Solide Basis. Fokussiere dich auf deine schwächsten Bereiche.';
  if (score >= 40) return l10n?.motivationImprove ?? 'Es gibt Verbesserungspotenzial. Schau dir die Empfehlungen an.';
  return l10n?.motivationAttention ?? 'Dein Körper braucht Aufmerksamkeit. Starte mit kleinen Schritten.';
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

String faktorHinweis(String name, [AppLocalizations? l10n]) {
  switch (name) {
    case 'Training':        return l10n?.hintTraining ?? 'Plane dein nächstes Workout und bleib aktiv.';
    case 'Ernährung':       return l10n?.hintNutrition ?? 'Tracke deine Mahlzeiten und triff dein Kalorienziel.';
    case 'Regeneration':    return l10n?.hintRegeneration ?? 'Achte auf 7–9 Stunden Schlaf pro Nacht.';
    case 'Supplemente':     return l10n?.hintSupplements ?? 'Nimm deine heutigen Supplemente ein.';
    case 'Medikamente':     return l10n?.hintMedication ?? 'Vergiss nicht, deine Medikamente zu nehmen.';
    case 'Stress & Mental': return l10n?.hintMentalStress ?? 'Notiere deine heutige Stimmung und mach eine Pause.';
    default:                return l10n?.hintDefault ?? 'Schau dir die Details an.';
  }
}
