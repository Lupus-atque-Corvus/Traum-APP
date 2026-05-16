import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/components/components.dart';
import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        title: const Text('Training'),
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
        label: const Text(
          'Routine erstellen',
          style: TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600),
        ),
        icon: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Wochentag-Leiste
                _WeekDayStrip(),
                const SizedBox(height: 12),

                // Heutiges Workout
                _TodayWorkoutCard(
                  onStart: () => context.push(Routes.activeWorkout),
                ),
                const SizedBox(height: 12),

                // Wöchentlicher Fortschritt
                _WeeklyProgressCard(),
                const SizedBox(height: 12),

                // Muskelgruppen-Übersicht
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Muskelgruppen Übersicht',
                        actionLabel: 'Mehr ›',
                        onAction: () => context.push(Routes.muscleHeatmap),
                      ),
                      const SizedBox(height: 12),
                      const Center(
                        child: Text(
                          'Noch keine Trainingseinheiten aufgezeichnet.',
                          style: TextStyle(
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

                // Routinen
                TraumCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SectionHeader(
                        title: 'Meine Routinen',
                        actionLabel: 'Alle ›',
                        onAction: () => context.push(Routes.routines),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Noch keine Routinen erstellt.',
                        style: TextStyle(
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
  final _days = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];

  @override
  Widget build(BuildContext context) {
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
                    _days[i],
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
                const Text(
                  'Kein Workout geplant',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                  ),
                ),
                const SizedBox(height: 8),
                GradientButton(
                  label: 'Workout starten',
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
    return TraumCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionHeader(title: 'Wöchentlicher Fortschritt'),
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
