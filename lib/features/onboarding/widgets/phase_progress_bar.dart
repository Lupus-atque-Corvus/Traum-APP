import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../onboarding_models.dart';

class PhaseProgressBar extends StatelessWidget {
  /// Aktuelle Phase.
  final OnboardingPhase current;
  /// Fortschritt innerhalb der aktuellen Phase (0..1).
  final double phaseProgress;

  const PhaseProgressBar({
    super.key,
    required this.current,
    required this.phaseProgress,
  });

  @override
  Widget build(BuildContext context) {
    final phases = OnboardingPhase.values;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      child: Row(
        children: [
          for (final p in phases) ...[
            Expanded(
              child: _Segment(
                key: const ValueKey('phase-segment'),
                fill: p.index < current.index
                    ? 1.0
                    : p.index == current.index
                        ? phaseProgress.clamp(0.0, 1.0)
                        : 0.0,
              ),
            ),
            if (p != phases.last) const SizedBox(width: 6),
          ],
        ],
      ),
    );
  }
}

class _Segment extends StatelessWidget {
  final double fill;
  const _Segment({super.key, required this.fill});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(3),
      child: Stack(
        children: [
          Container(height: 6, color: TraumColors.surfaceVariant),
          AnimatedFractionallySizedBox(
            duration: const Duration(milliseconds: 300),
            widthFactor: fill,
            child: Container(
              height: 6,
              decoration: const BoxDecoration(gradient: TraumColors.gradientWarm),
            ),
          ),
        ],
      ),
    );
  }
}
