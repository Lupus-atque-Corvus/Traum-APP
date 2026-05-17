import 'package:flutter/material.dart';
import 'package:health/health.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';
import '../../data/database/traum_database.dart';

class HealthSyncService {
  static final _types = [
    HealthDataType.STEPS,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.HEART_RATE,
    HealthDataType.WEIGHT,
  ];

  static Future<void> syncOnStart(
    TraumDatabase db,
    SharedPreferences prefs,
    BuildContext context,
  ) async {
    final health = Health();

    try {
      await health.configure();
    } catch (e) {
      debugPrint('Health configure error: $e');
      return;
    }

    bool hasPermission = false;
    try {
      hasPermission =
          await health.hasPermissions(_types) ?? false;
    } catch (e) {
      debugPrint('Health permission check error: $e');
    }

    if (!hasPermission) {
      bool granted = false;
      try {
        granted = await health.requestAuthorization(_types);
      } catch (e) {
        debugPrint('Health permission request error: $e');
        if (context.mounted) _showHealthPermissionDialog(context, health);
        return;
      }
      if (!granted) return;
    }

    await _loadAllHealthData(db, prefs, health);
  }

  static void _showHealthPermissionDialog(
      BuildContext context, Health health) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Gesundheitsdaten benötigt',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'TRAUM benötigt Zugriff auf Schritte, Schlaf, Herzfrequenz und '
          'Gewicht aus Health Connect.',
          style: TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Später',
              style: TextStyle(color: TraumColors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Health Connect öffnen',
              style: TextStyle(
                color: TraumColors.coralOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Future<void> _loadAllHealthData(
    TraumDatabase db,
    SharedPreferences prefs,
    Health health,
  ) async {
    final now = DateTime.now();
    final thirtyDaysAgo = now.subtract(const Duration(days: 30));
    final todayStart = DateTime(now.year, now.month, now.day);

    try {
      // Schritte heute
      final steps = await health.getTotalStepsInInterval(todayStart, now);
      if (steps != null) await prefs.setInt('steps_today', steps);

      // Schritte letzte 30 Tage
      for (int i = 1; i < 30; i++) {
        final day = now.subtract(Duration(days: i));
        final s = DateTime(day.year, day.month, day.day);
        final e = s.add(const Duration(days: 1));
        final daySteps = await health.getTotalStepsInInterval(s, e);
        if (daySteps != null) {
          await prefs.setInt(
              'steps_${s.toIso8601String().substring(0, 10)}', daySteps);
        }
      }
    } catch (e) {
      debugPrint('Health steps error: $e');
    }

    try {
      // Schlaf
      final sleepData = await health.getHealthDataFromTypes(
        startTime: thirtyDaysAgo,
        endTime: now,
        types: [HealthDataType.SLEEP_ASLEEP],
      );
      for (final entry in sleepData) {
        await db.healthDao.insertSleepLog(SleepLogsCompanion.insert(
          bedtime: entry.dateFrom,
          wakeTime: entry.dateTo,
        ));
      }
    } catch (e) {
      debugPrint('Health sleep error: $e');
    }

    try {
      // Herzfrequenz
      final hrData = await health.getHealthDataFromTypes(
        startTime: thirtyDaysAgo,
        endTime: now,
        types: [HealthDataType.HEART_RATE],
      );
      if (hrData.isNotEmpty) {
        final bpm =
            (hrData.last.value as NumericHealthValue).numericValue.toInt();
        await prefs.setInt('last_heart_rate', bpm);
      }
    } catch (e) {
      debugPrint('Health heart rate error: $e');
    }

    try {
      // Gewicht
      final weightData = await health.getHealthDataFromTypes(
        startTime: DateTime(2000),
        endTime: now,
        types: [HealthDataType.WEIGHT],
      );
      for (final entry in weightData) {
        final kg =
            (entry.value as NumericHealthValue).numericValue.toDouble();
        await db.healthDao.insertWeightLog(WeightLogsCompanion.insert(
          weightKg: kg,
          logDate: entry.dateFrom,
        ));
      }
    } catch (e) {
      debugPrint('Health weight error: $e');
    }
  }
}
