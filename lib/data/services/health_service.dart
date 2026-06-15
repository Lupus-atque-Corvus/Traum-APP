import 'package:health/health.dart';

/// Thin wrapper around the `health` package for reading device health metrics
/// (Health Connect on Android, HealthKit on iOS).
///
/// Every method fails soft and returns `0` when the data is unavailable
/// (Health Connect not installed, permission denied, background isolate without
/// platform channels, …) so callers never have to handle errors.
class HealthService {
  HealthService._();

  static final Health _health = Health();
  static bool _configured = false;

  static const List<HealthDataType> readTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.EXERCISE_TIME,
  ];

  static Future<void> _ensureConfigured() async {
    if (_configured) return;
    await _health.configure();
    _configured = true;
  }

  /// Requests read authorization for all metrics we display.
  static Future<bool> requestAuthorization() async {
    try {
      await _ensureConfigured();
      return await _health.requestAuthorization(readTypes);
    } catch (_) {
      return false;
    }
  }

  /// Total steps since midnight.
  static Future<int> stepsToday() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      return (await _health.getTotalStepsInInterval(start, now)) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// Average daily steps over the last 7 days (days without data are skipped).
  static Future<int> stepsWeekAvg() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      var total = 0;
      var days = 0;
      for (var i = 0; i < 7; i++) {
        final dayStart = today.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
        if (steps != null) {
          total += steps;
          days++;
        }
      }
      return days == 0 ? 0 : (total / days).round();
    } catch (_) {
      return 0;
    }
  }

  /// Daily step counts for the last 7 days, ordered oldest → newest.
  /// Missing days are reported as 0. Empty list on error.
  static Future<List<int>> stepsWeek() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final result = <int>[];
      for (var i = 6; i >= 0; i--) {
        final dayStart = today.subtract(Duration(days: i));
        final dayEnd = dayStart.add(const Duration(days: 1));
        final steps = await _health.getTotalStepsInInterval(dayStart, dayEnd);
        result.add(steps ?? 0);
      }
      return result;
    } catch (_) {
      return const [];
    }
  }

  /// Most recent heart-rate reading within the last 24h (bpm), else 0.
  static Future<int> latestHeartRate() async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = now.subtract(const Duration(hours: 24));
      final pts = await _health.getHealthDataFromTypes(
        types: const [HealthDataType.HEART_RATE],
        startTime: start,
        endTime: now,
      );
      if (pts.isEmpty) return 0;
      pts.sort((a, b) => a.dateTo.compareTo(b.dateTo));
      final v = pts.last.value;
      return v is NumericHealthValue ? v.numericValue.round() : 0;
    } catch (_) {
      return 0;
    }
  }

  /// Active/exercise minutes today.
  static Future<int> activeMinutesToday() =>
      _sumNumericToday(HealthDataType.EXERCISE_TIME);

  /// Active energy burned today (kcal).
  static Future<int> caloriesBurnedToday() =>
      _sumNumericToday(HealthDataType.ACTIVE_ENERGY_BURNED);

  static Future<int> _sumNumericToday(HealthDataType type) async {
    try {
      await _ensureConfigured();
      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final pts = await _health.getHealthDataFromTypes(
        types: [type],
        startTime: start,
        endTime: now,
      );
      num sum = 0;
      for (final p in pts) {
        final v = p.value;
        if (v is NumericHealthValue) sum += v.numericValue;
      }
      return sum.round();
    } catch (_) {
      return 0;
    }
  }
}
