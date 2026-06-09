import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/navigation/routes.dart';
import '../../../core/providers/database_provider.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart' show DiaryEntry, MoodLog;
import '../../diary/diary_provider.dart';
import '../home_tile.dart';
import '../home_widget_frame.dart';
import '../home_widget_registry.dart';

// ─── One-shot providers (no .watch() streams) ────────────────────────────────

/// The most recent diary entry (by createdAt), or null when none exist.
final _lastDiaryEntryProvider =
    FutureProvider.autoDispose<DiaryEntry?>((ref) {
  return ref.watch(diaryDaoProvider).getLastEntry();
});

/// Mood logs since the start of the current month, for the mood calendar.
final _monthMoodLogsProvider =
    FutureProvider.autoDispose<List<MoodLog>>((ref) {
  final now = DateTime.now();
  final monthStart = DateTime(now.year, now.month);
  return ref.watch(healthDaoProvider).getMoodLogsAfter(monthStart);
});

final Map<HomeWidgetType, HomeWidgetDescriptor> diaryHomeWidgets = {
  HomeWidgetType.writeStreak: HomeWidgetDescriptor(
    title: 'Schreib-Streak',
    group: HomeWidgetGroup.diary,
    accent: TraumColors.amberGold,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.diary,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Schreib-Streak',
      accent: TraumColors.amberGold,
      size: size,
      route: Routes.diary,
      child: const _WriteStreakContent(),
    ),
  ),
  HomeWidgetType.lastEntry: HomeWidgetDescriptor(
    title: 'Letzter Eintrag',
    group: HomeWidgetGroup.diary,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.wide,
    sizes: const {HomeTileSize.wide},
    route: Routes.diary,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Letzter Eintrag',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.diary,
      child: const _LastEntryContent(),
    ),
  ),
  HomeWidgetType.yearHeatmap: HomeWidgetDescriptor(
    title: 'Jahres-Heatmap',
    group: HomeWidgetGroup.diary,
    accent: TraumColors.mintGreen,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.diary,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Jahres-Heatmap',
      accent: TraumColors.mintGreen,
      size: size,
      route: Routes.diary,
      child: const _YearHeatmapContent(),
    ),
  ),
  HomeWidgetType.moodCalendar: HomeWidgetDescriptor(
    title: 'Stimmungs-Kalender',
    group: HomeWidgetGroup.diary,
    accent: TraumColors.lavender,
    defaultSize: HomeTileSize.large,
    sizes: const {HomeTileSize.large},
    route: Routes.diary,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Stimmungs-Kalender',
      accent: TraumColors.lavender,
      size: size,
      route: Routes.diary,
      child: const _MoodCalendarContent(),
    ),
  ),
  HomeWidgetType.entriesThisMonth: HomeWidgetDescriptor(
    title: 'Einträge/Monat',
    group: HomeWidgetGroup.diary,
    accent: TraumColors.cyanBlue,
    defaultSize: HomeTileSize.small,
    sizes: const {HomeTileSize.small},
    route: Routes.diary,
    builder: (context, ref, size) => HomeWidgetFrame(
      title: 'Einträge/Monat',
      accent: TraumColors.cyanBlue,
      size: size,
      route: Routes.diary,
      child: const _EntriesThisMonthContent(),
    ),
  ),
};

// ─── Shared display helpers ──────────────────────────────────────────────────
const _muted = TextStyle(
  fontSize: 13,
  color: TraumColors.onBackgroundMuted,
  fontFamily: 'DMSans',
);

class _BigValue extends StatelessWidget {
  final String value;
  final String unit;
  final Color color;
  const _BigValue({required this.value, required this.unit, required this.color});

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
        Text(unit, style: _muted.copyWith(fontSize: 11)),
      ],
    );
  }
}

// ─── Schreib-Streak ──────────────────────────────────────────────────────────
class _WriteStreakContent extends ConsumerWidget {
  const _WriteStreakContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final streak = ref.watch(diaryStreakProvider).value;
    return _BigValue(
      value: streak == null ? '—' : '$streak',
      unit: streak == 1 ? 'Tag' : 'Tage',
      color: TraumColors.amberGold,
    );
  }
}

// ─── Letzter Eintrag ─────────────────────────────────────────────────────────
class _LastEntryContent extends ConsumerWidget {
  const _LastEntryContent();

  static const _months = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entry = ref.watch(_lastDiaryEntryProvider).value;
    if (entry == null) {
      return const Text('—', style: _muted);
    }
    final d = entry.createdAt;
    final dateLabel = '${d.day}. ${_months[d.month - 1]} ${d.year}';
    final note = entry.note.trim();
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: TraumColors.cyanBlue.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.menu_book_rounded,
              color: TraumColors.cyanBlue, size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                dateLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: TraumColors.onBackground,
                  fontFamily: 'DMSans',
                ),
              ),
              const SizedBox(height: 2),
              Text(
                note.isEmpty ? 'Kein Text' : note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: _muted.copyWith(fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Jahres-Heatmap ──────────────────────────────────────────────────────────
class _YearHeatmapContent extends ConsumerWidget {
  const _YearHeatmapContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dates = ref.watch(datesWithDiaryEntriesProvider).value ?? const {};
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startDate = today.subtract(const Duration(days: 363));

    final count = dates.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          count == 0 ? 'Noch keine Einträge' : '$count Tage mit Eintrag',
          style: _muted.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(52, (week) {
                return Column(
                  children: List.generate(7, (dayOfWeek) {
                    final date =
                        startDate.add(Duration(days: week * 7 + dayOfWeek));
                    if (date.isAfter(today)) {
                      return const SizedBox(width: 9, height: 9);
                    }
                    final dateStr =
                        '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                    final hasEntry = dates.contains(dateStr);
                    final isToday = date == today;
                    return Container(
                      width: 7,
                      height: 7,
                      margin: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: isToday
                            ? TraumColors.coralOrange
                            : hasEntry
                                ? TraumColors.mintGreen
                                : TraumColors.surfaceVariant,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Stimmungs-Kalender ──────────────────────────────────────────────────────
class _MoodCalendarContent extends ConsumerWidget {
  const _MoodCalendarContent();

  static const _moodColors = [
    TraumColors.roseRed,
    TraumColors.coralOrange,
    TraumColors.amberGold,
    TraumColors.mintGreen,
    TraumColors.cyanBlue,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logs = ref.watch(_monthMoodLogsProvider).value ?? const <MoodLog>[];
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final firstWeekday = DateTime(now.year, now.month, 1).weekday; // 1 = Mon

    // Latest mood score per day-of-month.
    final moodByDay = <int, int>{};
    for (final log in logs) {
      final d = log.logDate;
      if (d.year == now.year && d.month == now.month) {
        moodByDay[d.day] = log.moodScore.clamp(1, 5);
      }
    }

    final cells = <Widget>[];
    for (var i = 1; i < firstWeekday; i++) {
      cells.add(const SizedBox.shrink());
    }
    for (var day = 1; day <= daysInMonth; day++) {
      final score = moodByDay[day];
      final isToday = day == now.day;
      cells.add(
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: score != null
                ? _moodColors[score - 1].withValues(alpha: 0.85)
                : TraumColors.surfaceVariant,
            border: isToday
                ? Border.all(color: TraumColors.lavender, width: 1.5)
                : null,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          moodByDay.isEmpty
              ? 'Keine Stimmung erfasst'
              : '${moodByDay.length} Tage erfasst',
          style: _muted.copyWith(fontSize: 12),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: GridView.count(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            children: cells,
          ),
        ),
      ],
    );
  }
}

// ─── Einträge/Monat ──────────────────────────────────────────────────────────
class _EntriesThisMonthContent extends ConsumerWidget {
  const _EntriesThisMonthContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final entries =
        ref.watch(diaryEntriesForMonthProvider((now.year, now.month))).value;
    return _BigValue(
      value: entries == null ? '—' : '${entries.length}',
      unit: 'Einträge',
      color: TraumColors.cyanBlue,
    );
  }
}
