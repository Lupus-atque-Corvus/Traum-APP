import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

double _epley1RM(double weight, int reps) =>
    reps == 1 ? weight : weight * (1 + reps / 30);

class ExerciseProgressScreen extends ConsumerWidget {
  final int exerciseId;
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(recentTrainingSetsProvider(90));
    final exercisesAsync = ref.watch(allExercisesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.progress,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: setsAsync.when(
        data: (allSets) => exercisesAsync.when(
          data: (exercises) {
            final ex = exercises.cast<Exercise?>().firstWhere(
                (e) => e?.id == exerciseId, orElse: () => null);
            final sets = allSets.where((s) => s.exerciseId == exerciseId).toList()
              ..sort((a, b) => a.id.compareTo(b.id));

            if (sets.isEmpty) {
              return Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.show_chart_rounded,
                      size: 64, color: TraumColors.onBackgroundSubtle),
                  const SizedBox(height: 16),
                  Text(AppLocalizations.of(context)!.noProgressData,
                      style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Text(AppLocalizations.of(context)!.trainExerciseToSeeProgress,
                      style: TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 12),
                      textAlign: TextAlign.center),
                ]),
              );
            }

            // PR tracking
            final maxWeight =
                sets.fold(0.0, (m, s) => (s.weightKg ?? 0) > m ? s.weightKg! : m);
            final maxReps = sets.fold(0, (m, s) => (s.reps ?? 0) > m ? s.reps! : m);

            // Volume per session (simplified: sum weight*reps per set)
            final volumeData = sets
                .where((s) => s.weightKg != null && s.reps != null)
                .map((s) => s.weightKg! * s.reps!)
                .toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (ex != null) ...[
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                    ),
                    child: Row(children: [
                      Container(
                        width: 44, height: 44,
                        decoration: const BoxDecoration(
                            color: TraumColors.coralDim, shape: BoxShape.circle),
                        child: const Icon(Icons.fitness_center_rounded,
                            color: TraumColors.coralOrange, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(ex.name,
                              style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16)),
                          Text(ex.muscleGroup,
                              style: const TextStyle(
                                  color: TraumColors.coralOrange,
                                  fontFamily: 'DMSans',
                                  fontSize: 12)),
                        ]),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 16),
                ],
                // PRs
                Row(children: [
                  Expanded(
                    child: _PRCard(
                      label: AppLocalizations.of(context)!.maxWeight,
                      value: '${maxWeight.toStringAsFixed(1)} kg',
                      icon: Icons.trending_up_rounded,
                      color: TraumColors.coralOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PRCard(
                      label: AppLocalizations.of(context)!.maxReps,
                      value: '$maxReps',
                      icon: Icons.repeat_rounded,
                      color: TraumColors.mintGreen,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
                // 1RM LineChart
                Builder(builder: (context) {
                  final oneRMPoints = sets
                      .where((s) => s.weightKg != null && s.reps != null && s.reps! > 0)
                      .toList();

                  if (oneRMPoints.length > 1) {
                    return Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: TraumColors.surface,
                            borderRadius: BorderRadius.circular(TraumRadius.card),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppLocalizations.of(context)!.estimated1RM,
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 12),
                              SizedBox(
                                height: 160,
                                child: LineChart(
                                  LineChartData(
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      getDrawingHorizontalLine: (_) => FlLine(
                                        color: TraumColors.surfaceVariant,
                                        strokeWidth: 1,
                                      ),
                                    ),
                                    titlesData: FlTitlesData(
                                      leftTitles: AxisTitles(
                                        sideTitles: SideTitles(
                                          showTitles: true,
                                          reservedSize: 40,
                                          getTitlesWidget: (v, _) => Text(
                                            '${v.toInt()} kg',
                                            style: const TextStyle(
                                              color: TraumColors.onBackgroundSubtle,
                                              fontFamily: 'DMSans',
                                              fontSize: 10,
                                            ),
                                          ),
                                        ),
                                      ),
                                      bottomTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                    ),
                                    borderData: FlBorderData(show: false),
                                    lineBarsData: [
                                      LineChartBarData(
                                        spots: oneRMPoints.asMap().entries.map((e) {
                                          final rm = _epley1RM(e.value.weightKg!, e.value.reps!);
                                          return FlSpot(e.key.toDouble(), rm);
                                        }).toList(),
                                        isCurved: true,
                                        color: TraumColors.coralOrange,
                                        barWidth: 2,
                                        dotData: const FlDotData(show: false),
                                        belowBarData: BarAreaData(
                                          show: true,
                                          color: TraumColors.coralOrange.withValues(alpha: 0.1),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                }),
                // Volume chart
                if (volumeData.length > 1) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppLocalizations.of(context)!.volumeLast90Days,
                          style: const TextStyle(
                            color: TraumColors.onBackground,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                              ),
                              barGroups: volumeData.asMap().entries.map((e) =>
                                BarChartGroupData(
                                  x: e.key,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value,
                                      color: TraumColors.mintGreen,
                                      width: 8,
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                  ],
                                ),
                              ).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Recent sets
                Text(AppLocalizations.of(context)!.recentSets,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 8),
                ...sets.reversed.take(15).map((s) => Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: TraumColors.surface,
                        borderRadius: BorderRadius.circular(TraumRadius.card),
                      ),
                      child: Row(children: [
                        Text(AppLocalizations.of(context)!.setLabel(s.setNumber),
                            style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 12)),
                        const Spacer(),
                        if (s.weightKg != null)
                          Text('${s.weightKg} kg',
                              style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w500)),
                        if (s.weightKg != null && s.reps != null)
                          const Text('  ×  ',
                              style: TextStyle(
                                  color: TraumColors.onBackgroundMuted,
                                  fontFamily: 'DMSans')),
                        if (s.reps != null)
                          Text(AppLocalizations.of(context)!.repsCount(s.reps!),
                              style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w500)),
                      ]),
                    )),
              ],
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(color: TraumColors.coralOrange)),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }
}

class _PRCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _PRCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 6),
        Text(value,
            style: TextStyle(
                color: color,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18)),
        Text(label,
            style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11)),
      ]),
    );
  }
}
