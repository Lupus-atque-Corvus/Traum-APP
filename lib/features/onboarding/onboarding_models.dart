import 'package:flutter/material.dart';

/// Phasen für die segmentierte Fortschrittsleiste.
enum OnboardingPhase { basis, interests, permissions, security }

/// Inhalt einer datengetriebenen Showcase-Seite.
class ModuleShowcase {
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final String Function(dynamic l10n) title;
  final String Function(dynamic l10n) subtitle;
  final List<String Function(dynamic l10n)> features;

  const ModuleShowcase({
    required this.icon,
    required this.color,
    required this.gradient,
    required this.title,
    required this.subtitle,
    required this.features,
  });
}
