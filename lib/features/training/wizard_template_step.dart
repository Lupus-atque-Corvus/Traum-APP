import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/repositories/plan_templates.dart';

class WizardTemplateStep extends StatelessWidget {
  final PlanTemplate? selected;
  final ValueChanged<PlanTemplate> onSelect;

  const WizardTemplateStep({
    super.key,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vorlage waehlen',
          style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        const Text(
          'Waehle einen bewaehrten Plan oder erstelle deinen eigenen.',
          style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...PlanTemplates.all.map((t) => _TemplateCard(
          template: t,
          isSelected: selected?.id == t.id,
          onTap: () => onSelect(t),
        )),
      ],
    );
  }
}

class _TemplateCard extends StatelessWidget {
  final PlanTemplate template;
  final bool isSelected;
  final VoidCallback onTap;

  const _TemplateCard({
    required this.template,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? TraumColors.coralOrange.withValues(alpha: 0.12)
              : TraumColors.surface,
          borderRadius: BorderRadius.circular(TraumRadius.card),
          border: Border.all(
            color: isSelected
                ? TraumColors.coralOrange
                : TraumColors.surface,
            width: 1.5,
          ),
        ),
        child: Row(children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  template.name,
                  style: TextStyle(
                      color: isSelected
                          ? TraumColors.coralOrange
                          : TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15),
                ),
                const SizedBox(height: 3),
                Text(
                  template.subtitle,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 13),
                ),
              ],
            ),
          ),
          if (isSelected)
            const Icon(Icons.check_circle_rounded,
                color: TraumColors.coralOrange, size: 22),
        ]),
      ),
    );
  }
}
