import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import 'progress_icon.dart';

/// Discrete completion levels a single heatmap cell can render as.
enum HeatmapIntensity { none, partial, full }

/// Pure mapping from a raw completion fraction (0.0..1.0, or any bool
/// converted to 0/1 by the caller) to a discrete [HeatmapIntensity].
///
/// Thresholds:
/// - `<= 0`        -> [HeatmapIntensity.none]
/// - `0 < x < 1`   -> [HeatmapIntensity.partial]
/// - `>= 1`        -> [HeatmapIntensity.full]
///
/// Values outside 0..1 are clamped first, so e.g. `1.5` -> full and `-1` ->
/// none.
HeatmapIntensity heatmapIntensityFor(double completion) {
  final clamped = completion.clamp(0.0, 1.0);
  if (clamped <= 0) return HeatmapIntensity.none;
  if (clamped >= 1) return HeatmapIntensity.full;
  return HeatmapIntensity.partial;
}

/// Resolves an [HeatmapIntensity] to a cell fill color, given a [base]
/// accent (default mint, per the habits palette) and a [track] color used
/// for the empty state.
Color heatmapIntensityColor(
  HeatmapIntensity intensity, {
  Color base = TraumColors.mintGreen,
  Color track = TraumColors.surfaceVariant,
}) {
  switch (intensity) {
    case HeatmapIntensity.none:
      return track;
    case HeatmapIntensity.partial:
      return base.withValues(alpha: 0.45);
    case HeatmapIntensity.full:
      return base;
  }
}

/// One row's worth of data for the [WeeklyHabitHeatmap]: a habit's name/icon
/// plus its completion fraction (0.0..1.0) for each of the 7 days of the
/// week, Monday-first.
class HabitHeatmapRow {
  final String name;
  final String? iconKey;
  final List<double> dayValues;

  const HabitHeatmapRow({
    required this.name,
    this.iconKey,
    required this.dayValues,
  }) : assert(
          dayValues.length == 7,
          'dayValues must have exactly 7 entries (Mon..Sun)',
        );
}

const List<String> _kWeekdayLabels = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

/// A grid of habit rows x 7 day columns, each cell colored by completion
/// intensity via [heatmapIntensityColor]. Renders purely from [rows] — no
/// provider/screen wiring.
class WeeklyHabitHeatmap extends StatelessWidget {
  final List<HabitHeatmapRow> rows;
  final Color accentColor;
  final int? todayIndex;

  const WeeklyHabitHeatmap({
    super.key,
    required this.rows,
    this.accentColor = TraumColors.mintGreen,
    this.todayIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(flex: 3, child: SizedBox()),
            for (var i = 0; i < 7; i++)
              Expanded(
                child: Center(
                  child: Text(
                    _kWeekdayLabels[i],
                    style: TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: i == todayIndex
                          ? accentColor
                          : TraumColors.onBackgroundMuted,
                    ),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      ProgressIcon(row.iconKey, size: 16, color: accentColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          row.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: TraumColors.onBackground,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                for (var i = 0; i < 7; i++)
                  Expanded(
                    child: Center(
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: heatmapIntensityColor(
                                heatmapIntensityFor(row.dayValues[i]),
                                base: accentColor,
                              ),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
