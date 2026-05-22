import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/rest_duration_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../core/providers/unit_preference_provider.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/exercise_icon.dart';
import 'widgets/rest_timer_widget.dart';

String _muscleGroupKey(String g) {
  switch (g.toLowerCase()) {
    case 'brust': return 'chest';
    case 'rücken': return 'back';
    case 'schulter': return 'shoulders';
    case 'bizeps': return 'biceps';
    case 'trizeps': return 'triceps';
    case 'bauch': return 'core';
    case 'beine': case 'gesäß': case 'waden': return 'legs';
    case 'ganzkörper': return 'full_body';
    default: return 'full_body';
  }
}

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() => _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  late DateTime _startedAt;
  late Timer _timer;
  Duration _elapsed = Duration.zero;
  int? _sessionId;
  final _sets = <_SetEntry>[];
  bool _finishing = false;

  @override
  void initState() {
    super.initState();
    _startedAt = DateTime.now();
    WakelockPlus.enable();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(_startedAt));
    });
    _createSession();
  }

  Future<void> _createSession() async {
    final id = await ref.read(trainingDaoProvider).insertSession(
          WorkoutSessionsCompanion.insert(startedAt: _startedAt),
        );
    if (mounted) setState(() => _sessionId = id);
  }

  @override
  void dispose() {
    _timer.cancel();
    WakelockPlus.disable();
    super.dispose();
  }

  String get _elapsedStr {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    final restDuration = ref.watch(restDurationProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(_elapsedStr,
            style: const TextStyle(
                color: TraumColors.coralOrange,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 20)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _finishing ? null : _finishWorkout,
            child: Text(
                _finishing ? l10n.finishing : l10n.done,
                style: const TextStyle(
                    color: TraumColors.mintGreen,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Rest duration chips ──────────────────────────────────────────
          Container(
            color: TraumColors.background,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Row(children: [
              Text(l10n.restDuration,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12)),
              const SizedBox(width: 10),
              ...restDurationOptions.map((sec) {
                final selected = sec == restDuration;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: GestureDetector(
                    onTap: () => ref.read(restDurationProvider.notifier).set(sec),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: selected ? TraumColors.mintGreen : TraumColors.surface,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${sec}s',
                        style: TextStyle(
                          color: selected ? TraumColors.background : TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ]),
          ),
          // ── Set list ────────────────────────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (_sets.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 64, color: TraumColors.coralOrange),
                      const SizedBox(height: 16),
                      Text(l10n.addExercise,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                  children: _sets.asMap().entries.map((e) {
                    final entry = e.value;
                    final ex = exercises.cast<Exercise?>().firstWhere(
                        (ex) => ex?.id == entry.exerciseId, orElse: () => null);
                    return _SetCard(
                      exerciseName: ex?.name ?? l10n.exercise,
                      muscleGroup: ex?.muscleGroup ?? '',
                      entry: entry,
                      onRemove: () => setState(() => _sets.removeAt(e.key)),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.coralOrange)),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: exercisesAsync.when(
              data: (exercises) => GradientButton(
                label: l10n.addExercise,
                onPressed: () => _showAddSetDialog(context, exercises),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddSetDialog(BuildContext context, List<Exercise> exercises) {
    if (exercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppLocalizations.of(context)!.noExercisesInLibrary)));
      return;
    }
    final useLbs = ref.read(unitPreferenceProvider);
    final allSetsAsync = ref.read(recentTrainingSetsProvider(90));
    final allSets = allSetsAsync.valueOrNull ?? [];

    int selectedExerciseId = exercises.first.id;
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();
    bool isWarmup = false;

    WorkoutSet? lastSet(int exerciseId) {
      final filtered = allSets.where((s) => s.exerciseId == exerciseId).toList();
      return filtered.isEmpty ? null : filtered.last;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          final last = lastSet(selectedExerciseId);
          final l10n = AppLocalizations.of(context)!;

          String lastHint;
          if (last != null) {
            final parts = <String>[];
            if (last.weightKg != null) {
              parts.add('${last.weightKg!.toDisplayUnit(useLbs).toStringAsFixed(1)} ${last.weightKg!.unitLabel(useLbs)}');
            }
            if (last.reps != null) parts.add(l10n.repsCount(last.reps!));
            lastHint = parts.isNotEmpty ? l10n.lastPerformanceHint(parts.join(' × ')) : l10n.noLastPerformance;
          } else {
            lastHint = l10n.noLastPerformance;
          }

          return AlertDialog(
            backgroundColor: TraumColors.surfaceElevated,
            title: Text(l10n.addSet,
                style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                DropdownButtonFormField<int>(
                  value: selectedExerciseId,
                  dropdownColor: TraumColors.surfaceElevated,
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                    labelText: l10n.exercise,
                    labelStyle: const TextStyle(
                        color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                    filled: true,
                    fillColor: TraumColors.surface,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(TraumRadius.card),
                        borderSide: BorderSide.none),
                  ),
                  items: exercises
                      .map((e) => DropdownMenuItem(value: e.id, child: Text(e.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setDialogState(() => selectedExerciseId = v);
                  },
                ),
                // Last-performance hint
                Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 4, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(lastHint,
                        style: const TextStyle(
                            color: TraumColors.coralOrange,
                            fontFamily: 'DMSans',
                            fontSize: 12)),
                  ),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: weightCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                    labelText: useLbs ? l10n.weightLbs : l10n.weightKg,
                    labelStyle: const TextStyle(
                        color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: repsCtrl,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
                  decoration: InputDecoration(
                    labelText: l10n.reps,
                    labelStyle: const TextStyle(
                        color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
                  ),
                ),
                const SizedBox(height: 10),
                // Warmup toggle
                GestureDetector(
                  onTap: () => setDialogState(() => isWarmup = !isWarmup),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isWarmup
                          ? TraumColors.coralOrange.withValues(alpha: 0.18)
                          : TraumColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isWarmup
                            ? TraumColors.coralOrange.withValues(alpha: 0.5)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        isWarmup
                            ? Icons.local_fire_department_rounded
                            : Icons.local_fire_department_outlined,
                        color: isWarmup
                            ? TraumColors.coralOrange
                            : TraumColors.onBackgroundMuted,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        l10n.warmupSet,
                        style: TextStyle(
                          color: isWarmup
                              ? TraumColors.coralOrange
                              : TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: isWarmup ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(l10n.cancel,
                    style: const TextStyle(color: TraumColors.onBackgroundMuted)),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _sets.add(_SetEntry(
                      exerciseId: selectedExerciseId,
                      setNumber: _sets.length + 1,
                      weightKg: (() {
                        final raw = double.tryParse(weightCtrl.text.replaceAll(',', '.'));
                        return (raw != null && useLbs) ? raw / 2.20462 : raw;
                      })(),
                      reps: int.tryParse(repsCtrl.text),
                      isWarmup: isWarmup,
                    ));
                  });
                  HapticFeedback.mediumImpact();
                  Navigator.pop(ctx);
                  _showRestTimer(context);
                },
                child: Text(l10n.add,
                    style: const TextStyle(
                        color: TraumColors.coralOrange, fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showRestTimer(BuildContext context) {
    final restDuration = ref.read(restDurationProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (_) => RestTimerWidget(
        durationSeconds: restDuration,
        onFinished: () => Navigator.pop(context),
        onSkip: () => Navigator.pop(context),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    if (_sessionId == null) return;
    setState(() => _finishing = true);
    final now = DateTime.now();
    await ref.read(trainingDaoProvider).updateSession(
          WorkoutSessionsCompanion(
            id: Value(_sessionId!),
            startedAt: Value(_startedAt),
            completedAt: Value(now),
            durationSeconds: Value(_elapsed.inSeconds),
          ),
        );
    for (final s in _sets) {
      await ref.read(trainingDaoProvider).insertSet(
            WorkoutSetsCompanion.insert(
              sessionId: _sessionId!,
              exerciseId: s.exerciseId,
              setNumber: s.setNumber,
              weightKg: Value(s.weightKg),
              reps: Value(s.reps),
              isWarmup: Value(s.isWarmup),
            ),
          );
    }
    if (mounted) context.go('/training/session/$_sessionId');
  }
}

class _SetEntry {
  final int exerciseId;
  final int setNumber;
  final double? weightKg;
  final int? reps;
  final bool isWarmup;

  _SetEntry({
    required this.exerciseId,
    required this.setNumber,
    this.weightKg,
    this.reps,
    this.isWarmup = false,
  });
}

class _SetCard extends ConsumerWidget {
  final String exerciseName;
  final String muscleGroup;
  final _SetEntry entry;
  final VoidCallback onRemove;

  const _SetCard({
    required this.exerciseName,
    required this.muscleGroup,
    required this.entry,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final useLbs = ref.watch(unitPreferenceProvider);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: entry.isWarmup
            ? TraumColors.coralOrange.withValues(alpha: 0.06)
            : TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
        border: entry.isWarmup
            ? Border.all(color: TraumColors.coralOrange.withValues(alpha: 0.2))
            : null,
      ),
      child: Row(children: [
        ExerciseIcon(muscleGroup: _muscleGroupKey(muscleGroup), size: 40),
        const SizedBox(width: 12),
        // Set badge: "W" for warmup, number for normal
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(
            color: entry.isWarmup ? TraumColors.coralOrange.withValues(alpha: 0.18) : TraumColors.coralDim,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              entry.isWarmup ? 'W' : '${entry.setNumber}',
              style: const TextStyle(
                  color: TraumColors.coralOrange,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 13),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(exerciseName,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600)),
            Text(
              [
                if (entry.weightKg != null)
                  '${entry.weightKg!.toDisplayUnit(useLbs).toStringAsFixed(1)} ${entry.weightKg!.unitLabel(useLbs)}',
                if (entry.reps != null)
                  AppLocalizations.of(context)!.repsCount(entry.reps!),
              ].join('  ×  '),
              style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12),
            ),
          ]),
        ),
        IconButton(
          icon: const Icon(Icons.close_rounded,
              color: TraumColors.onBackgroundSubtle, size: 18),
          onPressed: onRemove,
        ),
      ]),
    );
  }
}
