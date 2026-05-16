import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';
import '../health_score_result.dart';

class ScoreRadarChart extends StatelessWidget {
  final List<FaktorScore> faktoren;

  const ScoreRadarChart({super.key, required this.faktoren});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 240,
      child: RadarChart(
        RadarChartData(
          radarShape: RadarShape.polygon,
          tickCount: 4,
          ticksTextStyle: const TextStyle(
            color: TraumColors.onBackgroundSubtle,
            fontSize: 8,
            fontFamily: 'DMSans',
          ),
          tickBorderData: const BorderSide(
            color: Colors.white12,
            width: 1,
          ),
          gridBorderData: const BorderSide(
            color: Colors.white12,
            width: 1,
          ),
          radarBorderData: const BorderSide(
            color: Colors.white12,
            width: 1,
          ),
          getTitle: (index, angle) {
            if (index < 0 || index >= faktoren.length) {
              return RadarChartTitle(text: '');
            }
            final f = faktoren[index];
            return RadarChartTitle(
              text: '${f.name}\n${f.score}',
              angle: 0,
            );
          },
          titleTextStyle: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontSize: 9,
            fontFamily: 'DMSans',
          ),
          dataSets: [
            RadarDataSet(
              fillColor: TraumColors.coralOrange.withValues(alpha: 0.20),
              borderColor: TraumColors.coralOrange,
              entryRadius: 3,
              borderWidth: 2,
              dataEntries: faktoren
                  .map((f) => RadarEntry(value: f.score / 100 * 4))
                  .toList(),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 400),
      ),
    );
  }
}
