import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'wings_data.dart';

class WingsTutorialsScreen extends StatefulWidget {
  const WingsTutorialsScreen({super.key});

  @override
  State<WingsTutorialsScreen> createState() => _WingsTutorialsScreenState();
}

class _WingsTutorialsScreenState extends State<WingsTutorialsScreen> {
  String _query = '';
  WingsCategory? _selectedCategory;

  List<WingsExercise> get _filtered {
    return wingsExercises.where((ex) {
      final matchesQuery = _query.isEmpty ||
          ex.name.toLowerCase().contains(_query.toLowerCase()) ||
          ex.muscles.toLowerCase().contains(_query.toLowerCase());
      final matchesCategory =
          _selectedCategory == null || ex.category == _selectedCategory;
      return matchesQuery && matchesCategory;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final filtered = _filtered;

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: TextField(
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackground,
            ),
            decoration: InputDecoration(
              hintText: l10n.wingsSearchExercises,
              hintStyle: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
              ),
              prefixIcon: const Icon(Icons.search, color: TraumColors.onBackgroundMuted),
              filled: true,
              fillColor: TraumColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onChanged: (v) => setState(() => _query = v),
          ),
        ),

        // Category filter chips
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            children: [
              _FilterChip(
                label: l10n.wingsAll,
                selected: _selectedCategory == null,
                onTap: () => setState(() => _selectedCategory = null),
              ),
              ...WingsCategory.values.map((cat) => _FilterChip(
                    label: categoryLabel(cat),
                    selected: _selectedCategory == cat,
                    onTap: () => setState(() =>
                        _selectedCategory = _selectedCategory == cat ? null : cat),
                  )),
            ],
          ),
        ),

        // Exercise list
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.wingsNoExercisesFound,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: filtered.length,
                  itemBuilder: (ctx, i) {
                    final ex = filtered[i];
                    return _ExerciseTile(exercise: ex);
                  },
                ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: selected ? TraumColors.cyanDim : TraumColors.surfaceVariant,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: selected ? TraumColors.cyanBlue : Colors.transparent,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'DMSans',
              color: selected ? TraumColors.cyanBlue : TraumColors.onBackgroundMuted,
              fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  final WingsExercise exercise;

  const _ExerciseTile({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final diffColor = difficultyColor(exercise.difficulty);

    return GestureDetector(
      onTap: () => context.go(Routes.wingsExercisePath(exercise.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            // Category icon
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: diffColor.withAlpha(30),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(categoryIcon(exercise.category), color: diffColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    exercise.name,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    exercise.muscles,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: diffColor.withAlpha(30),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                difficultyLabel(exercise.difficulty),
                style: TextStyle(
                  fontFamily: 'DMSans',
                  color: diffColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
