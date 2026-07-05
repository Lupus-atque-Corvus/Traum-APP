import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'muscle_groups.dart';
import 'widgets/body_map_widget.dart';
import 'widgets/exercise_icon.dart';

/// Full-screen muscle heatmap (Task 8.2 rebuild).
///
/// Same providers as before (`recentTrainingSetsProvider` +
/// `allExercisesStreamProvider`), new presentation:
/// - Header: front + back [BodyMapWidget] colored via its additive
///   `intensity` mode (continuous gradient, not the old 3-bucket heatMap).
/// - A gradient color-scale bar replacing the old dot legend.
/// - Period chips (7/14/30 days) feeding `recentTrainingSetsProvider(days)`.
/// - A muscle-group list with icons, a progress bar, and a tap-to-expand
///   exercise breakdown built from an O(1) `exerciseId -> Exercise` map
///   (Audit finding #4 — no more `firstWhere` in a loop).
class MuscleHeatmapScreen extends ConsumerStatefulWidget {
  const MuscleHeatmapScreen({super.key});

  @override
  ConsumerState<MuscleHeatmapScreen> createState() =>
      _MuscleHeatmapScreenState();
}

class _MuscleHeatmapScreenState extends ConsumerState<MuscleHeatmapScreen> {
  int _days = 7;
  String? _expandedGroup;

  static const Color _coldColor = Color(0xFF2A2A3D);
  static const Color _hotColor = Color(0xFFFF4D4D);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final setsAsync = ref.watch(recentTrainingSetsStreamProvider(_days));
    final exercisesAsync = ref.watch(allExercisesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(
          l10n.muscleHeatmapTitle,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: setsAsync.when(
        data: (sets) => exercisesAsync.when(
          data: (exercises) => _buildBody(context, l10n, sets, exercises),
          loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.coralOrange),
          ),
          error: (e, _) => Center(child: Text('$e')),
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: TraumColors.coralOrange),
        ),
        error: (e, _) => Center(
          child: Text(
            '${l10n.error}: $e',
            style: const TextStyle(color: TraumColors.roseRed),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<WorkoutSet> sets,
    List<Exercise> exercises,
  ) {
    // O(1) lookup instead of `firstWhere` in a loop (Audit finding #4).
    final exerciseById = {for (final e in exercises) e.id: e};

    final setsPerGroup = <String, int>{};
    for (final s in sets) {
      final ex = exerciseById[s.exerciseId];
      if (ex == null) continue;
      final canonical = canonicalMuscleGroup(ex.muscleGroup);
      setsPerGroup[canonical] = (setsPerGroup[canonical] ?? 0) + 1;
    }
    final maxSets = setsPerGroup.values.isEmpty
        ? 1
        : setsPerGroup.values.reduce((a, b) => a > b ? a : b);

    // BodyMap intensity: spread each group's ratio onto its body-map
    // muscles. Some canonical groups overlap (e.g. 'cardio'/'full_body'
    // cover the whole body) — keep the max ratio per muscle rather than
    // letting a later, lower-intensity group overwrite a stronger one.
    final intensity = <String, double>{};
    for (final entry in setsPerGroup.entries) {
      final ratio = maxSets > 0 ? entry.value / maxSets : 0.0;
      for (final m in bodyMapMusclesFor(entry.key)) {
        final existing = intensity[m] ?? 0.0;
        if (ratio > existing) intensity[m] = ratio;
      }
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Front + back body maps, continuous intensity coloring.
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: BodyMapWidget(
                primaryMuscles: const [],
                secondaryMuscles: const [],
                intensity: intensity,
                height: 240,
              ),
            ),
            Expanded(
              child: BodyMapWidget(
                primaryMuscles: const [],
                secondaryMuscles: const [],
                intensity: intensity,
                showBack: true,
                height: 240,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _ColorScaleBar(lowLabel: l10n.notTrainedHeatmap, highLabel: l10n.much),
        const SizedBox(height: 20),

        // Period chips.
        Row(
          children: [
            _PeriodChip(
              label: l10n.heatmapDays7,
              selected: _days == 7,
              onTap: () => setState(() => _days = 7),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: l10n.heatmapDays14,
              selected: _days == 14,
              onTap: () => setState(() => _days = 14),
            ),
            const SizedBox(width: 8),
            _PeriodChip(
              label: l10n.heatmapDays30,
              selected: _days == 30,
              onTap: () => setState(() => _days = 30),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // Muscle-group list.
        ...kAllMuscleGroups.map((g) {
          final count = setsPerGroup[g] ?? 0;
          final ratio = maxSets > 0 ? count / maxSets : 0.0;
          final color = Color.lerp(_coldColor, _hotColor, ratio)!;
          final expanded = _expandedGroup == g;

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
              border: Border.all(
                color: count > 0
                    ? color.withValues(alpha: 0.3)
                    : TraumColors.surfaceVariant,
              ),
            ),
            child: Column(
              children: [
                InkWell(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  onTap: () =>
                      setState(() => _expandedGroup = expanded ? null : g),
                  child: Padding(
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        ExerciseIcon(muscleGroup: g, size: 40),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                muscleGroupLabel(g, l10n),
                                style: const TextStyle(
                                  color: TraumColors.onBackground,
                                  fontFamily: 'DMSans',
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                count == 0
                                    ? l10n.notTrained
                                    : l10n.setCount(count),
                                style: TextStyle(
                                  color: count > 0
                                      ? color
                                      : TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans',
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (count > 0)
                          SizedBox(
                            width: 90,
                            child: LinearProgressIndicator(
                              value: ratio,
                              backgroundColor: TraumColors.surfaceVariant,
                              valueColor: AlwaysStoppedAnimation<Color>(color),
                              borderRadius: BorderRadius.circular(4),
                              minHeight: 6,
                            ),
                          ),
                        const SizedBox(width: 6),
                        Icon(
                          expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          color: TraumColors.onBackgroundMuted,
                        ),
                      ],
                    ),
                  ),
                ),
                if (expanded)
                  _ExerciseBreakdown(
                    group: g,
                    sets: sets,
                    exerciseById: exerciseById,
                    l10n: l10n,
                  ),
              ],
            ),
          );
        }),
        const SizedBox(height: 16),
      ],
    );
  }
}

/// Tap-expanded panel: exercises trained for [group] in the current period,
/// from the already-loaded `sets` + the O(1) `exerciseById` map (no new
/// provider — reuses the data the screen already has).
class _ExerciseBreakdown extends StatelessWidget {
  final String group;
  final List<WorkoutSet> sets;
  final Map<int, Exercise> exerciseById;
  final AppLocalizations l10n;

  const _ExerciseBreakdown({
    required this.group,
    required this.sets,
    required this.exerciseById,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    final countByExercise = <int, int>{};
    for (final s in sets) {
      final ex = exerciseById[s.exerciseId];
      if (ex == null) continue;
      if (canonicalMuscleGroup(ex.muscleGroup) != group) continue;
      countByExercise[s.exerciseId] = (countByExercise[s.exerciseId] ?? 0) + 1;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(color: TraumColors.surfaceVariant, height: 20),
          Text(
            l10n.heatmapExercisesIn,
            style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 8),
          if (countByExercise.isEmpty)
            Text(
              l10n.notTrained,
              style: const TextStyle(
                color: TraumColors.onBackgroundSubtle,
                fontFamily: 'DMSans',
                fontSize: 12,
              ),
            )
          else
            ...countByExercise.entries.map((entry) {
              final ex = exerciseById[entry.key];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        ex?.name ?? '—',
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Text(
                      l10n.setCount(entry.value),
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

/// Gradient color-scale bar (replaces the old dot-legend rows).
class _ColorScaleBar extends StatelessWidget {
  final String lowLabel;
  final String highLabel;

  const _ColorScaleBar({required this.lowLabel, required this.highLabel});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 10,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            gradient: const LinearGradient(
              colors: [Color(0xFF2A2A3D), Color(0xFFFF4D4D)],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lowLabel,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11,
              ),
            ),
            Text(
              highLabel,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 11,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _PeriodChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PeriodChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? TraumColors.coralOrange : TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
            border: Border.all(
              color: selected
                  ? TraumColors.coralOrange
                  : TraumColors.surfaceVariant,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
