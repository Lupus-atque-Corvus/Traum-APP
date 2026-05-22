import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'widgets/exercise_icon.dart';

// ── Muscle group display names ────────────────────────────────────────────────
String _mgDisplay(String key) {
  switch (key.toLowerCase()) {
    case 'chest':     return 'PECTORALS';
    case 'back':      return 'LATS';
    case 'shoulders': return 'DELTOIDS';
    case 'biceps':    return 'BICEPS';
    case 'triceps':   return 'TRICEPS';
    case 'core':      return 'ABDOMINALS';
    case 'legs':      return 'QUADRICEPS, GLUTES';
    case 'cardio':    return 'CARDIO';
    case 'full_body': return 'FULL BODY';
    default:          return key.toUpperCase();
  }
}

// ── Muscle group icon key ─────────────────────────────────────────────────────
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

// ── Equipment icon ────────────────────────────────────────────────────────────
IconData _equipIcon(String? eq) {
  if (eq == null) return Icons.accessibility_new_rounded;
  final l = eq.toLowerCase();
  if (l.contains('hantel') || l.contains('dumbbell') || l.contains('barbell') ||
      l.contains('stange') || l.contains('langhantel')) return Icons.fitness_center_rounded;
  if (l.contains('maschine') || l.contains('machine')) return Icons.settings_rounded;
  if (l.contains('kabel') || l.contains('cable')) return Icons.linear_scale_rounded;
  if (l.contains('kettlebell')) return Icons.sports_handball_rounded;
  if (l.contains('band') || l.contains('theraband')) return Icons.compress_rounded;
  if (l.contains('bank') || l.contains('bench')) return Icons.airline_seat_flat_rounded;
  return Icons.fitness_center_rounded;
}

// ── 7 Filter categories (Blast-style body icons) ─────────────────────────────
class _Cat {
  final String svg;
  final String label;
  final List<String> keys;
  const _Cat(this.svg, this.label, this.keys);
}

const _kCats = [
  _Cat('assets/exercises/icons/cardio.svg',    'Cardio',    ['cardio']),
  _Cat('assets/exercises/icons/biceps.svg',    'Arms',      ['biceps', 'triceps']),
  _Cat('assets/exercises/icons/shoulders.svg', 'Shoulders', ['shoulders']),
  _Cat('assets/exercises/icons/chest.svg',     'Chest',     ['chest']),
  _Cat('assets/exercises/icons/back.svg',      'Back',      ['back']),
  _Cat('assets/exercises/icons/core.svg',      'Abs',       ['core']),
  _Cat('assets/exercises/icons/legs.svg',      'Legs',      ['legs']),
];

// ─────────────────────────────────────────────────────────────────────────────

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _searchActive = false;
  final Set<int> _selectedCats = {};

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Exercise> _applyFilters(List<Exercise> all) {
    var list = all;
    if (_search.isNotEmpty) {
      list = list.where((e) => e.name.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    if (_selectedCats.isNotEmpty) {
      final allowed = <String>{};
      for (final i in _selectedCats) allowed.addAll(_kCats[i].keys);
      list = list.where((e) => allowed.contains(e.muscleGroup)).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    final counts = ref.watch(exerciseSetCountsProvider).valueOrNull ?? {};
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Filter icon bar ──────────────────────────────────────────────
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kCats.length,
              itemBuilder: (_, i) {
                final cat = _kCats[i];
                final active = _selectedCats.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (active) _selectedCats.remove(i); else _selectedCats.add(i);
                  }),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: active ? TraumColors.coralOrange : TraumColors.surfaceVariant,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: SvgPicture.asset(
                            cat.svg,
                            colorFilter: ColorFilter.mode(
                              active ? Colors.white : TraumColors.onBackgroundMuted,
                              BlendMode.srcIn,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          cat.label,
                          style: TextStyle(
                            color: active ? TraumColors.coralOrange : TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 9,
                            fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Clear filters / count row ────────────────────────────────────
          exercisesAsync.when(
            data: (all) {
              final filtered = _applyFilters(all);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                child: Row(
                  children: [
                    if (_selectedCats.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _selectedCats.clear()),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.close_rounded,
                              size: 13, color: TraumColors.onBackgroundMuted),
                          const SizedBox(width: 4),
                          Text(
                            'Clear filters (${_selectedCats.length})',
                            style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 12,
                            ),
                          ),
                        ]),
                      ),
                    const Spacer(),
                    Text(
                      '${filtered.length} / ${all.length}',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              );
            },
            loading: () => const SizedBox(height: 20),
            error: (_, __) => const SizedBox(height: 20),
          ),

          // ── Divider ──────────────────────────────────────────────────────
          Container(height: 1, color: TraumColors.surfaceVariant),

          // ── Exercise list ────────────────────────────────────────────────
          Expanded(
            child: exercisesAsync.when(
              data: (all) {
                final exercises = _applyFilters(all);
                exercises.sort((a, b) {
                  final ca = counts[a.id] ?? 0;
                  final cb = counts[b.id] ?? 0;
                  if (ca != cb) return cb.compareTo(ca);
                  return a.name.compareTo(b.name);
                });

                if (exercises.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.fitness_center_rounded,
                          size: 48, color: TraumColors.onBackgroundSubtle),
                      const SizedBox(height: 12),
                      Text(
                        all.isEmpty ? l10n.noExercisesYet : l10n.noResults,
                        style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ]),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.only(bottom: 24),
                  itemCount: exercises.length + 1,
                  itemBuilder: (_, i) {
                    if (i == exercises.length) {
                      return _CreateExerciseButton(
                        onTap: () => _showAddExerciseSheet(context),
                      );
                    }
                    final ex = exercises[i];
                    return _ExerciseTile(
                      exercise: ex,
                      usageCount: counts[ex.id] ?? 0,
                      onTap: () => context.go('/training/exercise/${ex.id}/progress'),
                      onDelete: ex.isCustom
                          ? () => ref.read(trainingDaoProvider).deleteExercise(ex.id)
                          : null,
                    );
                  },
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.coralOrange)),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    if (_searchActive) {
      return AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: TraumColors.onBackground),
          onPressed: () => setState(() {
            _searchActive = false;
            _searchCtrl.clear();
            _search = '';
          }),
        ),
        title: TextField(
          controller: _searchCtrl,
          autofocus: true,
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans', fontSize: 16),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Search exercises...',
            hintStyle: TextStyle(color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          ),
          onChanged: (v) => setState(() => _search = v),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: TraumColors.onBackground),
            onPressed: () => setState(() {
              _searchActive = false;
              _searchCtrl.clear();
              _search = '';
            }),
          ),
          _FilterBadgeButton(count: _selectedCats.length),
        ],
      );
    }

    return AppBar(
      backgroundColor: TraumColors.background,
      elevation: 0,
      iconTheme: const IconThemeData(color: TraumColors.onBackground),
      title: const SizedBox.shrink(),
      actions: [
        IconButton(
          icon: const Icon(Icons.search_rounded, color: TraumColors.onBackground),
          onPressed: () => setState(() => _searchActive = true),
        ),
        _FilterBadgeButton(count: _selectedCats.length),
        const SizedBox(width: 4),
      ],
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (_) => _AddExerciseSheet(
        onAdd: (c) => ref.read(trainingDaoProvider).insertExercise(c),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter badge button
// ─────────────────────────────────────────────────────────────────────────────
class _FilterBadgeButton extends StatelessWidget {
  final int count;
  const _FilterBadgeButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44, height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          const Icon(Icons.filter_list_rounded, color: TraumColors.onBackground, size: 24),
          if (count > 0)
            Positioned(
              top: 4, right: 4,
              child: Container(
                width: 16, height: 16,
                decoration: const BoxDecoration(
                  color: TraumColors.coralOrange,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    '$count',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'DMSans',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise tile (Blast-style)
// ─────────────────────────────────────────────────────────────────────────────
class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final int usageCount;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ExerciseTile({
    required this.exercise,
    required this.usageCount,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onDelete != null ? () => _showOptions(context) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            // ── Icon ──────────────────────────────────────────────────────
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: ExerciseIcon(muscleGroup: _mgKey(exercise.muscleGroup), size: 42),
              ),
            ),
            const SizedBox(width: 14),
            // ── Info ──────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      color: TraumColors.onBackground,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _mgDisplay(exercise.muscleGroup),
                    style: const TextStyle(
                      color: TraumColors.coralOrange,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                      letterSpacing: 0.4,
                    ),
                  ),
                  if (exercise.equipment != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(_equipIcon(exercise.equipment),
                            size: 13, color: TraumColors.onBackgroundSubtle),
                        const SizedBox(width: 4),
                        Text(
                          exercise.equipment!,
                          style: const TextStyle(
                            color: TraumColors.onBackgroundSubtle,
                            fontFamily: 'DMSans',
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            // ── Usage badge ───────────────────────────────────────────────
            if (usageCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: TraumColors.coralOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '$usageCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.delete_rounded, color: TraumColors.coralOrange),
            title: const Text(
              'Delete Exercise',
              style: TextStyle(color: TraumColors.coralOrange, fontFamily: 'DMSans'),
            ),
            onTap: () {
              Navigator.pop(context);
              onDelete?.call();
            },
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Create Exercise button at list bottom
// ─────────────────────────────────────────────────────────────────────────────
class _CreateExerciseButton extends StatelessWidget {
  final VoidCallback onTap;
  const _CreateExerciseButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onTap,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 20),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: const [
          Icon(Icons.add_rounded, color: TraumColors.onBackgroundMuted, size: 18),
          SizedBox(width: 6),
          Text(
            'Create Exercise',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Add Exercise Sheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddExerciseSheet extends StatefulWidget {
  final Future<void> Function(ExercisesCompanion) onAdd;
  const _AddExerciseSheet({required this.onAdd});

  @override
  State<_AddExerciseSheet> createState() => _AddExerciseSheetState();
}

class _AddExerciseSheetState extends State<_AddExerciseSheet> {
  final _nameCtrl = TextEditingController();
  final _equipCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  String _muscleGroup = 'chest';
  bool _saving = false;

  static const _muscleGroups = [
    'chest', 'back', 'shoulders', 'biceps', 'triceps',
    'core', 'legs', 'cardio', 'full_body',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _equipCtrl.dispose();
    _instrCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: TraumColors.onBackgroundSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.createExercise,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 16),
            _buildField(l10n.fieldName, _nameCtrl, hint: l10n.exerciseHint),
            const SizedBox(height: 12),
            Text(
              l10n.muscleGroup,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _muscleGroup,
              dropdownColor: TraumColors.surfaceElevated,
              isExpanded: true,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              underline: Container(height: 1, color: TraumColors.surfaceVariant),
              items: _muscleGroups.map((m) => DropdownMenuItem(
                value: m,
                child: Text(_mgDisplay(m)),
              )).toList(),
              onChanged: (v) => setState(() => _muscleGroup = v!),
            ),
            const SizedBox(height: 12),
            _buildField(l10n.equipmentOptional, _equipCtrl, hint: l10n.equipmentHint),
            const SizedBox(height: 12),
            _buildField(l10n.instructionsOptional, _instrCtrl,
                hint: l10n.instructionExecution, lines: 3),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? l10n.saving : l10n.createExercise,
              onPressed: _saving ? null : _save,
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl,
      {String? hint, int lines = 1}) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans', fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        maxLines: lines,
        style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(
              color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
          filled: true,
          fillColor: TraumColors.surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(TraumRadius.card),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    final l10n = AppLocalizations.of(context)!;
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(ExercisesCompanion.insert(
      name: _nameCtrl.text.trim(),
      muscleGroup: _muscleGroup,
      equipment: Value(_equipCtrl.text.trim().isEmpty ? null : _equipCtrl.text.trim()),
      instructions: Value(_instrCtrl.text.trim().isEmpty ? null : _instrCtrl.text.trim()),
      isCustom: const Value(true),
    ));
    if (mounted) Navigator.pop(context);
  }
}
