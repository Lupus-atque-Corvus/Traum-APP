import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/body_map_widget.dart';

String _muscleLabel(String key, AppLocalizations l10n) {
  switch (key) {
    case 'Brust': return l10n.muscleBrust;
    case 'Rücken': return l10n.muscleRuecken;
    case 'Schulter': return l10n.muscleSchulter;
    case 'Bizeps': return l10n.muscleBizeps;
    case 'Trizeps': return l10n.muscleTrizeps;
    case 'Bauch': return l10n.muscleBauch;
    case 'Beine': return l10n.muscleBeine;
    case 'Gesäß': return l10n.muscleGesaess;
    case 'Waden': return l10n.muscleWaden;
    case 'Ganzkörper': return l10n.muscleGanzkoerper;
    default: return key;
  }
}

class MuscleHeatmapScreen extends ConsumerWidget {
  const MuscleHeatmapScreen({super.key});

  static const _muscleGroups = [
    'Brust', 'Rücken', 'Schulter', 'Bizeps', 'Trizeps',
    'Bauch', 'Beine', 'Gesäß', 'Waden', 'Ganzkörper',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setsAsync = ref.watch(recentTrainingSetsProvider(7));
    final exercisesAsync = ref.watch(allExercisesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.muscleHeatmapTitle,
            style: const TextStyle(
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

            // Map trained muscle groups → BodyMap muscle IDs
            final strongMuscles = <String>{};
            final lightMuscles = <String>{};
            for (final entry in setsPerMuscle.entries) {
              final muscleIds = BodyMapWidget.musclesForGroup(entry.key);
              final ratio = maxSets > 0 ? entry.value / maxSets : 0.0;
              if (ratio > 0.5) {
                strongMuscles.addAll(muscleIds);
              } else if (ratio > 0) {
                lightMuscles.addAll(muscleIds);
              }
            }
            final primaryMuscles = strongMuscles.toList();
            final secondaryMuscles = lightMuscles.difference(strongMuscles).toList();

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Body map front + back
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    BodyMapWidget(
                      primaryMuscles: primaryMuscles,
                      secondaryMuscles: secondaryMuscles,
                      height: 200,
                    ),
                    const SizedBox(width: 16),
                    BodyMapWidget(
                      primaryMuscles: primaryMuscles,
                      secondaryMuscles: secondaryMuscles,
                      showBack: true,
                      height: 200,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Legend
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BodyMapLegendDot(color: const Color(0xFFFF4D4D), label: AppLocalizations.of(context)!.heavilyTrained),
                    const SizedBox(width: 16),
                    _BodyMapLegendDot(color: const Color(0xFFFFD34C), label: AppLocalizations.of(context)!.lightlyTrained),
                    const SizedBox(width: 16),
                    _BodyMapLegendDot(color: const Color(0xFF2A2A3D), label: AppLocalizations.of(context)!.notTrainedHeatmap),
                  ],
                ),
                const SizedBox(height: 20),
                Text(AppLocalizations.of(context)!.trainingVolumeLast7Days,
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
                          Text(_muscleLabel(muscle, AppLocalizations.of(context)!),
                              style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600)),
                          Text(count == 0
                              ? AppLocalizations.of(context)!.notTrained
                              : AppLocalizations.of(context)!.setCount(count),
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
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _LegendItem(color: TraumColors.onBackgroundSubtle, label: AppLocalizations.of(context)!.noTraining),
                      _LegendItem(color: TraumColors.amberGold, label: AppLocalizations.of(context)!.little),
                      _LegendItem(color: TraumColors.coralOrange, label: AppLocalizations.of(context)!.medium),
                      _LegendItem(color: TraumColors.roseRed, label: AppLocalizations.of(context)!.much),
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
            child: Text('${AppLocalizations.of(context)!.error}: $e',
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

class _BodyMapLegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _BodyMapLegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 10, height: 10,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
        fontSize: 11,
      )),
    ]);
  }
}
