import 'date_utils.dart' as traum_dates;

int calculateStreak(List<DateTime> dates) {
  if (dates.isEmpty) return 0;
  final sorted = dates.toList()..sort((a, b) => b.compareTo(a));
  final today = DateTime.now();
  int streak = 0;
  DateTime check = today;

  for (final d in sorted) {
    if (traum_dates.isSameDay(d, check)) {
      streak++;
      check = check.subtract(const Duration(days: 1));
    } else if (traum_dates.isSameDay(d, check.subtract(const Duration(days: 1)))) {
      // gap allowed
      continue;
    } else {
      break;
    }
  }
  return streak;
}
