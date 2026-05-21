import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../data/repositories/plan_templates.dart';
import '../../l10n/app_localizations.dart';
import 'wizard_template_step.dart';
import 'wizard_days_step.dart';
import 'wizard_exercises_step.dart';

class TrainingWizardScreen extends ConsumerStatefulWidget {
  const TrainingWizardScreen({super.key});

  @override
  ConsumerState<TrainingWizardScreen> createState() =>
      _TrainingWizardScreenState();
}

class _TrainingWizardScreenState
    extends ConsumerState<TrainingWizardScreen> {
  int _step = 0;
  PlanTemplate? _selectedTemplate;
  // dayOfWeek (1-7) -> day name
  final Map<int, String> _selectedDays = {};
  bool _saving = false;

  bool get _canAdvance {
    if (_step == 0) return _selectedTemplate != null;
    if (_step == 1) return _selectedDays.isNotEmpty;
    return true;
  }

  void _advance() {
    if (_step < 2) {
      setState(() => _step++);
    } else {
      _finish();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  Future<void> _skip() async {
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setTrainingSetupComplete(true);
    if (mounted) context.go(Routes.training);
  }

  Future<void> _finish() async {
    if (_saving) return;
    setState(() => _saving = true);

    final dao = ref.read(trainingDaoProvider);
    final db = ref.read(databaseProvider);
    final allExercises = await dao.watchAllExercises().first;

    await db.transaction(() async {
      // Deactivate all existing plans
      final existing = await dao.watchAllPlans().first;
      for (final p in existing) {
        await dao.updatePlan(p.toCompanion(true).copyWith(isActive: const Value(false)));
      }

      // Create new plan
      final planId = await dao.insertPlan(
        WorkoutPlansCompanion.insert(
          name: _selectedTemplate!.name,
          isActive: const Value(true),
        ),
      );

      // Create days + exercises
      final sortedEntries = _selectedDays.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));

      for (final entry in sortedEntries) {
        final dayId = await dao.insertDay(
          WorkoutDaysCompanion.insert(
            planId: planId,
            name: entry.value,
            dayOfWeek: Value(entry.key),
            sortOrder: Value(entry.key),
          ),
        );

        final templateDay = _selectedTemplate!.days.cast<TemplateDay?>()
            .firstWhere(
              (d) => d?.dayOfWeek == entry.key,
              orElse: () => null,
            );

        if (templateDay != null) {
          for (var i = 0; i < templateDay.exercises.length; i++) {
            final te = templateDay.exercises[i];
            final exercise = allExercises.cast<Exercise?>().firstWhere(
              (e) => e?.name == te.exerciseName,
              orElse: () => null,
            );
            if (exercise == null) continue;
            await dao.insertDayExercise(
              WorkoutDayExercisesCompanion.insert(
                dayId: dayId,
                exerciseId: exercise.id,
                sortOrder: Value(i),
                defaultSets: Value(te.sets),
                defaultReps: Value(te.reps),
              ),
            );
          }
        }
      }
    });

    // Mark setup complete in preferences
    final prefs = ref.read(preferencesRepositoryProvider);
    await prefs.setTrainingSetupComplete(true);

    if (!mounted) return;
    context.go(Routes.training);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: _step > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded,
                    color: TraumColors.onBackground),
                onPressed: _back,
              )
            : null,
        title: Text(
          l10n.wizardStepOf(_step + 1, 3),
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: _skip,
            child: Text(l10n.wizardSkip,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
          ),
        ],
      ),
      body: Column(children: [
        // Progress bar
        LinearProgressIndicator(
          value: (_step + 1) / 3,
          backgroundColor: TraumColors.surfaceVariant,
          color: TraumColors.coralOrange,
          minHeight: 3,
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: _buildStep(),
          ),
        ),
        // Bottom button
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _canAdvance && !_saving ? _advance : null,
              style: FilledButton.styleFrom(
                backgroundColor: TraumColors.coralOrange,
                disabledBackgroundColor: TraumColors.surfaceVariant,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.button)),
              ),
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                  : Text(
                      _step < 2 ? l10n.wizardNext : l10n.wizardFinish,
                      style: const TextStyle(
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w700,
                          fontSize: 16),
                    ),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return WizardTemplateStep(
          selected: _selectedTemplate,
          onSelect: (t) {
            setState(() {
              _selectedTemplate = t;
              _selectedDays.clear();
              for (final day in t.days) {
                _selectedDays[day.dayOfWeek] = day.name;
              }
            });
          },
        );
      case 1:
        return WizardDaysStep(
          template: _selectedTemplate!,
          selectedDays: _selectedDays,
          onChanged: (days) => setState(() {
            _selectedDays
              ..clear()
              ..addAll(days);
          }),
        );
      case 2:
        return WizardExercisesStep(
          template: _selectedTemplate!,
          selectedDays: _selectedDays,
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
