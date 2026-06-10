import 'package:flutter/material.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/components/components.dart';
import '../../../l10n/app_localizations.dart';

/// Modul-Picker. Auswahl bestimmt Detail-Seiten, Home-Widgets und Tab-Vorbelegung.
class InterestsPage extends StatelessWidget {
  final String? sex;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const InterestsPage({
    super.key,
    required this.sex,
    required this.selected,
    required this.onToggle,
    required this.onNext,
  });

  static const List<(String, IconData)> _modules = [
    ('training', Icons.fitness_center_rounded),
    ('health', Icons.favorite_rounded),
    ('nutrition', Icons.restaurant_rounded),
    ('supplements', Icons.science_rounded),
    ('medication', Icons.medication_rounded),
    ('substances', Icons.biotech_rounded),
    ('planning', Icons.checklist_rounded),
    ('abstinence', Icons.shield_rounded),
    ('budget', Icons.account_balance_wallet_rounded),
    ('diary', Icons.photo_camera_rounded),
    ('notes', Icons.notes_rounded),
    ('graffitiMap', Icons.map_rounded),
    ('period', Icons.water_drop_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final modules = _modules
        .where((e) => e.$1 != 'period' || sex == 'female')
        .toList();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l10n.obInterestsTitle,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 8),
          Text(l10n.obInterestsSubtitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  height: 1.5)),
          const SizedBox(height: 6),
          Text(l10n.obInterestsSelected(selected.length),
              style: const TextStyle(
                  fontSize: 12,
                  color: TraumColors.onBackgroundSubtle,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: modules.map((e) {
                  final module = e.$1;
                  final isSel = selected.contains(module);
                  final color = TraumColors.moduleColor(module);
                  return GestureDetector(
                    onTap: () => onToggle(module),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSel
                            ? color.withValues(alpha: 0.15)
                            : TraumColors.surface,
                        borderRadius:
                            BorderRadius.circular(TraumRadius.card),
                        border: Border.all(
                            color:
                                isSel ? color : TraumColors.surfaceVariant,
                            width: isSel ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(e.$2,
                              size: 20,
                              color: isSel
                                  ? color
                                  : TraumColors.onBackgroundMuted),
                          const SizedBox(width: 8),
                          Text(Routes.labelFor(module, l10n),
                              style: TextStyle(
                                  fontSize: 14,
                                  fontFamily: 'DMSans',
                                  fontWeight: isSel
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: isSel
                                      ? color
                                      : TraumColors.onBackgroundMuted)),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 12),
          GradientButton(label: l10n.next, onPressed: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
