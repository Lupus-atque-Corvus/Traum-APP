import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import 'widgets/exercise_icon.dart';

// ── Helpers (same as library screen) ─────────────────────────────────────────
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

const _kPickerCats = [
  _PickerCat('assets/exercises/icons/cardio.svg',    'Cardio',    ['cardio']),
  _PickerCat('assets/exercises/icons/biceps.svg',    'Arms',      ['biceps', 'triceps']),
  _PickerCat('assets/exercises/icons/shoulders.svg', 'Shoulders', ['shoulders']),
  _PickerCat('assets/exercises/icons/chest.svg',     'Chest',     ['chest']),
  _PickerCat('assets/exercises/icons/back.svg',      'Back',      ['back']),
  _PickerCat('assets/exercises/icons/core.svg',      'Abs',       ['core']),
  _PickerCat('assets/exercises/icons/legs.svg',      'Legs',      ['legs']),
];

class _PickerCat {
  final String svg;
  final String label;
  final List<String> keys;
  const _PickerCat(this.svg, this.label, this.keys);
}

// ─────────────────────────────────────────────────────────────────────────────
// ExercisePickerScreen
// Returns: List<_PickedExercise> via Navigator.pop
// ─────────────────────────────────────────────────────────────────────────────

class PickedExercise {
  final Exercise exercise;
  final bool asSuperset;
  PickedExercise(this.exercise, {this.asSuperset = false});
}

class ExercisePickerScreen extends ConsumerStatefulWidget {
  const ExercisePickerScreen({super.key});

  @override
  ConsumerState<ExercisePickerScreen> createState() => _ExercisePickerScreenState();
}

class _ExercisePickerScreenState extends ConsumerState<ExercisePickerScreen> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  bool _searchActive = false;
  final Set<int> _selectedCats = {};

  // Selected exercise IDs in order
  final List<Exercise> _selected = [];

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
      for (final i in _selectedCats) { allowed.addAll(_kPickerCats[i].keys); }
      list = list.where((e) => allowed.contains(e.muscleGroup)).toList();
    }
    return list;
  }

  bool _isSelected(Exercise ex) => _selected.any((s) => s.id == ex.id);

  void _toggle(Exercise ex) {
    setState(() {
      if (_isSelected(ex)) {
        _selected.removeWhere((s) => s.id == ex.id);
      } else {
        _selected.add(ex);
      }
    });
  }

  void _removeSelected(Exercise ex) {
    setState(() => _selected.removeWhere((s) => s.id == ex.id));
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    final counts = ref.watch(exerciseSetCountsProvider).valueOrNull ?? {};

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          // ── Filter icon bar ──────────────────────────────────────────────
          SizedBox(
            height: 76,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _kPickerCats.length,
              itemBuilder: (_, i) {
                final cat = _kPickerCats[i];
                final active = _selectedCats.contains(i);
                return GestureDetector(
                  onTap: () => setState(() {
                    if (active) { _selectedCats.remove(i); } else { _selectedCats.add(i); }
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
                        Text(cat.label,
                            style: TextStyle(
                              color: active ? TraumColors.coralOrange : TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontSize: 9,
                              fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                            )),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Exercise count row ───────────────────────────────────────────
          exercisesAsync.when(
            data: (all) {
              final filtered = _applyFilters(all);
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 2, 16, 4),
                child: Row(children: [
                  const Spacer(),
                  Text('${filtered.length} / ${all.length}',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans', fontSize: 12,
                      )),
                ]),
              );
            },
            loading: () => const SizedBox(height: 20),
            error: (_, __) => const SizedBox(height: 20),
          ),

          Container(height: 1, color: TraumColors.surfaceVariant),

          // ── Main content: selected sidebar + exercise list ─────────────
          Expanded(
            child: exercisesAsync.when(
              data: (all) {
                final exercises = _applyFilters(all)
                  ..sort((a, b) {
                    final ca = counts[a.id] ?? 0;
                    final cb = counts[b.id] ?? 0;
                    if (ca != cb) return cb.compareTo(ca);
                    return a.name.compareTo(b.name);
                  });

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Selected exercises sidebar ──────────────────────
                    if (_selected.isNotEmpty)
                      Container(
                        width: 72,
                        color: const Color(0xFF161929),
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: _selected.length,
                          itemBuilder: (_, i) {
                            final ex = _selected[i];
                            return _SelectedThumb(
                              exercise: ex,
                              onRemove: () => _removeSelected(ex),
                            );
                          },
                        ),
                      ),
                    // ── Exercise list ───────────────────────────────────
                    Expanded(
                      child: ListView.builder(
                        itemCount: exercises.length,
                        itemBuilder: (_, i) {
                          final ex = exercises[i];
                          final selected = _isSelected(ex);
                          return _PickerTile(
                            exercise: ex,
                            usageCount: counts[ex.id] ?? 0,
                            selected: selected,
                            onTap: () => _toggle(ex),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                  child: CircularProgressIndicator(color: TraumColors.coralOrange)),
              error: (e, _) => Center(child: Text('$e')),
            ),
          ),

          // ── Bottom action bar ────────────────────────────────────────────
          if (_selected.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: TraumColors.surfaceElevated,
                border: Border(top: BorderSide(color: TraumColors.surfaceVariant)),
              ),
              padding: EdgeInsets.fromLTRB(
                  16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
              child: Row(
                children: [
                  // Superset button
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _selected.length >= 2
                          ? () => _addAll(asSuperset: true)
                          : null,
                      icon: const Icon(Icons.link_rounded, size: 18),
                      label: const Text('Superset',
                          style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: TraumColors.onBackground,
                        side: const BorderSide(color: TraumColors.surfaceVariant),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TraumRadius.card),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add All button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _addAll(),
                      icon: const Icon(Icons.add_rounded, size: 18),
                      label: Text(
                        'Add All (${_selected.length})',
                        style: const TextStyle(
                          fontFamily: 'DMSans', fontWeight: FontWeight.w700),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: TraumColors.coralOrange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(TraumRadius.card),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _addAll({bool asSuperset = false}) {
    final result = _selected.map((ex) => PickedExercise(ex, asSuperset: asSuperset)).toList();
    Navigator.of(context).pop(result);
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
          style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
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
        const Icon(Icons.filter_list_rounded, color: TraumColors.onBackground),
        const SizedBox(width: 12),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Selected exercise thumbnail in sidebar
// ─────────────────────────────────────────────────────────────────────────────
class _SelectedThumb extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onRemove;
  const _SelectedThumb({required this.exercise, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF1E2235),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: ExerciseIcon(muscleGroup: _mgKey(exercise.muscleGroup), size: 40),
            ),
          ),
          Positioned(
            top: -4, right: -4,
            child: GestureDetector(
              onTap: onRemove,
              child: Container(
                width: 18, height: 18,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close_rounded, size: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Exercise tile in picker (Blast-style, with selection highlight)
// ─────────────────────────────────────────────────────────────────────────────
class _PickerTile extends StatelessWidget {
  final Exercise exercise;
  final int usageCount;
  final bool selected;
  final VoidCallback onTap;
  const _PickerTile({
    required this.exercise,
    required this.usageCount,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        color: selected
            ? TraumColors.coralOrange.withValues(alpha: 0.08)
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF1E2235),
                borderRadius: BorderRadius.circular(10),
                border: selected
                    ? Border.all(color: TraumColors.coralOrange, width: 1.5)
                    : null,
              ),
              child: Center(
                child: ExerciseIcon(muscleGroup: _mgKey(exercise.muscleGroup), size: 38),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exercise.name,
                      style: TextStyle(
                        color: selected ? TraumColors.coralOrange : TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      )),
                  const SizedBox(height: 2),
                  Text(_mgDisplay(exercise.muscleGroup),
                      style: const TextStyle(
                        color: TraumColors.coralOrange,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                        letterSpacing: 0.4,
                      )),
                ],
              ),
            ),
            if (usageCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: TraumColors.coralOrange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text('$usageCount',
                    style: const TextStyle(
                      color: Colors.white, fontFamily: 'DMSans',
                      fontWeight: FontWeight.w700, fontSize: 11,
                    )),
              ),
          ],
        ),
      ),
    );
  }
}
