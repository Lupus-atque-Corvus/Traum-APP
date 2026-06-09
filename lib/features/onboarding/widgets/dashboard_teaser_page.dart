import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../../../core/components/components.dart';
import '../../../l10n/app_localizations.dart';

class DashboardTeaserPage extends StatelessWidget {
  final VoidCallback onNext;
  const DashboardTeaserPage({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    const accent = TraumColors.coralOrange;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          const SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: TraumColors.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: TraumColors.surfaceVariant),
                      ),
                      child: Column(
                        children: [
                          _mockRow([2]),
                          const SizedBox(height: 8),
                          _mockRow([1, 1]),
                          const SizedBox(height: 8),
                          _mockRow([1, 1]),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(l10n.obDashboardTitle,
                      style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans')),
                  const SizedBox(height: 8),
                  Text(l10n.obDashboardSubtitle,
                      style: const TextStyle(
                          fontSize: 14,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans')),
                  const SizedBox(height: 20),
                  for (final f in [
                    l10n.obDashboardFeature1,
                    l10n.obDashboardFeature2,
                    l10n.obDashboardFeature3,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(children: [
                        const Icon(Icons.check_circle_rounded,
                            color: accent, size: 22),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Text(f,
                                style: const TextStyle(
                                    fontSize: 14,
                                    color: TraumColors.onBackground,
                                    fontFamily: 'DMSans'))),
                      ]),
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: TraumColors.coralDim,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(l10n.obDashboardSeeded,
                        style: const TextStyle(
                            color: TraumColors.peachOrange,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                  ),
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

  Widget _mockRow(List<int> flexes) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          for (var i = 0; i < flexes.length; i++) ...[
            Expanded(
              flex: flexes[i],
              child: Container(
                decoration: BoxDecoration(
                  gradient: TraumColors.gradientWarm,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            if (i != flexes.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
