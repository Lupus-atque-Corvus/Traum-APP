import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';

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
    super.dispose();
  }

  String get _elapsedStr {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    if (h > 0) return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(
      StreamProvider((ref) => ref.watch(trainingDaoProvider).watchAllExercises()),
    );

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
            child: Text(_finishing ? 'Beenden…' : 'Fertig',
                style: const TextStyle(
                    color: TraumColors.mintGreen,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                if (_sets.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.add_circle_outline_rounded,
                          size: 64, color: TraumColors.coralOrange),
                      const SizedBox(height: 16),
                      const Text('Füge eine Übung hinzu',
                          style: TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: _sets.asMap().entries.map((e) {
                    final entry = e.value;
                    final ex = exercises.cast<Exercise?>().firstWhere(
                        (ex) => ex?.id == entry.exerciseId, orElse: () => null);
                    return _SetCard(
                      exerciseName: ex?.name ?? 'Übung',
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
                label: 'Übung hinzufügen',
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Keine Übungen in der Bibliothek. Zuerst Übungen anlegen.')));
      return;
    }
    int? selectedExerciseId = exercises.first.id;
    final weightCtrl = TextEditingController();
    final repsCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: const Text('Satz hinzufügen',
            style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
        content: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<int>(
              initialValue: selectedExerciseId,
              dropdownColor: TraumColors.surfaceElevated,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                labelText: 'Übung',
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
              onChanged: (v) => selectedExerciseId = v,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: weightCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: const InputDecoration(
                labelText: 'Gewicht (kg)',
                labelStyle: TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: repsCtrl,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: const InputDecoration(
                labelText: 'Wiederholungen',
                labelStyle: TextStyle(
                    color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
              ),
            ),
          ]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Abbrechen',
                style: TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () {
              if (selectedExerciseId == null) return;
              setState(() {
                _sets.add(_SetEntry(
                  exerciseId: selectedExerciseId!,
                  setNumber: _sets.length + 1,
                  weightKg: double.tryParse(weightCtrl.text.replaceAll(',', '.')),
                  reps: int.tryParse(repsCtrl.text),
                ));
              });
              Navigator.pop(ctx);
            },
            child: const Text('Hinzufügen',
                style: TextStyle(
                    color: TraumColors.coralOrange, fontWeight: FontWeight.w700)),
          ),
        ],
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
  _SetEntry(
      {required this.exerciseId,
      required this.setNumber,
      this.weightKg,
      this.reps});
}

class _SetCard extends StatelessWidget {
  final String exerciseName;
  final _SetEntry entry;
  final VoidCallback onRemove;

  const _SetCard(
      {required this.exerciseName, required this.entry, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: Row(children: [
        Container(
          width: 32, height: 32,
          decoration: const BoxDecoration(
              color: TraumColors.coralDim, shape: BoxShape.circle),
          child: Center(
            child: Text('${entry.setNumber}',
                style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 13)),
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
                if (entry.weightKg != null) '${entry.weightKg} kg',
                if (entry.reps != null) '${entry.reps} Wdh.',
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
