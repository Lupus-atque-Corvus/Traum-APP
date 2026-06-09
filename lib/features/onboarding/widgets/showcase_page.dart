import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/components/components.dart';
import '../../../l10n/app_localizations.dart';

/// Beschreibt den statischen Inhalt einer Showcase-Seite.
class _Showcase {
  final IconData icon;
  final Color color;
  final Gradient gradient;
  final String Function(AppLocalizations) title;
  final String Function(AppLocalizations) subtitle;
  final List<String Function(AppLocalizations)> features;
  const _Showcase(this.icon, this.color, this.gradient, this.title,
      this.subtitle, this.features);
}

final Map<String, _Showcase> _kShowcases = {
  'substances': _Showcase(
    Icons.science_rounded, TraumColors.indigoBlue, TraumColors.gradientSupplements,
    (l) => l.obSubstancesTitle, (l) => l.obSubstancesSubtitle,
    [(l) => l.obSubstancesFeature1, (l) => l.obSubstancesFeature2, (l) => l.obSubstancesFeature3]),
  'planning': _Showcase(
    Icons.checklist_rounded, TraumColors.lavender, TraumColors.gradientPlanning,
    (l) => l.obPlanningTitle, (l) => l.obPlanningSubtitle,
    [(l) => l.obPlanningFeature1, (l) => l.obPlanningFeature2, (l) => l.obPlanningFeature3]),
  'diary': _Showcase(
    Icons.photo_camera_rounded, TraumColors.peachOrange, TraumColors.gradientWarm,
    (l) => l.obDiaryTitle, (l) => l.obDiarySubtitle,
    [(l) => l.obDiaryFeature1, (l) => l.obDiaryFeature2, (l) => l.obDiaryFeature3]),
  'notes': _Showcase(
    Icons.notes_rounded, TraumColors.lavender, TraumColors.gradientPlanning,
    (l) => l.obNotesTitle, (l) => l.obNotesSubtitle,
    [(l) => l.obNotesFeature1, (l) => l.obNotesFeature2, (l) => l.obNotesFeature3]),
  'graffitiMap': _Showcase(
    Icons.map_rounded, TraumColors.cyanBlue, TraumColors.gradientCool,
    (l) => l.obMapTitle, (l) => l.obMapSubtitle,
    [(l) => l.obMapFeature1, (l) => l.obMapFeature2, (l) => l.obMapFeature3]),
  'healthScore': _Showcase(
    Icons.favorite_rounded, TraumColors.cyanBlue, TraumColors.gradientCool,
    (l) => l.obHealthScoreTitle, (l) => l.obHealthScoreSubtitle,
    [(l) => l.obHealthScoreFeature1, (l) => l.obHealthScoreFeature2, (l) => l.obHealthScoreFeature3]),
};

class ShowcasePage extends StatelessWidget {
  final String moduleKey;
  final VoidCallback onNext;
  const ShowcasePage({super.key, required this.moduleKey, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final s = _kShowcases[moduleKey]!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  Container(
                    width: 88, height: 88,
                    decoration: BoxDecoration(
                      gradient: s.gradient,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: Icon(s.icon, color: Colors.white, size: 44),
                  ),
                  const SizedBox(height: 20),
                  Text(s.title(l10n),
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.w700,
                          color: TraumColors.onBackground, fontFamily: 'DMSans'),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(s.subtitle(l10n),
                      style: const TextStyle(
                          fontSize: 14, color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans', height: 1.5),
                      textAlign: TextAlign.center),
                  const SizedBox(height: 24),
                  ...s.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Icon(Icons.check_circle_rounded, color: s.color, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(f(l10n),
                                  style: const TextStyle(
                                      fontSize: 14, color: TraumColors.onBackground,
                                      fontFamily: 'DMSans')),
                            ),
                          ],
                        ),
                      )),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(label: l10n.obUnderstood, onPressed: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
