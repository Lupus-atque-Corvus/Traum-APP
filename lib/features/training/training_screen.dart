import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        title: Text(l10n.training),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month_outlined),
            onPressed: () {},
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(Routes.routines),
        backgroundColor: TraumColors.coralOrange,
        label: Text(
          l10n.createRoutine,
          style: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _WeekDayStrip(),
                const SizedBox(height: 12),
                _TodayWorkoutCard(
                  onStart: () => context.push(Routes.activeWorkout),
                ),
                const SizedBox(height: 12),
                _WeeklyProgressCard(),
                const SizedBox(height: 12),
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: l10n.muscleGroupsOverview,
                        actionLabel: '${l10n.moreLabel} ›',
                        onAction: () => context.push(Routes.muscleHeatmap),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: Text(
                          l10n.noTrainingSessionsRecorded,
                          style: const TextStyle(
                            fontSize: 13,
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: l10n.myRoutines,
                        actionLabel: '${l10n.all} ›',
                        onAction: () => context.push(Routes.routines),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.noRoutinesCreated,
                        style: const TextStyle(
                          fontSize: 13,
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeekDayStrip extends StatefulWidget {
  @override
  State<_WeekDayStrip> createState() => _WeekDayStripState();
}

class _WeekDayStripState extends State<_WeekDayStrip> {
  int _selected = DateTime.now().weekday - 1;

  @override
  Widget build(BuildContext context) {
    final days = AppLocalizations.of(context)!.weekdaysShort.split(',');
    final today = DateTime.now().weekday - 1;
    return SizedBox(
      height: 56,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        itemBuilder: (_, i) {
          final now = DateTime.now();
          final dayDate = now.subtract(Duration(days: now.weekday - 1 - i));
          final isToday = i == today;
          final isPast = i < today;
          final isSelected = i == _selected;

          return GestureDetector(
            onTap: () => setState(() => _selected = i),
            child: Container(
              width: 44,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                color: isSelected ? TraumColors.coralDim : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      fontSize: 11,
                      color: isPast
                          ? TraumColors.onBackgroundSubtle
                          : TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: isToday ? TraumColors.coralOrange : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        '${dayDate.day}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isToday
                              ? Colors.white
                              : isPast
                                  ? TraumColors.onBackgroundSubtle
                                  : TraumColors.onBackground,
                          fontFamily: 'DMSans',
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TodayWorkoutCard extends StatelessWidget {
  final VoidCallback onStart;
  const _TodayWorkoutCard({required this.onStart});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TraumCard(
      borderColor: TraumColors.coralOrange,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  TraumColors.coralOrange.withValues(alpha: 0.3),
                  TraumColors.background,
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: const Center(
              child: Icon(
                Icons.fitness_center,
                color: TraumColors.coralOrange,
                size: 48,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.noWorkoutPlanned,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: l10n.startWorkout,
                  onPressed: onStart,
                  icon: const Icon(Icons.play_arrow_rounded,
                      color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyProgressCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(title: l10n.weeklyProgress),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatItem(icon: '🏋', label: '0 Workouts'),
              _StatItem(icon: '🔥', label: '0 kcal'),
              _StatItem(icon: '⏱', label: '0:00 Std.'),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String icon, label;
  const _StatItem({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}
