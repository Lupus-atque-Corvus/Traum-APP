import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/components/components.dart';
import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart' show WeightLog;
import '../../health/health_score_provider.dart';
import '../../health/health_score_result.dart';
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

/// One-shot weight log list for the home widgets. Uses a plain query (not the
/// drift `.watch()` stream) so no query-stream close timer lingers in tests.
final _weightLogsSnapshotProvider =
    FutureProvider.autoDispose<List<WeightLog>>((ref) {
  return ref.watch(healthDaoProvider).getAllWeightLogs();
});

final Map<HomeWidgetType, HomeWidgetDescriptor> healthHomeWidgets = {
  HomeWidgetType.steps: HomeWidgetDescriptor(
    title: 'Schritte',
    group: HomeWidgetGroup.health,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small, HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Schritte',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.health,
      child: _StepsContent(size: size),
    ),
  ),
  HomeWidgetType.sleep: HomeWidgetDescriptor(
    title: 'Schlaf',
    group: HomeWidgetGroup.health,
    accent: TraumColors.lavender,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Schlaf',
      accent: TraumColors.lavender,
      size: size,
      route: Routes.health,
      child: const _SleepContent(),
    ),
  ),
  HomeWidgetType.heartRate: HomeWidgetDescriptor(
    title: 'Herzfrequenz',
    group: HomeWidgetGroup.health,
    accent: TraumColors.roseRed,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Herzfrequenz',
      accent: TraumColors.roseRed,
      size: size,
      route: Routes.health,
      child: const _MetricValue(
        value: '—',
        unit: 'bpm',
        color: TraumColors.roseRed,
      ),
    ),
  ),
  HomeWidgetType.moodToday: HomeWidgetDescriptor(
    title: 'Stimmung',
    group: HomeWidgetGroup.health,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Stimmung',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.health,
      child: const _MoodContent(),
    ),
  ),
  HomeWidgetType.weightTrend: HomeWidgetDescriptor(
    title: 'Gewicht',
    group: HomeWidgetGroup.health,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.small, HomeTileSize.wide},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Gewicht',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.health,
      child: const _WeightTrendContent(),
    ),
  ),
  HomeWidgetType.healthScore: HomeWidgetDescriptor(
    title: 'Score',
    group: HomeWidgetGroup.health,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.small, HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Score',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.health,
      child: _HealthScoreContent(size: size),
    ),
  ),
  HomeWidgetType.healthSnapshot: HomeWidgetDescriptor(
    title: 'Gesundheit',
    group: HomeWidgetGroup.health,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Gesundheit',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.health,
      child: const _HealthSnapshotContent(),
    ),
  ),
  HomeWidgetType.activeMinutes: HomeWidgetDescriptor(
    title: 'Aktive Min.',
    group: HomeWidgetGroup.health,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Aktive Min.',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.health,
      child: const _MetricValue(
        value: '—',
        unit: 'min',
        color: TraumColors.mintGreen,
      ),
    ),
  ),
  HomeWidgetType.caloriesBurned: HomeWidgetDescriptor(
    title: 'Verbrannt',
    group: HomeWidgetGroup.health,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Verbrannt',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.health,
      child: const _MetricValue(
        value: '—',
        unit: 'kcal',
        color: TraumColors.amberGold,
      ),
    ),
  ),
  HomeWidgetType.stepsWeekChart: HomeWidgetDescriptor(
    title: 'Schritte-Woche',
    group: HomeWidgetGroup.health,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Schritte-Woche',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.health,
      child: const _StepsWeekChartContent(),
    ),
  ),
  HomeWidgetType.weightChart: HomeWidgetDescriptor(
    title: 'Gewichtsverlauf',
    group: HomeWidgetGroup.health,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.health,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Gewichtsverlauf',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.health,
      child: const _WeightChartContent(),
    ),
  ),
};

// ─── Shared empty / value display ──────────────────────────────────────────
class _EmptyDash extends StatelessWidget {
  final double fontSize;
  const _EmptyDash({this.fontSize = 28});

  @override
  Widget build(BuildContext context) {
    return Text(
      '—',
      style: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.w700,
        color: TraumColors.onBackgroundMuted,
        fontFamily: 'DMSans',
      ),
    );
  }
}

class _MetricValue extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _MetricValue({
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isEmpty = value == '—';
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w700,
              color: isEmpty ? TraumColors.onBackgroundMuted : color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: const TextStyle(
            fontSize: 11,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Steps ───────────────────────────────────────────────────────────────
class _StepsContent extends StatelessWidget {
  final HomeTileSize size;
  const _StepsContent({required this.size});

  @override
  Widget build(BuildContext context) {
    // No live step source yet → empty state with unit / goal.
    const goal = 10000;
    if (size == HomeTileSize.large) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressRing(
            value: 0,
            size: 96,
            color: TraumColors.cyanBlue,
            center: const _EmptyDash(fontSize: 26),
          ),
          const SizedBox(height: 8),
          Text(
            'Ziel $goal',
            style: const TextStyle(
              fontSize: 12,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      );
    }
    return const _MetricValue(
      value: '—',
      unit: 'Schritte',
      color: TraumColors.cyanBlue,
    );
  }
}

// ─── Sleep ───────────────────────────────────────────────────────────────
class _SleepContent extends ConsumerWidget {
  const _SleepContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(recentSleepLogsProvider(2)).value;
    String value = '—';
    if (logs != null && logs.isNotEmpty) {
      final latest = logs.reduce((a, b) => a.bedtime.isAfter(b.bedtime) ? a : b);
      final hours = latest.wakeTime.difference(latest.bedtime).inMinutes / 60.0;
      if (hours > 0) value = hours.toStringAsFixed(1);
    }
    return _MetricValue(
      value: value,
      unit: 'h',
      color: TraumColors.lavender,
    );
  }
}

// ─── Mood ────────────────────────────────────────────────────────────────
class _MoodContent extends ConsumerWidget {
  const _MoodContent();

  static const _moodIcons = [
    Icons.sentiment_very_dissatisfied_rounded,
    Icons.sentiment_dissatisfied_rounded,
    Icons.sentiment_neutral_rounded,
    Icons.sentiment_satisfied_rounded,
    Icons.sentiment_very_satisfied_rounded,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mood = ref.watch(latestMoodProvider).value;
    final now = DateTime.now();
    final isToday = mood != null &&
        mood.logDate.year == now.year &&
        mood.logDate.month == now.month &&
        mood.logDate.day == now.day;

    if (!isToday) {
      return const _MetricValue(
        value: '—',
        unit: '/5',
        color: TraumColors.amberGold,
      );
    }

    final score = mood.moodScore.clamp(1, 5);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(_moodIcons[score - 1], color: TraumColors.amberGold, size: 34),
        const SizedBox(height: 4),
        Text(
          '$score/5',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: TraumColors.amberGold,
            fontFamily: 'DMSans',
          ),
        ),
      ],
    );
  }
}

// ─── Weight trend ──────────────────────────────────────────────────────────
class _WeightTrendContent extends ConsumerWidget {
  const _WeightTrendContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_weightLogsSnapshotProvider).value;
    if (logs == null || logs.isEmpty) {
      return const _EmptyDash();
    }
    // Stream is ordered desc by logDate.
    final latest = logs.first.weightKg;
    double? delta;
    if (logs.length > 1) {
      delta = latest - logs[1].weightKg;
    }

    Widget? trend;
    if (delta != null && delta.abs() >= 0.05) {
      final up = delta > 0;
      trend = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            up ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: 14,
            color: up ? TraumColors.roseRed : TraumColors.mintGreen,
          ),
          Text(
            '${delta.abs().toStringAsFixed(1)} kg',
            style: TextStyle(
              fontSize: 12,
              color: up ? TraumColors.roseRed : TraumColors.mintGreen,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      );
    }

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '${latest.toStringAsFixed(1)} kg',
          style: const TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: TraumColors.mintGreen,
            fontFamily: 'DMSans',
          ),
        ),
        if (trend != null) ...[
          const SizedBox(height: 4),
          trend,
        ],
      ],
    );
  }
}

// ─── Health score ──────────────────────────────────────────────────────────
class _HealthScoreContent extends ConsumerWidget {
  final HomeTileSize size;
  const _HealthScoreContent({required this.size});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final score = ref.watch(healthScoreProvider).value?.gesamtScore;
    if (score == null) {
      return _EmptyDash(fontSize: size == HomeTileSize.small ? 32 : 48);
    }
    final color = scoreLabelColor(score);
    final ringSize = size == HomeTileSize.small ? 72.0 : 96.0;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        CircularProgressRing(
          value: (score / 100).clamp(0.0, 1.0),
          size: ringSize,
          color: color,
          center: Text(
            '$score',
            style: TextStyle(
              fontSize: size == HomeTileSize.small ? 24 : 32,
              fontWeight: FontWeight.w700,
              color: color,
              fontFamily: 'DMSans',
            ),
          ),
        ),
        if (size != HomeTileSize.small) ...[
          const SizedBox(height: 8),
          Text(
            scoreLabel(score),
            style: const TextStyle(
              fontSize: 13,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ],
    );
  }
}

// ─── Health snapshot (3 metrics) ─────────────────────────────────────────────
class _HealthSnapshotContent extends ConsumerWidget {
  const _HealthSnapshotContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sleepLogs = ref.watch(recentSleepLogsProvider(2)).value;
    final mood = ref.watch(latestMoodProvider).value;

    String sleepValue = '—';
    if (sleepLogs != null && sleepLogs.isNotEmpty) {
      final latest =
          sleepLogs.reduce((a, b) => a.bedtime.isAfter(b.bedtime) ? a : b);
      final hours = latest.wakeTime.difference(latest.bedtime).inMinutes / 60.0;
      if (hours > 0) sleepValue = hours.toStringAsFixed(1);
    }

    final now = DateTime.now();
    final moodToday = mood != null &&
        mood.logDate.year == now.year &&
        mood.logDate.month == now.month &&
        mood.logDate.day == now.day;
    final moodValue = moodToday ? '${mood.moodScore.clamp(1, 5)}' : '—';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _SnapshotMetric(
          icon: Icons.bedtime_rounded,
          label: 'Schlaf',
          value: sleepValue,
          unit: 'h',
          color: TraumColors.lavender,
        ),
        const _SnapshotMetric(
          icon: Icons.favorite_rounded,
          label: 'Herzfrequenz',
          value: '—',
          unit: 'bpm',
          color: TraumColors.roseRed,
        ),
        _SnapshotMetric(
          icon: Icons.mood_rounded,
          label: 'Stimmung',
          value: moodValue,
          unit: '/5',
          color: TraumColors.amberGold,
        ),
      ],
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  final IconData icon;
  final String label, value, unit;
  final Color color;

  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: color,
                    fontFamily: 'DMSans',
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontSize: 11,
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                  ),
                ),
              ],
            ),
          ),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: TraumColors.onBackgroundMuted,
              fontFamily: 'DMSans',
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Steps week chart ────────────────────────────────────────────────────────
class _StepsWeekChartContent extends StatelessWidget {
  const _StepsWeekChartContent();

  @override
  Widget build(BuildContext context) {
    // No live step source → empty state.
    return const Center(
      child: Text(
        'Noch keine Daten',
        style: TextStyle(
          fontSize: 13,
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
        ),
      ),
    );
  }
}

// ─── Weight chart ────────────────────────────────────────────────────────────
class _WeightChartContent extends ConsumerWidget {
  const _WeightChartContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_weightLogsSnapshotProvider).value;
    if (logs == null || logs.isEmpty) {
      return const Center(
        child: Text(
          'Noch keine Daten',
          style: TextStyle(
            fontSize: 13,
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
      );
    }

    // Stream ordered desc → take up to 14 most recent, then chronological.
    final recent = logs.take(14).toList().reversed.toList();
    final spots = <FlSpot>[];
    for (var i = 0; i < recent.length; i++) {
      spots.add(FlSpot(i.toDouble(), recent[i].weightKg));
    }
    final labels = [
      for (final l in recent) '${l.logDate.day}.${l.logDate.month}',
    ];

    return TraumLineChart(
      spots: spots,
      xLabels: labels,
      color: TraumColors.mintGreen,
      height: 140,
    );
  }
}
