import 'dart:convert';

/// A single reminder time-of-day, restricted to a set of ISO weekdays
/// (1=Monday..7=Sunday). Not everyone takes a medication/supplement every
/// day of the week, or at the same time every day it is taken — each
/// medication/supplement can have several of these, one per distinct
/// time-of-day it's actually taken at.
class ReminderTime {
  /// "HH:mm", 24h.
  final String time;

  /// ISO weekdays this time applies on (1=Monday..7=Sunday). Always
  /// non-empty in practice — the UI doesn't allow clearing the last day.
  final Set<int> days;

  const ReminderTime({required this.time, required this.days});

  factory ReminderTime.everyDay(String time) =>
      ReminderTime(time: time, days: const {1, 2, 3, 4, 5, 6, 7});

  bool get isEveryDay => days.length == 7;

  ReminderTime copyWith({String? time, Set<int>? days}) =>
      ReminderTime(time: time ?? this.time, days: days ?? this.days);

  Map<String, dynamic> toJson() =>
      {'time': time, 'days': days.toList()..sort()};

  static ReminderTime fromJson(dynamic json) {
    // Legacy format: a bare "HH:mm" string meant "every day" — the only
    // option that existed before per-weekday selection.
    if (json is String) return ReminderTime.everyDay(json);
    final map = json as Map<String, dynamic>;
    final days = ((map['days'] as List?)?.cast<int>() ?? const <int>[]).toSet();
    return ReminderTime(
      time: map['time'] as String,
      days: days.isEmpty ? const {1, 2, 3, 4, 5, 6, 7} : days,
    );
  }
}

/// Parses a medication's/supplement's `timings` column (JSON: either the
/// legacy `["08:00", "20:00"]` array of plain strings, or the current
/// `[{"time":"08:00","days":[1,2,3,4,5]}, ...]` array of objects — mixed
/// arrays from an edit that only touched some entries are fine too, each
/// entry is parsed independently).
List<ReminderTime> parseReminderTimes(String timingsJson) {
  try {
    final decoded = jsonDecode(timingsJson) as List;
    return decoded.map(ReminderTime.fromJson).toList();
  } catch (_) {
    return const [];
  }
}

String encodeReminderTimes(List<ReminderTime> times) =>
    jsonEncode(times.map((t) => t.toJson()).toList());
