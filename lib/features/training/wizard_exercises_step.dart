import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/repositories/plan_templates.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/exercise_icon.dart';

class WizardExercisesStep extends ConsumerStatefulWidget {
  final PlanTemplate template;
  final Map<int, String> selectedDays; // dayOfWeek -> name

  const WizardExercisesStep({
    super.key,
    required this.template,
    required this.selectedDays,
  });

  @override
  ConsumerState<WizardExercisesStep> createState() =>
      _WizardExercisesStepState();
}

class _WizardExercisesStepState
    extends ConsumerState<WizardExercisesStep> {
  // dayOfWeek -> list of (exerciseName, sets, reps)
  late Map<int, List<_WizardExerciseEntry>> _entries;

  @override
  void initState() {
    super.initState();
    _entries = {};
    for (final dow in widget.selectedDays.keys) {
      final templateDay = widget.template.days.cast<TemplateDay?>()
          .firstWhere((d) => d?.dayOfWeek == dow, orElse: () => null);
      _entries[dow] = templateDay?.exercises
              .map((e) => _WizardExerciseEntry(
                    exerciseName: e.exerciseName,
                    sets: e.sets,
                    reps: e.reps,
                  ))
              .toList() ??
          [];
    }
  }

  void _removeExercise(int dow, int index) {
    setState(() => _entries[dow]!.removeAt(index));
  }

  Future<void> _showPicker(int dow) async {
    final allExercises = await ref.read(trainingDaoProvider).watchAllExercises().first;
    if (!mounted) return;

    final picked = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular(TraumRadius.card)),
      ),
      builder: (_) => _ExercisePickerSheet(exercises: allExercises),
    );

    if (picked != null) {
      setState(() {
        _entries[dow]!.add(_WizardExerciseEntry(
          exerciseName: picked.name,
          sets: 3,
          reps: 10,
        ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final sortedDays = widget.selectedDays.keys.toList()..sort();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.exercisesReviewTitle,
          style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 20),
        ),
        const SizedBox(height: 6),
        Text(
          l10n.exercisesReviewSubtitle,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        const SizedBox(height: 20),
        ...sortedDays.map((dow) => _DayExerciseBlock(
          dayName: widget.selectedDays[dow]!,
          entries: _entries[dow]!,
          onRemove: (i) => _removeExercise(dow, i),
          onAdd: () => _showPicker(dow),
        )),
      ],
    );
  }
}

class _DayExerciseBlock extends StatelessWidget {
  final String dayName;
  final List<_WizardExerciseEntry> entries;
  final ValueChanged<int> onRemove;
  final VoidCallback onAdd;

  const _DayExerciseBlock({
    required this.dayName,
    required this.entries,
    required this.onRemove,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dayName,
              style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  fontSize: 14)),
          const SizedBox(height: 10),
          ...entries.asMap().entries.map((e) => _ExerciseTile(
            entry: e.value,
            onRemove: () => onRemove(e.key),
          )),
          TextButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded,
                color: TraumColors.coralOrange, size: 18),
            label: Text(l10n.addExercise,
                style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ],
      ),
    );
  }
}

class _ExerciseTile extends ConsumerWidget {
  final _WizardExerciseEntry entry;
  final VoidCallback onRemove;

  const _ExerciseTile({required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    return exercisesAsync.when(
      data: (exercises) {
        final exercise = exercises.cast<Exercise?>()
            .firstWhere((e) => e?.name == entry.exerciseName, orElse: () => null);
        final muscleGroup = exercise?.muscleGroup ?? 'full_body';
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(children: [
            ExerciseIcon(muscleGroup: muscleGroup, size: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(entry.exerciseName,
                  style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontSize: 13)),
            ),
            Text('${entry.sets}x${entry.reps}',
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12)),
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onRemove,
              child: const Icon(Icons.close_rounded,
                  color: TraumColors.onBackgroundMuted, size: 18),
            ),
          ]),
        );
      },
      loading: () => const SizedBox(height: 36),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final List<Exercise> exercises;
  const _ExercisePickerSheet({required this.exercises});

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = widget.exercises
        .where((e) =>
            e.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (_, controller) => Column(children: [
        const SizedBox(height: 12),
        Container(
            width: 36, height: 4,
            decoration: BoxDecoration(
                color: TraumColors.surfaceVariant,
                borderRadius: BorderRadius.circular(2))),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: TextField(
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: l10n.searchExercise,
              hintStyle: const TextStyle(color: TraumColors.onBackgroundMuted),
              prefixIcon: const Icon(Icons.search_rounded,
                  color: TraumColors.onBackgroundMuted),
              filled: true,
              fillColor: TraumColors.surfaceVariant,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(TraumRadius.input),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: ListView.builder(
            controller: controller,
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final ex = filtered[i];
              return ListTile(
                leading: ExerciseIcon(muscleGroup: ex.muscleGroup, size: 40),
                title: Text(ex.name,
                    style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontSize: 14)),
                subtitle: Text(ex.muscleGroup,
                    style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12)),
                onTap: () => Navigator.pop(context, ex),
              );
            },
          ),
        ),
      ]),
    );
  }
}

class _WizardExerciseEntry {
  String exerciseName;
  int sets;
  int reps;
  _WizardExerciseEntry({
    required this.exerciseName,
    required this.sets,
    required this.reps,
  });
}
