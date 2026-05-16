import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

class ExerciseProgressScreen extends ConsumerWidget {
  final int exerciseId;
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(
      FutureProvider((ref) =>
          ref.watch(trainingDaoProvider).getRecentSets(const Duration(days: 90))),
    );
    final exercisesAsync = ref.watch(
      StreamProvider((ref) => ref.watch(trainingDaoProvider).watchAllExercises()),
    );

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: const Text('Fortschritt',
            style: TextStyle(
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
                  const Text('Noch keine Daten',
                      style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  const Text('Trainiere diese Übung, um Fortschritte zu sehen',
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
            final maxVol = volumeData.isEmpty
                ? 1.0
                : volumeData.fold(0.0, (m, v) => v > m ? v : m);

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
                      label: 'Max. Gewicht',
                      value: '${maxWeight.toStringAsFixed(1)} kg',
                      icon: Icons.trending_up_rounded,
                      color: TraumColors.coralOrange,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PRCard(
                      label: 'Max. Wiederh.',
                      value: '$maxReps',
                      icon: Icons.repeat_rounded,
                      color: TraumColors.mintGreen,
                    ),
                  ),
                ]),
                const SizedBox(height: 16),
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
                        const Text('Volumen (letzte 90 Tage)',
                            style: TextStyle(
                                color: TraumColors.onBackground,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: volumeData.take(20).map((v) {
                            final h = maxVol > 0 ? (v / maxVol) * 80 : 2.0;
                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 1),
                                child: Container(
                                  height: h.clamp(2.0, 80.0),
                                  decoration: BoxDecoration(
                                    color: TraumColors.coralOrange.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                // Recent sets
                const Text('Letzte Sätze',
                    style: TextStyle(
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
                        Text('Satz ${s.setNumber}',
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
                          Text('${s.reps} Wdh.',
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
            child: Text('Fehler: $e',
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
