import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/providers/repository_providers.dart';
import '../../data/database/traum_database.dart';

export '../../core/providers/preferences_provider.dart' show activeDiaryProvider;

final diariesProvider = FutureProvider.autoDispose<List<Diary>>(
    (ref) => ref.watch(diaryRepositoryProvider).getAllDiaries());

final activeDiaryInfoProvider = FutureProvider.autoDispose<Diary?>((ref) {
  final id = ref.watch(activeDiaryProvider);
  return ref.watch(diaryRepositoryProvider).getDiaryById(id);
});

final diaryEntryCountProvider =
    FutureProvider.autoDispose.family<int, int>((ref, diaryId) =>
        ref.watch(diaryRepositoryProvider).diaryEntryCount(diaryId));

/// Pfad des letzten Fotos/Video-Vorschaubilds im aktiven Tagebuch — als
/// Geist-Overlay-Referenz für die nächste Aufnahme (`null`, wenn das
/// Tagebuch noch leer ist).
final diaryGhostImageProvider = FutureProvider.autoDispose<String?>((ref) async {
  final diaryId = ref.watch(activeDiaryProvider);
  final entry = await ref.watch(diaryRepositoryProvider).getLastEntry(diaryId);
  if (entry == null) return null;
  return entry.mediaType == 'video' ? entry.thumbnailPath : entry.mediaPath;
});

final diaryEntriesForMonthProvider = FutureProvider.autoDispose
    .family<List<DiaryEntry>, (int, int)>((ref, ym) {
  final diaryId = ref.watch(activeDiaryProvider);
  return ref
      .watch(diaryRepositoryProvider)
      .getEntriesForMonth(diaryId, ym.$1, ym.$2);
});

final todaysDiaryEntryProvider =
    FutureProvider.autoDispose<DiaryEntry?>((ref) {
  final diaryId = ref.watch(activeDiaryProvider);
  final today = DateTime.now();
  final dateStr =
      '${today.year.toString().padLeft(4, '0')}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
  return ref.watch(diaryRepositoryProvider).getEntryForDate(diaryId, dateStr);
});

final datesWithDiaryEntriesProvider =
    FutureProvider.autoDispose<Set<String>>((ref) async {
  final diaryId = ref.watch(activeDiaryProvider);
  final dates =
      await ref.watch(diaryRepositoryProvider).getDatesWithEntries(diaryId);
  return dates.toSet();
});

final diaryStreakProvider = FutureProvider.autoDispose<int>((ref) async {
  final diaryId = ref.watch(activeDiaryProvider);
  final dates =
      await ref.watch(diaryRepositoryProvider).getDatesLastYear(diaryId);
  return _calculateStreak(dates);
});

final totalDiaryEntriesProvider = FutureProvider.autoDispose<int>((ref) {
  final diaryId = ref.watch(activeDiaryProvider);
  return ref.watch(diaryRepositoryProvider).getTotalCount(diaryId);
});

final recentDiaryEntriesProvider = FutureProvider.autoDispose
    .family<List<DiaryEntry>, int>((ref, days) {
  final diaryId = ref.watch(activeDiaryProvider);
  return ref.watch(diaryRepositoryProvider).getRecentEntries(diaryId, days);
});

/// Volltextsuche über die Notiz-Einträge des aktiven Tagebuchs. Lädt nur
/// bei nicht-leerer Query (siehe `diarySearchScreen.dart`), damit ein
/// leeres Suchfeld keine unnötige Abfrage auslöst.
final diarySearchResultsProvider = FutureProvider.autoDispose
    .family<List<DiaryEntry>, (int, String)>((ref, params) {
  final (diaryId, query) = params;
  if (query.trim().isEmpty) return Future.value(const <DiaryEntry>[]);
  return ref.watch(diaryRepositoryProvider).searchEntries(diaryId, query);
});

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
