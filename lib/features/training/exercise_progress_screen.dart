import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/providers/database_provider.dart';
import '../../core/providers/unit_preference_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../settings/feedback/feedback_bottom_sheet.dart';
import 'widgets/body_map_widget.dart';

// ── Helpers ───────────────────────────────────────────────────────────────────
String _mgDisplay(String key) {
  switch (key.toLowerCase()) {
    case 'chest':     return 'Pectorals';
    case 'back':      return 'Lats';
    case 'shoulders': return 'Deltoids';
    case 'biceps':    return 'Biceps';
    case 'triceps':   return 'Triceps';
    case 'core':      return 'Abdominals';
    case 'legs':      return 'Quadriceps, Glutes';
    case 'cardio':    return 'Cardio';
    case 'full_body': return 'Full Body';
    default:          return key;
  }
}

bool _isCardio(String muscleGroup) => muscleGroup.toLowerCase() == 'cardio';

// Time range options
enum _Range { m1, m3, m6, y1, all }

extension _RangeExt on _Range {
  String get label => switch (this) {
    _Range.m1  => '1M',
    _Range.m3  => '3M',
    _Range.m6  => '6M',
    _Range.y1  => '1Y',
    _Range.all => 'ALL',
  };
  DateTime? get cutoff {
    final now = DateTime.now();
    return switch (this) {
      _Range.m1  => now.subtract(const Duration(days: 30)),
      _Range.m3  => now.subtract(const Duration(days: 90)),
      _Range.m6  => now.subtract(const Duration(days: 180)),
      _Range.y1  => now.subtract(const Duration(days: 365)),
      _Range.all => null,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class ExerciseProgressScreen extends ConsumerStatefulWidget {
  final int exerciseId;
  const ExerciseProgressScreen({super.key, required this.exerciseId});

  @override
  ConsumerState<ExerciseProgressScreen> createState() =>
      _ExerciseProgressScreenState();
}

class _ExerciseProgressScreenState
    extends ConsumerState<ExerciseProgressScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  _Range _range = _Range.m1;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _showExerciseOptions(BuildContext context, Exercise? ex) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (ex != null)
            ListTile(
              leading: Icon(
                ex.isBookmarked
                    ? Icons.bookmark_rounded
                    : Icons.bookmark_border_rounded,
                color: TraumColors.amberGold,
              ),
              title: Text(
                ex.isBookmarked ? 'Lesezeichen entfernen' : 'Als Lesezeichen',
                style: const TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans'),
              ),
              onTap: () {
                ref
                    .read(trainingDaoProvider)
                    .setBookmarked(ex.id, !ex.isBookmarked);
                Navigator.pop(context);
              },
            ),
          ListTile(
            leading:
                const Icon(Icons.feedback_outlined, color: TraumColors.cyanBlue),
            title: const Text('Feedback zu dieser Übung',
                style: TextStyle(
                    color: TraumColors.onBackground, fontFamily: 'DMSans')),
            onTap: () {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                builder: (_) => const FeedbackBottomSheet(),
              );
            },
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final exercisesAsync = ref.watch(allExercisesStreamProvider);
    final historyAsync = ref.watch(exerciseSessionHistoryProvider(widget.exerciseId));

    return exercisesAsync.when(
      data: (exercises) {
        final ex = exercises.cast<Exercise?>()
            .firstWhere((e) => e?.id == widget.exerciseId, orElse: () => null);

        return Scaffold(
          backgroundColor: TraumColors.background,
          appBar: AppBar(
            backgroundColor: TraumColors.background,
            elevation: 0,
            iconTheme: const IconThemeData(color: TraumColors.onBackground),
            title: Text(
              ex?.name ?? 'Exercise',
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700,
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, color: TraumColors.onBackground),
                onPressed: () => _showExerciseOptions(context, ex),
              ),
            ],
            bottom: TabBar(
              controller: _tabs,
              labelColor: TraumColors.onBackground,
              unselectedLabelColor: TraumColors.onBackgroundSubtle,
              indicatorColor: TraumColors.onBackground,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: const TextStyle(fontFamily: 'DMSans', fontWeight: FontWeight.w600, fontSize: 13),
              tabs: const [
                Tab(icon: Icon(Icons.info_outline_rounded, size: 18), text: 'Info'),
                Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Statistics'),
                Tab(icon: Icon(Icons.history_rounded, size: 18), text: 'History'),
              ],
            ),
          ),
          body: TabBarView(
            controller: _tabs,
            children: [
              // ── Tab 1: Info ─────────────────────────────────────────────
              _InfoTab(exercise: ex, exercises: exercises),

              // ── Tab 2: Statistics ───────────────────────────────────────
              historyAsync.when(
                data: (history) => _StatisticsTab(
                  exercise: ex,
                  history: history,
                  range: _range,
                  onRangeChanged: (r) => setState(() => _range = r),
                ),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: TraumColors.coralOrange)),
                error: (e, _) => Center(child: Text('$e')),
              ),

              // ── Tab 3: History ──────────────────────────────────────────
              historyAsync.when(
                data: (history) => _HistoryTab(exercise: ex, history: history),
                loading: () => const Center(
                    child: CircularProgressIndicator(color: TraumColors.coralOrange)),
                error: (e, _) => Center(child: Text('$e')),
              ),
            ],
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(child: CircularProgressIndicator(color: TraumColors.coralOrange)),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: TraumColors.background,
        body: Center(child: Text('$e')),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Info Tab
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTab extends StatelessWidget {
  final Exercise? exercise;
  final List<Exercise> exercises;
  const _InfoTab({required this.exercise, required this.exercises});

  @override
  Widget build(BuildContext context) {
    if (exercise == null) {
      return const Center(
        child: Text('Exercise not found',
            style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans')),
      );
    }
    final ex = exercise!;
    final muscles = BodyMapWidget.musclesForGroup(ex.muscleGroup);
    final similar = exercises
        .where((e) => e.id != ex.id && e.muscleGroup == ex.muscleGroup)
        .take(5)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Muscle map card ──────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + category badge
              Text(ex.name,
                  style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  )),
              const SizedBox(height: 8),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: TraumColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _mgDisplay(ex.muscleGroup),
                    style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.access_time_rounded,
                    color: TraumColors.onBackgroundSubtle, size: 16),
                const SizedBox(width: 8),
                const Icon(Icons.person_outline_rounded,
                    color: TraumColors.onBackgroundSubtle, size: 16),
              ]),
              const SizedBox(height: 16),
              // Front + Back body map side by side
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  SizedBox(
                    height: 180,
                    child: BodyMapWidget(
                      primaryMuscles: muscles,
                      secondaryMuscles: const [],
                      height: 180,
                    ),
                  ),
                  SizedBox(
                    height: 180,
                    child: BodyMapWidget(
                      primaryMuscles: muscles,
                      secondaryMuscles: const [],
                      showBack: true,
                      height: 180,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Instructions (if any)
        if (ex.instructions != null && ex.instructions!.isNotEmpty) ...[
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Text(
              ex.instructions!,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        // Suggestion link → opens the feedback sheet
        TextButton(
          onPressed: () => showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const FeedbackBottomSheet(),
          ),
          child: const Text(
            'Hast du Tipps zu dieser Übung?',
            style: TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 13,
              decoration: TextDecoration.underline,
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Similar exercises
        if (similar.isNotEmpty) ...[
          const Text(
            'Similar Exercises',
            style: TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 8),
          ...similar.map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Icon(Icons.fitness_center_rounded,
                      color: TraumColors.onBackgroundMuted, size: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.name,
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontWeight: FontWeight.w600,
                        )),
                    Text(_mgDisplay(s.muscleGroup).toUpperCase(),
                        style: const TextStyle(
                          color: TraumColors.coralOrange,
                          fontFamily: 'DMSans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.4,
                        )),
                  ],
                ),
              ),
            ]),
          )),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Statistics Tab
// ─────────────────────────────────────────────────────────────────────────────
class _StatisticsTab extends StatelessWidget {
  final Exercise? exercise;
  final List<(WorkoutSession, List<WorkoutSet>)> history;
  final _Range range;
  final void Function(_Range) onRangeChanged;
  const _StatisticsTab({
    required this.exercise,
    required this.history,
    required this.range,
    required this.onRangeChanged,
  });

  List<(WorkoutSession, List<WorkoutSet>)> get _filtered {
    final cutoff = range.cutoff;
    if (cutoff == null) return history;
    return history.where((h) => h.$1.startedAt.isAfter(cutoff)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final cardio = exercise != null && _isCardio(exercise!.muscleGroup);

    // Aggregate stats
    final totalSets = filtered.fold(0, (s, h) => s + h.$2.length);
    Duration totalDuration = Duration.zero;
    for (final (session, _) in filtered) {
      if (session.durationSeconds != null) {
        totalDuration += Duration(seconds: session.durationSeconds!);
      }
    }
    final totalVolume = filtered.fold(0.0, (sum, h) {
      for (final s in h.$2) {
        sum += (s.weightKg ?? 0) * (s.reps ?? 0);
      }
      return sum;
    });

    if (filtered.isEmpty) {
      return _emptyState();
    }

    // Build chart points (max weight or volume per session)
    final chartPoints = <FlSpot>[];
    for (int i = 0; i < filtered.length; i++) {
      final sets = filtered[i].$2;
      double val = 0;
      for (final s in sets) {
        if (cardio) {
          val = (s.weightKg ?? 0) > val ? (s.weightKg ?? 0) : val;
        } else {
          final v = (s.weightKg ?? 0) * (s.reps ?? 0);
          if (v > val) val = v;
        }
      }
      chartPoints.add(FlSpot(i.toDouble(), val));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Training volume card ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Training volume',
                  style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  )),
              const SizedBox(height: 12),
              _StatRow(label: 'Times performed', value: '$totalSets'),
              _StatRow(
                label: 'Total duration',
                value: '${totalDuration.inHours > 0 ? '${totalDuration.inHours} h ' : ''}${totalDuration.inMinutes % 60} min',
              ),
              if (!cardio)
                _StatRow(
                  label: 'Total volume',
                  value: '${totalVolume.toStringAsFixed(0)} kg',
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // ── Time range selector ──────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: TraumColors.surface,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
          padding: const EdgeInsets.all(4),
          child: Row(
            children: _Range.values.map((r) {
              final active = r == range;
              return Expanded(
                child: GestureDetector(
                  onTap: () => onRangeChanged(r),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: active ? TraumColors.surfaceVariant : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      r.label,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: active ? TraumColors.onBackground : TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 12),

        // ── Max weight / volume chart ────────────────────────────────────
        if (chartPoints.length > 1) ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      cardio ? 'Distance' : 'Volume',
                      style: const TextStyle(
                        color: TraumColors.onBackground,
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    const Icon(Icons.ios_share_rounded,
                        color: TraumColors.onBackgroundSubtle, size: 16),
                  ],
                ),
                const SizedBox(height: 4),
                if (filtered.isNotEmpty) ...[
                  _ChartStats(
                    mostRecent: chartPoints.last.y,
                    maximum: chartPoints.map((p) => p.y).reduce((a, b) => a > b ? a : b),
                    average: chartPoints.map((p) => p.y).fold(0.0, (a, b) => a + b) / chartPoints.length,
                    unit: cardio ? 'km' : 'kg',
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  height: 120,
                  child: LineChart(
                    LineChartData(
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => const FlLine(
                          color: Color(0xFF2A2D3E),
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: FlTitlesData(
                        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 36,
                            getTitlesWidget: (v, _) => Text(
                              v.toStringAsFixed(1),
                              style: const TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontFamily: 'DMSans',
                                fontSize: 9,
                              ),
                            ),
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 20,
                            getTitlesWidget: (v, _) {
                              final i = v.toInt();
                              if (i >= filtered.length) return const SizedBox.shrink();
                              final d = filtered[i].$1.startedAt;
                              return Text(
                                '${_monthAbbr(d.month)}${d.day}',
                                style: const TextStyle(
                                  color: TraumColors.onBackgroundSubtle,
                                  fontFamily: 'DMSans',
                                  fontSize: 9,
                                ),
                              );
                            },
                          ),
                        ),
                        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: chartPoints,
                          isCurved: true,
                          color: TraumColors.coralOrange,
                          barWidth: 2,
                          dotData: const FlDotData(show: false),
                          belowBarData: BarAreaData(
                            show: true,
                            color: TraumColors.coralOrange.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _emptyState() {
    return const Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.show_chart_rounded, size: 48, color: TraumColors.onBackgroundSubtle),
        SizedBox(height: 12),
        Text('No data yet',
            style: TextStyle(
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
            )),
        SizedBox(height: 4),
        Text('Train this exercise to see your progress',
            style: TextStyle(
              color: TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 12,
            )),
      ]),
    );
  }
}

String _monthAbbr(int month) {
  const abbrs = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return abbrs[month];
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;
  const _StatRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontSize: 13,
              )),
          Text(value,
              style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
                fontSize: 13,
              )),
        ],
      ),
    );
  }
}

class _ChartStats extends StatelessWidget {
  final double mostRecent;
  final double maximum;
  final double average;
  final String unit;
  const _ChartStats({
    required this.mostRecent,
    required this.maximum,
    required this.average,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _MiniStat(label: 'Most recent', value: '${mostRecent.toStringAsFixed(1)} $unit',
            icon: Icons.access_time_rounded),
        _MiniStat(label: 'Maximum', value: '${maximum.toStringAsFixed(1)} $unit',
            icon: Icons.trending_up_rounded),
        _MiniStat(label: 'Average', value: '${average.toStringAsFixed(1)} $unit',
            icon: Icons.bar_chart_rounded),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  const _MiniStat({required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: const TextStyle(
            color: TraumColors.onBackgroundSubtle,
            fontFamily: 'DMSans',
            fontSize: 11,
          )),
      Row(children: [
        Text(value,
            style: const TextStyle(
              color: TraumColors.onBackground,
              fontFamily: 'DMSans',
              fontWeight: FontWeight.w600,
              fontSize: 13,
            )),
        const SizedBox(width: 4),
        Icon(icon, color: TraumColors.onBackgroundSubtle, size: 12),
      ]),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// History Tab
// ─────────────────────────────────────────────────────────────────────────────
class _HistoryTab extends ConsumerWidget {
  final Exercise? exercise;
  final List<(WorkoutSession, List<WorkoutSet>)> history;
  const _HistoryTab({required this.exercise, required this.history});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (history.isEmpty) {
      return const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.history_rounded, size: 48, color: TraumColors.onBackgroundSubtle),
          SizedBox(height: 12),
          Text('No history yet',
              style: TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w600,
              )),
        ]),
      );
    }

    final useLbs = ref.watch(unitPreferenceProvider);
    final cardio = exercise != null && _isCardio(exercise!.muscleGroup);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: history.length,
      itemBuilder: (_, i) {
        final (session, sets) = history[i];
        final prevSets = i + 1 < history.length ? history[i + 1].$2 : null;

        // Format date
        final d = session.startedAt;
        final dateStr = '${_monthAbbr(d.month)} ${d.day}, ${d.year}';

        // Compute totals for Σ row
        final totalReps = sets.fold(0, (s, set) => s + (set.reps ?? 0));
        final totalVol = sets.fold(0.0, (s, set) => s + (set.weightKg ?? 0) * (set.reps ?? 0));
        final prevVol = prevSets?.fold(0.0, (s, set) => s + (set.weightKg ?? 0) * (set.reps ?? 0));

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              // Set rows
              ...sets.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(children: [
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${s.setNumber}',
                      style: const TextStyle(
                        color: TraumColors.onBackgroundSubtle,
                        fontFamily: 'DMSans',
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (!cardio) ...[
                    Expanded(
                      child: Text(
                        s.reps != null ? '${s.reps} reps' : '-',
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.weightKg != null
                            ? '${s.weightKg!.toDisplayUnit(useLbs).toStringAsFixed(1)} ${s.weightKg!.unitLabel(useLbs)}'
                            : '-',
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ] else ...[
                    Expanded(
                      child: Text(
                        s.durationSeconds != null
                            ? _fmtDuration(s.durationSeconds!)
                            : '-',
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        s.weightKg != null ? '${s.weightKg!.toStringAsFixed(1)} km' : '-',
                        style: const TextStyle(
                          color: TraumColors.onBackground,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ]),
              )),
              // Σ summary row with trend
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(vertical: 6),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: TraumColors.surfaceVariant)),
                ),
                child: Row(children: [
                  const SizedBox(
                    width: 24,
                    child: Text('Σ',
                        style: TextStyle(
                          color: TraumColors.onBackgroundSubtle,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        )),
                  ),
                  const SizedBox(width: 8),
                  if (!cardio) ...[
                    Expanded(
                      child: Text(
                        '$totalReps reps',
                        style: const TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 12,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(children: [
                        Text(
                          '${totalVol.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            color: TraumColors.onBackgroundMuted,
                            fontFamily: 'DMSans',
                            fontSize: 12,
                          ),
                        ),
                        if (prevVol != null) ...[
                          const SizedBox(width: 4),
                          _TrendArrow(current: totalVol, previous: prevVol),
                        ],
                      ]),
                    ),
                  ],
                ]),
              ),
            ],
          ),
        );
      },
    );
  }

  String _fmtDuration(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class _TrendArrow extends StatelessWidget {
  final double current;
  final double previous;
  const _TrendArrow({required this.current, required this.previous});

  @override
  Widget build(BuildContext context) {
    if (current == previous) return const SizedBox.shrink();
    final up = current > previous;
    return Icon(
      up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
      color: up ? const Color(0xFF4CAF50) : TraumColors.coralOrange,
      size: 14,
    );
  }
}
