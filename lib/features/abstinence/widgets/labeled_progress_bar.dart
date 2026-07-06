import 'package:flutter/material.dart';
import '../../../core/components/gradient_progress_bar.dart';
import '../../../core/theme/colors.dart';

/// A row with a name + percent header, a gradient-filled progress bar, and
/// an optional meta line below (e.g. "€120 von €500" or "12/20 Tage").
///
/// Wraps the shared `GradientProgressBar` (core/components) rather than
/// reimplementing bar-fill rendering.
class LabeledProgressBar extends StatelessWidget {
  final String name;
  final double value;
  final String? metaLine;
  final LinearGradient gradient;
  final double barHeight;

  const LabeledProgressBar({
    super.key,
    required this.name,
    required this.value,
    this.metaLine,
    this.gradient = TraumColors.gradientWarm,
    this.barHeight = 8,
  });

  @override
  Widget build(BuildContext context) {
    final percent = (value.clamp(0.0, 1.0) * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: TraumColors.onBackground,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: TextStyle(
                fontFamily: 'DMSans',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: gradient.colors.first,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        GradientProgressBar(
          value: value,
          gradient: gradient,
          height: barHeight,
        ),
        if (metaLine != null) ...[
          const SizedBox(height: 4),
          Text(
            metaLine!,
            style: const TextStyle(
              fontFamily: 'DMSans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: TraumColors.onBackgroundMuted,
            ),
          ),
        ],
      ],
    );
  }
}
