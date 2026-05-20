import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

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

class ExerciseLibraryScreen extends ConsumerStatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  ConsumerState<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends ConsumerState<ExerciseLibraryScreen> {
  String _search = '';
  String? _muscleFilter;

  static const _muscleGroups = [
    'Brust', 'Rücken', 'Schulter', 'Bizeps', 'Trizeps',
    'Bauch', 'Beine', 'Gesäß', 'Waden', 'Ganzkörper',
  ];

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(AppLocalizations.of(context)!.exerciseLibrary,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: TraumColors.coralOrange,
        onPressed: () => _showAddExerciseSheet(context),
        child: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: TextField(
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              decoration: InputDecoration(
                hintText: AppLocalizations.of(context)!.search,
                hintStyle: const TextStyle(
                    color: TraumColors.onBackgroundSubtle, fontFamily: 'DMSans'),
                prefixIcon: const Icon(Icons.search_rounded,
                    color: TraumColors.onBackgroundMuted),
                filled: true,
                fillColor: TraumColors.surface,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(TraumRadius.card),
                    borderSide: BorderSide.none),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              onChanged: (v) => setState(() => _search = v),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _MuscleChip(
                    label: AppLocalizations.of(context)!.all, selected: _muscleFilter == null,
                    onTap: () => setState(() => _muscleFilter = null)),
                ..._muscleGroups.map((m) => _MuscleChip(
                      label: _muscleLabel(m, AppLocalizations.of(context)!),
                      selected: _muscleFilter == m,
                      onTap: () => setState(
                          () => _muscleFilter = _muscleFilter == m ? null : m),
                    )),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: exercisesAsync.when(
              data: (exercises) {
                var filtered = exercises.where((e) {
                  if (_search.isNotEmpty &&
                      !e.name.toLowerCase().contains(_search.toLowerCase())) {
                    return false;
                  }
                  if (_muscleFilter != null && e.muscleGroup != _muscleFilter) {
                    return false;
                  }
                  return true;
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.fitness_center_rounded,
                          size: 48, color: TraumColors.onBackgroundSubtle),
                      const SizedBox(height: 12),
                      Text(exercises.isEmpty ? AppLocalizations.of(context)!.noExercisesYet : AppLocalizations.of(context)!.noResults,
                          style: const TextStyle(
                              color: TraumColors.onBackgroundMuted,
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w600)),
                    ]),
                  );
                }

                final grouped = <String, List<Exercise>>{};
                for (final e in filtered) {
                  grouped.putIfAbsent(e.muscleGroup, () => []).add(e);
                }

                return ListView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  children: grouped.entries.map((entry) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 12, bottom: 6),
                        child: Text(_muscleLabel(entry.key, AppLocalizations.of(context)!),
                            style: const TextStyle(
                                color: TraumColors.coralOrange,
                                fontFamily: 'DMSans',
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                      ...entry.value.map((ex) => _ExerciseTile(
                            exercise: ex,
                            onTap: () => context.go('/training/exercise/${ex.id}/progress'),
                            onDelete: ex.isCustom
                                ? () => ref.read(trainingDaoProvider).deleteExercise(ex.id)
                                : null,
                          )),
                    ],
                  )).toList(),
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

  void _showAddExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(TraumRadius.card)),
      ),
      builder: (ctx) => _AddExerciseSheet(
        onAdd: (c) => ref.read(trainingDaoProvider).insertExercise(c),
      ),
    );
  }
}

class _MuscleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MuscleChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? TraumColors.coralDim : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: selected ? TraumColors.coralOrange : Colors.transparent),
          ),
          child: Text(label,
              style: TextStyle(
                  color: selected
                      ? TraumColors.coralOrange
                      : TraumColors.onBackgroundMuted,
                  fontFamily: 'DMSans',
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  fontSize: 12)),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final Exercise exercise;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ExerciseTile(
      {required this.exercise, required this.onTap, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(TraumRadius.card),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          width: 40, height: 40,
          decoration: const BoxDecoration(
              color: TraumColors.coralDim, shape: BoxShape.circle),
          child: const Icon(Icons.fitness_center_rounded,
              color: TraumColors.coralOrange, size: 18),
        ),
        title: Text(exercise.name,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600)),
        subtitle: Text(
          [
            exercise.muscleGroup,
            if (exercise.equipment != null) exercise.equipment!,
          ].join('  •  '),
          style: const TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontSize: 11),
        ),
        trailing: onDelete != null
            ? IconButton(
                icon: const Icon(Icons.delete_rounded,
                    color: TraumColors.onBackgroundSubtle, size: 18),
                onPressed: onDelete,
              )
            : const Icon(Icons.chevron_right_rounded,
                color: TraumColors.onBackgroundSubtle),
      ),
    );
  }
}

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
  String _muscleGroup = 'Brust';
  bool _saving = false;

  static const _muscleGroups = [
    'Brust', 'Rücken', 'Schulter', 'Bizeps', 'Trizeps',
    'Bauch', 'Beine', 'Gesäß', 'Waden', 'Ganzkörper',
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
                      borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            Text(AppLocalizations.of(context)!.createExercise,
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18)),
            const SizedBox(height: 16),
            _buildField(AppLocalizations.of(context)!.fieldName, _nameCtrl, hint: AppLocalizations.of(context)!.exerciseHint),
            const SizedBox(height: 12),
            Text(AppLocalizations.of(context)!.muscleGroup,
                style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 13)),
            const SizedBox(height: 6),
            DropdownButton<String>(
              value: _muscleGroup,
              dropdownColor: TraumColors.surfaceElevated,
              isExpanded: true,
              style: const TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
              underline: Container(height: 1, color: TraumColors.surfaceVariant),
              items: _muscleGroups
                  .map((m) => DropdownMenuItem(value: m, child: Text(_muscleLabel(m, AppLocalizations.of(context)!))))
                  .toList(),
              onChanged: (v) => setState(() => _muscleGroup = v!),
            ),
            const SizedBox(height: 12),
            _buildField(AppLocalizations.of(context)!.equipmentOptional, _equipCtrl, hint: AppLocalizations.of(context)!.equipmentHint),
            const SizedBox(height: 12),
            _buildField(AppLocalizations.of(context)!.instructionsOptional, _instrCtrl, hint: AppLocalizations.of(context)!.instructionExecution, lines: 3),
            const SizedBox(height: 20),
            GradientButton(
              label: _saving ? AppLocalizations.of(context)!.saving : AppLocalizations.of(context)!.createExercise,
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
              borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    ]);
  }

  Future<void> _save() async {
    if (_nameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(AppLocalizations.of(context)!.nameRequired)));
      return;
    }
    setState(() => _saving = true);
    await widget.onAdd(ExercisesCompanion.insert(
      name: _nameCtrl.text.trim(),
      muscleGroup: _muscleGroup,
      equipment: Value(
          _equipCtrl.text.trim().isEmpty ? null : _equipCtrl.text.trim()),
      instructions: Value(
          _instrCtrl.text.trim().isEmpty ? null : _instrCtrl.text.trim()),
      isCustom: const Value(true),
    ));
    if (mounted) Navigator.pop(context);
  }
}
