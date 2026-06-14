import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/rest_duration_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'exercise_picker_screen.dart';
import 'widgets/exercise_icon.dart';
import 'widgets/rest_timer_widget.dart';

// ── Set types ─────────────────────────────────────────────────────────────────
enum _SetType { normal, warmup, drop, failure }

extension _SetTypeExt on _SetType {
  String get key => switch (this) {
    _SetType.normal  => 'normal',
    _SetType.warmup  => 'warmup',
    _SetType.drop    => 'drop',
    _SetType.failure => 'failure',
  };
  String get badge => switch (this) {
    _SetType.normal  => '',   // will show set number
    _SetType.warmup  => 'W',
    _SetType.drop    => 'D',
    _SetType.failure => 'F',
  };
  Color get color => switch (this) {
    _SetType.normal  => TraumColors.coralOrange,
    _SetType.warmup  => const Color(0xFFE8B84B),
    _SetType.drop    => const Color(0xFF5BC4F5),
    _SetType.failure => const Color(0xFFE85555),
  };
}

// ── Data model ────────────────────────────────────────────────────────────────
class _SetRow {
  int setNumber;
  _SetType setType = _SetType.normal;
  final TextEditingController weightCtrl;
  final TextEditingController repsCtrl;

  _SetRow({
    required this.setNumber,
    double? weightKg,
    int? reps,
  })  : weightCtrl = TextEditingController(
            text: weightKg != null ? weightKg.toStringAsFixed(1) : ''),
        repsCtrl = TextEditingController(
            text: reps != null ? '$reps' : '');

  double? get weightKg => double.tryParse(weightCtrl.text.replaceAll(',', '.'));
  int? get reps => int.tryParse(repsCtrl.text);

  void dispose() {
    weightCtrl.dispose();
    repsCtrl.dispose();
  }
}

class _ExerciseBlock {
  final Exercise exercise;
  String equipment;
  String mode = 'Bilateral';
  String? note;
  bool supersetWithNext = false;
  final List<_SetRow> sets;

  _ExerciseBlock({
    required this.exercise,
    String? equipment,
    List<_SetRow>? sets,
  })  : equipment = equipment ?? exercise.equipment ?? '',
        sets = sets ?? [_SetRow(setNumber: 1)];

  void dispose() {
    for (final s in sets) {
      s.dispose();
    }
  }
}

// ── Muscle group key helper ───────────────────────────────────────────────────
String _mgKey(String g) {
  switch (g.toLowerCase()) {
    case 'chest':     return 'chest';
    case 'back':      return 'back';
    case 'shoulders': return 'shoulders';
    case 'biceps':    return 'biceps';
    case 'triceps':   return 'triceps';
    case 'core':      return 'core';
    case 'legs':      return 'legs';
    case 'cardio':    return 'cardio';
    default:          return 'full_body';
  }
}

bool _isCardio(Exercise ex) => ex.muscleGroup.toLowerCase() == 'cardio';

// ─────────────────────────────────────────────────────────────────────────────
// ActiveWorkoutScreen
// ─────────────────────────────────────────────────────────────────────────────
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
  final _blocks = <_ExerciseBlock>[];
  bool _finishing = false;
  bool _isFavorite = false;
  final _mainScrollCtrl = ScrollController();
  final _sidebarScrollCtrl = ScrollController();
  int _focusedBlock = 0;

  // Approximate key heights for sidebar sync
  final _blockKeys = <GlobalKey>[];

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
    for (final b in _blocks) {
      b.dispose();
    }
    _mainScrollCtrl.dispose();
    _sidebarScrollCtrl.dispose();
    super.dispose();
  }

  String get _elapsedStr {
    final h = _elapsed.inHours;
    final m = _elapsed.inMinutes % 60;
    final s = _elapsed.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get _estimatedStr {
    final totalSets = _blocks.fold(0, (sum, b) => sum + b.sets.length);
    final est = Duration(seconds: totalSets * 120);
    final h = est.inHours;
    final m = est.inMinutes % 60;
    final s = est.inSeconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        title: const Text(
          'New Workout',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: _isFavorite ? TraumColors.coralOrange : TraumColors.onBackground,
            ),
            onPressed: _toggleFavorite,
          ),
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: TraumColors.onBackground),
            onPressed: () => _showWorkoutOptions(context),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Timer row ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                Text(
                  _elapsedStr,
                  style: const TextStyle(
                    color: TraumColors.coralOrange,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '/ $_estimatedStr',
                  style: const TextStyle(
                    color: TraumColors.onBackgroundSubtle,
                    fontFamily: 'DMSans',
                    fontSize: 14,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _finishing ? null : _finishWorkout,
                  icon: const Icon(Icons.play_arrow_rounded, size: 16),
                  label: Text(
                    _finishing ? l10n.finishing : l10n.done,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TraumColors.coralOrange,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: TraumColors.surfaceVariant),

          // ── Main body ────────────────────────────────────────────────────
          Expanded(
            child: _blocks.isEmpty
                ? _buildEmptyState(context)
                : Row(
                    children: [
                      // Left sidebar: exercise thumbnails
                      Container(
                        width: 66,
                        color: const Color(0xFF131625),
                        child: ListView.builder(
                          controller: _sidebarScrollCtrl,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _blocks.length,
                          itemBuilder: (_, i) => _SidebarThumb(
                            exercise: _blocks[i].exercise,
                            active: i == _focusedBlock,
                            onTap: () => _scrollToBlock(i),
                          ),
                        ),
                      ),
                      // Right: exercise cards
                      Expanded(
                        child: ListView.builder(
                          controller: _mainScrollCtrl,
                          padding: const EdgeInsets.only(bottom: 24),
                          itemCount: _blocks.length + 1,
                          itemBuilder: (_, i) {
                            if (i == _blocks.length) {
                              return _AddExerciseFooter(
                                onTap: () => _openExercisePicker(context),
                              );
                            }
                            return _ExerciseCard(
                              key: _blockKeys[i],
                              block: _blocks[i],
                              canLink: i < _blocks.length - 1,
                              onToggleLink: () => setState(() => _blocks[i]
                                  .supersetWithNext = !_blocks[i].supersetWithNext),
                              onChanged: () => setState(() {}),
                              onRemove: () => setState(() {
                                _blocks[i].dispose();
                                _blocks.removeAt(i);
                                _blockKeys.removeAt(i);
                                if (_focusedBlock >= _blocks.length && _focusedBlock > 0) {
                                  _focusedBlock--;
                                }
                              }),
                              onNavigateToDetail: () =>
                                  context.go('/training/exercise/${_blocks[i].exercise.id}/progress'),
                              onShowRestTimer: () => _showRestTimer(context),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.add_circle_outline_rounded,
            size: 64, color: TraumColors.coralOrange),
        const SizedBox(height: 16),
        const Text(
          'Add your first exercise',
          style: TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _openExercisePicker(context),
          icon: const Icon(Icons.add_rounded),
          label: const Text('Add Exercise',
              style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: TraumColors.coralOrange,
            foregroundColor: Colors.white,
            elevation: 0,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
          ),
        ),
      ],
    );
  }

  void _scrollToBlock(int index) {
    setState(() => _focusedBlock = index);
    if (_blockKeys.length > index) {
      final ctx = _blockKeys[index].currentContext;
      if (ctx != null) {
        Scrollable.ensureVisible(ctx,
            duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      }
    }
  }

  Future<void> _openExercisePicker(BuildContext context) async {
    final result = await Navigator.of(context).push<List<PickedExercise>>(
      MaterialPageRoute(builder: (_) => const ExercisePickerScreen()),
    );
    if (result == null || result.isEmpty) return;
    setState(() {
      for (final picked in result) {
        _blocks.add(_ExerciseBlock(exercise: picked.exercise));
        _blockKeys.add(GlobalKey());
      }
      _focusedBlock = _blocks.length - result.length;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBlock(_focusedBlock);
    });
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

  Future<void> _toggleFavorite() async {
    if (_blocks.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Noch keine Übungen im Workout')),
      );
      return;
    }
    final next = !_isFavorite;
    final dao = ref.read(trainingDaoProvider);
    for (final block in _blocks) {
      await dao.setBookmarked(block.exercise.id, next);
    }
    if (!mounted) return;
    setState(() => _isFavorite = next);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(next
            ? 'Übungen zu Favoriten hinzugefügt'
            : 'Übungen aus Favoriten entfernt'),
      ),
    );
  }

  void _showWorkoutOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.cancel_outlined, color: TraumColors.coralOrange),
            title: const Text('Discard Workout',
                style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
          ),
        ]),
      ),
    );
  }

  Future<void> _finishWorkout() async {
    if (_sessionId == null) return;
    setState(() => _finishing = true);
    final now = DateTime.now();
    await ref.read(trainingDaoProvider).updateSession(WorkoutSessionsCompanion(
      id: Value(_sessionId!),
      startedAt: Value(_startedAt),
      completedAt: Value(now),
      durationSeconds: Value(_elapsed.inSeconds),
    ));
    int globalSetNum = 1;
    for (final block in _blocks) {
      for (final s in block.sets) {
        await ref.read(trainingDaoProvider).insertSet(WorkoutSetsCompanion.insert(
          sessionId: _sessionId!,
          exerciseId: block.exercise.id,
          setNumber: globalSetNum++,
          weightKg: Value(s.weightKg),
          reps: Value(s.reps),
          isWarmup: Value(s.setType == _SetType.warmup),
          setType: Value(s.setType.key),
        ));
        HapticFeedback.mediumImpact();
      }
    }
    if (mounted) context.go('/training/session/$_sessionId');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sidebar thumbnail
// ─────────────────────────────────────────────────────────────────────────────
class _SidebarThumb extends StatelessWidget {
  final Exercise exercise;
  final bool active;
  final VoidCallback onTap;
  const _SidebarThumb({required this.exercise, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        width: 52, height: 52,
        decoration: BoxDecoration(
          color: active ? TraumColors.coralOrange.withValues(alpha: 0.15) : const Color(0xFF1E2235),
          borderRadius: BorderRadius.circular(10),
          border: active ? Border.all(color: TraumColors.coralOrange, width: 1.5) : null,
        ),
        child: Center(
          child: ExerciseIcon(muscleGroup: _mgKey(exercise.muscleGroup), size: 36),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise card (the main workout editing unit)
// ─────────────────────────────────────────────────────────────────────────────
class _ExerciseCard extends StatefulWidget {
  final _ExerciseBlock block;
  final bool canLink;
  final VoidCallback onToggleLink;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final VoidCallback onNavigateToDetail;
  final VoidCallback onShowRestTimer;

  const _ExerciseCard({
    super.key,
    required this.block,
    required this.canLink,
    required this.onToggleLink,
    required this.onChanged,
    required this.onRemove,
    required this.onNavigateToDetail,
    required this.onShowRestTimer,
  });

  @override
  State<_ExerciseCard> createState() => _ExerciseCardState();
}

class _ExerciseCardState extends State<_ExerciseCard> {
  _ExerciseBlock get block => widget.block;

  void _addSet() {
    setState(() {
      final lastSet = block.sets.isNotEmpty ? block.sets.last : null;
      block.sets.add(_SetRow(
        setNumber: block.sets.length + 1,
        weightKg: lastSet?.weightKg,
        reps: lastSet?.reps,
      ));
    });
    widget.onChanged();
    widget.onShowRestTimer();
    HapticFeedback.lightImpact();
  }

  void _showSetTypeMenu(BuildContext context, int setIndex) {
    final set = block.sets[setIndex];
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ..._SetType.values.map((type) => ListTile(
                leading: _SetTypeBadge(type: type, number: setIndex + 1, size: 32),
                title: Text(
                  switch (type) {
                    _SetType.normal  => 'Normal set',
                    _SetType.warmup  => 'Warm-up set',
                    _SetType.drop    => 'Drop set',
                    _SetType.failure => 'Failure set',
                  },
                  style: TextStyle(
                    color: type == _SetType.normal
                        ? TraumColors.onBackground
                        : type.color,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onTap: () {
                  setState(() => set.setType = type);
                  widget.onChanged();
                  Navigator.pop(context);
                },
              )),
          const Divider(color: TraumColors.surfaceVariant),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: TraumColors.coralOrange),
            title: const Text('Delete set',
                style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans')),
            onTap: () {
              setState(() {
                block.sets[setIndex].dispose();
                block.sets.removeAt(setIndex);
                for (int i = 0; i < block.sets.length; i++) {
                  block.sets[i].setNumber = i + 1;
                }
              });
              widget.onChanged();
              Navigator.pop(context);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showExerciseOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: TraumColors.onBackground),
            title: const Text('Exercise Info',
                style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              widget.onNavigateToDetail();
            },
          ),
          ListTile(
            leading: const Icon(Icons.note_add_outlined, color: TraumColors.coralOrange),
            title: const Text('Add a note',
                style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              _showAddNote(context);
            },
          ),
          const Divider(color: TraumColors.surfaceVariant),
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: TraumColors.coralOrange),
            title: const Text('Remove Exercise',
                style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              widget.onRemove();
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showAddNote(BuildContext context) {
    final ctrl = TextEditingController(text: block.note);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(16, 16, 16,
            MediaQuery.of(context).viewInsets.bottom + 16),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: ctrl,
            autofocus: true,
            maxLines: 3,
            style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            decoration: InputDecoration(
              hintText: 'Add a note...',
              hintStyle: const TextStyle(
                  color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(TraumRadius.card),
                  borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: TraumColors.onBackgroundMuted)),
              ),
            ),
            Expanded(
              child: ElevatedButton(
                onPressed: () {
                  setState(() => block.note = ctrl.text.trim().isEmpty ? null : ctrl.text.trim());
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.coralOrange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                ),
                child: const Text('Save',
                    style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ]),
      ),
    );
  }

  void _showEquipmentPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _EquipmentModePicker(
        initialEquipment: block.equipment,
        initialMode: block.mode,
        onSave: (equipment, mode) {
          setState(() {
            block.equipment = equipment;
            block.mode = mode;
          });
          widget.onChanged();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isCardio = _isCardio(block.exercise);

    return Container(
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: icon + name + link + menu ──────────────────────────
          Row(children: [
            ExerciseIcon(muscleGroup: _mgKey(block.exercise.muscleGroup), size: 38),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                block.exercise.name,
                style: const TextStyle(
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
            ),
            if (widget.canLink)
              IconButton(
                tooltip: block.supersetWithNext
                    ? 'Superset mit nächster Übung aufheben'
                    : 'Mit nächster Übung zum Superset verbinden',
                icon: Icon(
                  block.supersetWithNext
                      ? Icons.link_rounded
                      : Icons.link_off_rounded,
                  color: block.supersetWithNext
                      ? TraumColors.coralOrange
                      : TraumColors.onBackgroundMuted,
                  size: 20,
                ),
                onPressed: widget.onToggleLink,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            IconButton(
              icon: const Icon(Icons.more_vert_rounded,
                  color: TraumColors.onBackgroundMuted, size: 20),
              onPressed: () => _showExerciseOptions(context),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          ]),
          if (block.supersetWithNext)
            Padding(
              padding: const EdgeInsets.only(top: 2, bottom: 2),
              child: Row(
                children: [
                  const Icon(Icons.link_rounded,
                      color: TraumColors.coralOrange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    'Superset mit nächster Übung',
                    style: TextStyle(
                      color: TraumColors.coralOrange.withValues(alpha: 0.9),
                      fontFamily: 'DMSans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 8),

          // ── Equipment + Mode pills ──────────────────────────────────────
          Row(children: [
            GestureDetector(
              onTap: () => _showEquipmentPicker(context),
              child: _EquipmentPill(label: block.equipment.isNotEmpty ? block.equipment : 'Equipment'),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => _showEquipmentPicker(context),
              child: _ModePill(label: block.mode),
            ),
            const Spacer(),
            Icon(Icons.bar_chart_rounded,
                color: TraumColors.onBackgroundSubtle, size: 18),
          ]),

          if (block.note != null) ...[
            const SizedBox(height: 6),
            Text(block.note!,
                style: const TextStyle(
                  color: TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                )),
          ],

          const SizedBox(height: 12),

          // ── Set table header ────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(children: [
              const SizedBox(width: 40),
              Expanded(
                child: Text(
                  isCardio ? 'Time' : 'Reps',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  isCardio ? 'Dist. (km)' : 'Weight',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 36),
            ]),
          ),
          const SizedBox(height: 4),

          // ── Set rows ────────────────────────────────────────────────────
          ...block.sets.asMap().entries.map((entry) {
            final i = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(children: [
                // Set type badge
                GestureDetector(
                  onTap: () => _showSetTypeMenu(context, i),
                  child: _SetTypeBadge(type: set.setType, number: set.setNumber, size: 32),
                ),
                const SizedBox(width: 8),
                // Reps / Time field
                Expanded(
                  child: _InlineValueCell(controller: set.repsCtrl),
                ),
                const SizedBox(width: 8),
                // Weight / Distance field
                Expanded(
                  child: _InlineValueCell(
                    controller: set.weightCtrl,
                    decimal: true,
                  ),
                ),
                const SizedBox(width: 4),
                // Empty spacer matching + button width
                const SizedBox(width: 36),
              ]),
            );
          }),

          // ── Add set row ─────────────────────────────────────────────────
          Row(children: [
            const SizedBox(width: 40),
            Expanded(child: Container()),
            Expanded(child: Container()),
            SizedBox(
              width: 36,
              child: IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: TraumColors.coralOrange, size: 22),
                onPressed: _addSet,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ),
          ]),

          Container(
            height: 1,
            margin: const EdgeInsets.only(top: 8),
            color: TraumColors.surfaceVariant,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Set type badge widget
// ─────────────────────────────────────────────────────────────────────────────
class _SetTypeBadge extends StatelessWidget {
  final _SetType type;
  final int number;
  final double size;
  const _SetTypeBadge({required this.type, required this.number, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final label = type == _SetType.normal ? '$number' : type.badge;
    return Container(
      width: size, height: size,
      decoration: BoxDecoration(
        color: type.color.withValues(alpha: 0.15),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            color: type.color,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: size * 0.4,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inline editable value cell
// ─────────────────────────────────────────────────────────────────────────────
class _InlineValueCell extends StatelessWidget {
  final TextEditingController controller;
  final bool decimal;
  const _InlineValueCell({required this.controller, this.decimal = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D2E),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: TextField(
          controller: controller,
          keyboardType: decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            isDense: true,
            contentPadding: EdgeInsets.symmetric(vertical: 8),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment pill
// ─────────────────────────────────────────────────────────────────────────────
class _EquipmentPill extends StatelessWidget {
  final String label;
  const _EquipmentPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFF3A2E1A),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF8B6914), width: 0.8),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.fitness_center_rounded, size: 12, color: Color(0xFFE8B84B)),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFFE8B84B),
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Mode pill
// ─────────────────────────────────────────────────────────────────────────────
class _ModePill extends StatelessWidget {
  final String label;
  const _ModePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: TraumColors.surfaceVariant,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: TraumColors.surfaceVariant),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Equipment + Mode picker bottom sheet
// ─────────────────────────────────────────────────────────────────────────────
class _EquipmentModePicker extends StatefulWidget {
  final String initialEquipment;
  final String initialMode;
  final void Function(String equipment, String mode) onSave;
  const _EquipmentModePicker({
    required this.initialEquipment,
    required this.initialMode,
    required this.onSave,
  });

  @override
  State<_EquipmentModePicker> createState() => _EquipmentModePickerState();
}

class _EquipmentModePickerState extends State<_EquipmentModePicker>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  late String _equipment;
  late String _mode;

  static const _equipments = [
    ('Dumbbells',            Icons.fitness_center_rounded,     Color(0xFFE8B84B)),
    ('Kettlebell',           Icons.sports_handball_rounded,    Color(0xFF5BC4F5)),
    ('Plate',                Icons.circle_outlined,            Color(0xFFBB86FC)),
    ('Resistance Band',      Icons.compress_rounded,           Color(0xFF81C784)),
    ('Cable Machine',        Icons.linear_scale_rounded,       Color(0xFFFF8A65)),
    ('Stack Machine',        Icons.settings_rounded,           Color(0xFF4FC3F7)),
    ('Plate Loaded Machine', Icons.precision_manufacturing_rounded, Color(0xFFA5D6A7)),
    ('Bodyweight',           Icons.accessibility_new_rounded,  Color(0xFFFFD54F)),
    ('Barbell',              Icons.remove_rounded,             Color(0xFFEF9A9A)),
    ('Smith Machine',        Icons.grid_on_rounded,            Color(0xFFCE93D8)),
  ];

  static const _modes = [
    ('Bilateral',   Icons.swap_horiz_rounded),
    ('Unilateral',  Icons.arrow_forward_rounded),
    ('Alternating', Icons.sync_alt_rounded),
  ];

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _equipment = widget.initialEquipment;
    _mode = widget.initialMode;
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Tabs
        TabBar(
          controller: _tabs,
          labelColor: const Color(0xFFE8B84B),
          unselectedLabelColor: TraumColors.onBackgroundMuted,
          indicatorColor: const Color(0xFFE8B84B),
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w700),
          tabs: [
            Tab(text: _equipment.isNotEmpty ? _equipment : 'Equipment'),
            Tab(text: _mode),
          ],
        ),
        Flexible(
          child: TabBarView(
            controller: _tabs,
            children: [
              // Equipment list
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _equipments.map((eq) {
                  final selected = _equipment == eq.$1;
                  return ListTile(
                    leading: Icon(eq.$2, color: selected ? eq.$3 : TraumColors.onBackgroundSubtle, size: 20),
                    title: Text(eq.$1,
                        style: TextStyle(
                          color: selected ? TraumColors.onBackground : TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        )),
                    trailing: selected
                        ? const Icon(Icons.radio_button_checked_rounded,
                            color: Color(0xFF4CAF50), size: 20)
                        : const Icon(Icons.radio_button_unchecked_rounded,
                            color: TraumColors.onBackgroundSubtle, size: 20),
                    onTap: () {
                      setState(() => _equipment = eq.$1);
                      widget.onSave(_equipment, _mode);
                    },
                  );
                }).toList(),
              ),
              // Mode list
              ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: _modes.map((m) {
                  final selected = _mode == m.$1;
                  return ListTile(
                    leading: Icon(m.$2,
                        color: selected ? TraumColors.onBackground : TraumColors.onBackgroundSubtle,
                        size: 20),
                    title: Text(m.$1,
                        style: TextStyle(
                          color: selected ? TraumColors.onBackground : TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        )),
                    trailing: selected
                        ? const Icon(Icons.radio_button_checked_rounded,
                            color: Color(0xFF4CAF50), size: 20)
                        : const Icon(Icons.radio_button_unchecked_rounded,
                            color: TraumColors.onBackgroundSubtle, size: 20),
                    onTap: () {
                      setState(() => _mode = m.$1);
                      widget.onSave(_equipment, _mode);
                    },
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add exercise footer button
// ─────────────────────────────────────────────────────────────────────────────
class _AddExerciseFooter extends StatelessWidget {
  final VoidCallback onTap;
  const _AddExerciseFooter({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 20)),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
        Icon(Icons.add_rounded, color: TraumColors.onBackgroundMuted, size: 18),
        SizedBox(width: 6),
        Text('Add Exercise',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            )),
      ]),
    );
  }
}
