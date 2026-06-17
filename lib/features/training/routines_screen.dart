import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/body_map_widget.dart';

class RoutinesScreen extends ConsumerWidget {
  const RoutinesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plansAsync = ref.watch(allWorkoutPlansStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.trainingRoutines,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.coralOrange,
        onPressed: () => context.go('/training/routines/new'),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: plansAsync.when(
        data: (plans) {
          if (plans.isEmpty) {
            return Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.fitness_center_rounded,
                    size: 64,
                    color: TraumColors.onBackgroundSubtle.withValues(alpha: 0.5)),
                const SizedBox(height: 16),
                Text(AppLocalizations.of(context)!.noRoutines,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 16)),
                const SizedBox(height: 8),
                Text(AppLocalizations.of(context)!.tapToCreateRoutine,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13),
                    textAlign: TextAlign.center),
              ]),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
            itemCount: plans.length,
            itemBuilder: (ctx, i) => _PlanCard(
              plan: plans[i],
              onTap: () => context.go('/training/plan/${plans[i].id}'),
              onSetActive: () => ref.read(trainingDaoProvider).updatePlan(
                    WorkoutPlansCompanion(
                      id: Value(plans[i].id),
                      name: Value(plans[i].name),
                      description: Value(plans[i].description),
                      isActive: const Value(true),
                    ),
                  ),
              onDelete: () => ref.read(trainingDaoProvider).deletePlan(plans[i].id),
            ),
          );
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(
            child: Text('${AppLocalizations.of(context)!.error}: $e',
                style: const TextStyle(color: TraumColors.roseRed))),
      ),
    );
  }
}

class _PlanCard extends ConsumerWidget {
  final WorkoutPlan plan;
  final VoidCallback onTap;
  final VoidCallback onSetActive;
  final VoidCallback onDelete;

  const _PlanCard({
    required this.plan,
    required this.onTap,
    required this.onSetActive,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final muscleGroupsAsync = ref.watch(planMuscleGroupsProvider(plan.id));
    final muscleGroups = muscleGroupsAsync.value ?? [];

    // Convert German muscle groups to body map muscle keys
    final Set<String> primaryMuscles = {};
    for (final group in muscleGroups) {
      primaryMuscles.addAll(BodyMapWidget.musclesForGroup(group));
    }

    return Dismissible(
      key: ValueKey(plan.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: TraumColors.roseRed.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(TraumRadius.card),
        ),
        child: const Icon(Icons.delete_rounded, color: TraumColors.roseRed),
      ),
      onDismissed: (_) => onDelete(),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
            border: Border.all(
              color: plan.isActive
                  ? TraumColors.coralOrange.withValues(alpha: 0.4)
                  : TraumColors.surfaceVariant,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan.name,
                          style: const TextStyle(
                              color: TraumColors.onBackground,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      if (plan.description != null)
                        Text(plan.description!,
                            style: const TextStyle(
                                color: TraumColors.onBackgroundMuted,
                                fontFamily: 'DMSans',
                                fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                    ]),
                  ),
                  if (!plan.isActive)
                    TextButton(
                      onPressed: onSetActive,
                      style: TextButton.styleFrom(foregroundColor: TraumColors.coralOrange),
                      child: Text(l10n.activate,
                          style: const TextStyle(fontFamily: 'DMSans', fontSize: 12)),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: TraumColors.coralDim,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(l10n.active,
                          style: const TextStyle(
                              color: TraumColors.coralOrange,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600,
                              fontSize: 11)),
                    ),
                ]),
              ),

              // Body map preview (only show if there are muscles to display)
              if (primaryMuscles.isNotEmpty)
                Container(
                  decoration: BoxDecoration(
                    color: TraumColors.background.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(TraumRadius.card - 1),
                      bottomRight: Radius.circular(TraumRadius.card - 1),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: BodyMapWidget(
                          primaryMuscles: primaryMuscles.toList(),
                          secondaryMuscles: const [],
                          showBack: false,
                          height: 120,
                        ),
                      ),
                      Expanded(
                        child: BodyMapWidget(
                          primaryMuscles: primaryMuscles.toList(),
                          secondaryMuscles: const [],
                          showBack: true,
                          height: 120,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
