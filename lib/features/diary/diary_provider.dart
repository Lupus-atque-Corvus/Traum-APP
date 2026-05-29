import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../data/database/traum_database.dart';

final diaryEntriesForMonthProvider = FutureProvider.autoDispose
    .family<List<DiaryEntry>, (int, int)>((ref, ym) =>
        ref.watch(diaryDaoProvider).getEntriesForMonth(ym.$1, ym.$2));

final todaysDiaryEntryProvider =
    FutureProvider.autoDispose<DiaryEntry?>((ref) {
  final today = DateTime.now();
  final dateStr =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return ref.watch(diaryDaoProvider).getEntryForDate(dateStr);
});

final datesWithDiaryEntriesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final dates = await ref.watch(diaryDaoProvider).getDatesWithEntries();
  return dates.toSet();
});

final diaryStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final dates = await ref.watch(diaryDaoProvider).getDatesLastYear();
  return _calculateStreak(dates);
});

final totalDiaryEntriesProvider =
    FutureProvider.autoDispose<int>((ref) =>
        ref.watch(diaryDaoProvider).getTotalCount());

final recentDiaryEntriesProvider =
    FutureProvider.autoDispose.family<List<DiaryEntry>, int>((ref, days) =>
        ref.watch(diaryDaoProvider).getRecentEntries(days));

int _calculateStreak(List<String> sortedDates) {
  if (sortedDates.isEmpty) return 0;
  int streak = 0;
  DateTime current = DateTime.now();
  for (final dateStr in sortedDates) {
    final date = DateTime.parse(dateStr);
    final diff = DateTime(current.year, current.month, current.day)
        .difference(DateTime(date.year, date.month, date.day))
        .inDays;
    if (diff == 0 || diff == 1) {
      streak++;
      current = date;
    } else {
      break;
    }
  }
  return streak;
}
