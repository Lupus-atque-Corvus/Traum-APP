import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class MuscleHeatmapScreen extends ConsumerWidget {
  const MuscleHeatmapScreen({super.key});

  static const _muscleGroups = [
    'Brust', 'Rücken', 'Schulter', 'Bizeps', 'Trizeps',
    'Bauch', 'Beine', 'Gesäß', 'Waden', 'Ganzkörper',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(
      FutureProvider((ref) =>
          ref.watch(trainingDaoProvider).getRecentSets(const Duration(days: 7))),
    );
    final exercisesAsync = ref.watch(
      StreamProvider((ref) => ref.watch(trainingDaoProvider).watchAllExercises()),
    );

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Muskel-Heatmap',
            style: TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: setsAsync.when(
        data: (sets) => exercisesAsync.when(
          data: (exercises) {
            // Count sets per muscle group
            final setsPerMuscle = <String, int>{};
            for (final s in sets) {
              final ex = exercises.cast<Exercise?>()
                  .firstWhere((e) => e?.id == s.exerciseId, orElse: () => null);
              if (ex != null) {
                setsPerMuscle[ex.muscleGroup] =
                    (setsPerMuscle[ex.muscleGroup] ?? 0) + 1;
              }
            }
            final maxSets = setsPerMuscle.values.isEmpty
                ? 1
                : setsPerMuscle.values.reduce((a, b) => a > b ? a : b);

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text('Trainingsvolumen (letzte 7 Tage)',
                    style: TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 15)),
                const SizedBox(height: 16),
                ..._muscleGroups.map((muscle) {
                  final count = setsPerMuscle[muscle] ?? 0;
                  final ratio = maxSets > 0 ? count / maxSets : 0.0;
                  final heatColor = _heatColor(ratio);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: TraumColors.surface,
                      borderRadius: BorderRadius.circular(TraumRadius.card),
                      border: Border.all(
                          color: count > 0
                              ? heatColor.withValues(alpha: 0.3)
                              : TraumColors.surfaceVariant),
                    ),
                    child: Row(children: [
                      Container(
                        width: 12, height: 40,
                        decoration: BoxDecoration(
                          color: count > 0 ? heatColor : TraumColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(muscle,
                              style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600)),
                          Text(count == 0
                              ? 'Nicht trainiert'
                              : '$count ${count == 1 ? 'Satz' : 'Sätze'}',
                              style: TextStyle(
                                  color: count > 0
                                      ? heatColor
                                      : TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans',
                                  fontSize: 12)),
                        ]),
                      ),
                      if (count > 0)
                        SizedBox(
                          width: 100,
                          child: LinearProgressIndicator(
                            value: ratio,
                            backgroundColor:
                                TraumColors.surfaceVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(heatColor),
                            borderRadius: BorderRadius.circular(4),
                            minHeight: 6,
                          ),
                        ),
                    ]),
                  );
                }),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: TraumColors.surface,
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: TraumColors.onBackgroundSubtle, label: 'Kein Training'),
                      _LegendItem(color: TraumColors.amberGold, label: 'Wenig'),
                      _LegendItem(color: TraumColors.coralOrange, label: 'Mittel'),
                      _LegendItem(color: TraumColors.roseRed, label: 'Viel'),
                    ],
                  ),
                ),
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
            child: Text('Fehler: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }

  static Color _heatColor(double ratio) {
    if (ratio <= 0) return TraumColors.onBackgroundSubtle;
    if (ratio < 0.33) return TraumColors.amberGold;
    if (ratio < 0.66) return TraumColors.coralOrange;
    return TraumColors.roseRed;
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendItem({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: 10, height: 10,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 4),
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 10)),
    ]);
  }
}
