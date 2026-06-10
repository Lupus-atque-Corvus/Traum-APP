import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/components/components.dart';
import '../../../core/navigation/routes.dart';
import '../../../l10n/app_localizations.dart';

/// Lässt den Nutzer genau 4 Module für die Bottom-Bar anheften.
class TabsPage extends StatelessWidget {
  final List<String> candidates;
  final List<String> selectedSlots; // max 4
  final ValueChanged<String> onToggle;
  final VoidCallback onNext;

  const TabsPage({
    super.key,
    required this.candidates,
    required this.selectedSlots,
    required this.onToggle,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(l10n.obTabsTitle,
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans')),
          const SizedBox(height: 8),
          Text(l10n.obTabsSubtitle,
              style: const TextStyle(
                  fontSize: 14,
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  height: 1.5)),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: candidates.map((module) {
                  final isSel = selectedSlots.contains(module);
                  final canAdd = selectedSlots.length < 4;
                  final color = TraumColors.moduleColor(module);
                  return GestureDetector(
                    onTap: () {
                      if (isSel || canAdd) onToggle(module);
                    },
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
                            color: isSel
                                ? color
                                : TraumColors.surfaceVariant,
                            width: isSel ? 1.5 : 1),
                      ),
                      child: Text(Routes.labelFor(module, l10n),
                          style: TextStyle(
                              fontSize: 14,
                              fontFamily: 'DMSans',
                              fontWeight: isSel
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSel
                                  ? color
                                  : canAdd
                                      ? TraumColors.onBackgroundMuted
                                      : TraumColors.onBackgroundSubtle)),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.surfaceVariant.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(l10n.obTabsHint,
                style: const TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
          ),
          const SizedBox(height: 12),
          GradientButton(label: l10n.next, onPressed: onNext),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
