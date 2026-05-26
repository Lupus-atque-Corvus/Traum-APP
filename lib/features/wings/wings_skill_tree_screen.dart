import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
import 'wings_data.dart';

class WingsSkillTreeScreen extends StatelessWidget {
  const WingsSkillTreeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: wingsSkillCategories.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (ctx, i) =>
          _SkillCategoryCard(category: wingsSkillCategories[i]),
    );
  }
}

class _SkillCategoryCard extends StatefulWidget {
  final WingsSkillCategory category;

  const _SkillCategoryCard({required this.category});

  @override
  State<_SkillCategoryCard> createState() => _SkillCategoryCardState();
}

class _SkillCategoryCardState extends State<_SkillCategoryCard> {
  bool _expanded = false;
  int? _selectedRow;
  String? _selectedExerciseName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Container(
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _expanded ? TraumColors.cyanBlue.withAlpha(80) : Colors.transparent,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => setState(() {
              _expanded = !_expanded;
              if (!_expanded) {
                _selectedRow = null;
                _selectedExerciseName = null;
              }
            }),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: TraumColors.cyanDim,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      categoryIcon(widget.category.category),
                      color: TraumColors.cyanBlue,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.category.titleEn.toUpperCase(),
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground,
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          '${widget.category.rows.fold(0, (sum, row) => sum + row.names.length)} ${l10n.wingsExercisesCount}',
                          style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _expanded ? Icons.expand_less : Icons.expand_more,
                    color: TraumColors.onBackgroundMuted,
                  ),
                ],
              ),
            ),
          ),

          // Category blurb + skill rows
          if (_expanded) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                widget.category.blurb,
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackgroundMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 12),

            ...widget.category.rows.asMap().entries.map((rowEntry) {
              final rowIndex = rowEntry.key;
              final row = rowEntry.value;
              final isRowSelected = _selectedRow == rowIndex;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: Text(
                      'Level ${rowIndex + 1}',
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundSubtle,
                        fontSize: 11,
                        letterSpacing: 1,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: row.names.map((name) {
                        final exercise = findExerciseByName(name);
                        final isSelected =
                            isRowSelected && _selectedExerciseName == name;
                        final hasDetail = exercise != null;
                        final diffColor = exercise != null
                            ? difficultyColor(exercise.difficulty)
                            : TraumColors.onBackgroundSubtle;

                        return Padding(
                          padding: const EdgeInsets.only(right: 8, bottom: 8),
                          child: GestureDetector(
                            onTap: () {
                              if (isSelected) {
                                setState(() {
                                  _selectedRow = null;
                                  _selectedExerciseName = null;
                                });
                              } else {
                                setState(() {
                                  _selectedRow = rowIndex;
                                  _selectedExerciseName = name;
                                });
                              }
                            },
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? diffColor.withAlpha(40)
                                    : TraumColors.surfaceVariant,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: isSelected
                                      ? diffColor
                                      : Colors.transparent,
                                  width: 1.5,
                                ),
                              ),
                              child: Text(
                                name,
                                style: TextStyle(
                                  fontFamily: 'DMSans',
                                  color: isSelected
                                      ? diffColor
                                      : hasDetail
                                          ? TraumColors.onBackground
                                          : TraumColors.onBackgroundMuted,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),

                  // Expanded exercise detail inline
                  if (isRowSelected && _selectedExerciseName != null)
                    _InlineExerciseDetail(
                      name: _selectedExerciseName!,
                      exercise: findExerciseByName(_selectedExerciseName!),
                      l10n: l10n,
                    ),
                ],
              );
            }),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _InlineExerciseDetail extends StatelessWidget {
  final String name;
  final WingsExercise? exercise;
  final AppLocalizations l10n;

  const _InlineExerciseDetail({
    required this.name,
    required this.exercise,
    required this.l10n,
  });

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: TraumColors.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            const Icon(Icons.construction, color: TraumColors.onBackgroundMuted, size: 18),
            const SizedBox(width: 8),
            Text(
              '$name — ${l10n.wingsInProgress}',
              style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontStyle: FontStyle.italic,
                fontSize: 13,
              ),
            ),
          ],
        ),
      );
    }

    final diffColor = difficultyColor(exercise!.difficulty);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: TraumColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: diffColor.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title + difficulty
          Row(
            children: [
              Expanded(
                child: Text(
                  exercise!.name,
                  style: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: diffColor.withAlpha(30),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  difficultyLabel(exercise!.difficulty),
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
          const SizedBox(height: 6),

          // Muscles
          Text(
            exercise!.muscles,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.cyanBlue,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),

          // Description
          Text(
            exercise!.description,
            style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackgroundMuted,
              fontSize: 13,
              height: 1.5,
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),

          // Open detail button
          Align(
            alignment: Alignment.centerRight,
            child: GestureDetector(
              onTap: () => context.go(Routes.wingsExercisePath(exercise!.id)),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: TraumColors.cyanDim,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.wingsViewTutorial,
                      style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.cyanBlue,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward, color: TraumColors.cyanBlue, size: 14),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
