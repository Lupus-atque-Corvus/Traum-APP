import 'package:device_calendar/device_calendar.dart';
// ignore: implementation_imports
import 'package:drift/drift.dart';
import 'package:flutter/material.dart' show Color;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/database/traum_database.dart';
import '../providers/database_provider.dart';

class CalendarSyncResult {
  final int imported;
  final int exported;
  final String? error;

  const CalendarSyncResult({
    this.imported = 0,
    this.exported = 0,
    this.error,
  });
}

class CalendarSyncService {
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  final TraumDatabase _db;

  CalendarSyncService(this._db);

  Future<CalendarSyncResult> syncFromDevice() async {
    try {
      // Request permissions
      var permResult = await _plugin.hasPermissions();
      if (permResult.isSuccess && !(permResult.data ?? false)) {
        permResult = await _plugin.requestPermissions();
      }
      if (!(permResult.data ?? false)) {
        return const CalendarSyncResult(error: 'calendar_permission_denied');
      }

      // Get all calendars
      final calendarsResult = await _plugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return const CalendarSyncResult(error: 'calendar_read_failed');
      }

      final now = DateTime.now();
      final start = now.subtract(const Duration(days: 30));
      final end = now.add(const Duration(days: 90));

      int imported = 0;

      for (final cal in calendarsResult.data!) {
        final eventsResult = await _plugin.retrieveEvents(
          cal.id,
          RetrieveEventsParams(startDate: start, endDate: end),
        );
        if (!eventsResult.isSuccess || eventsResult.data == null) continue;

        for (final event in eventsResult.data!) {
          if (event.title == null || event.start == null) continue;

          // Check if already exists (by title + startTime)
          final startLocal = event.start!.toLocal();
          final exists = await (_db.select(_db.appointments)
                ..where((t) =>
                    t.title.equals(event.title!) &
                    t.startTime.isBiggerOrEqualValue(
                        startLocal.subtract(const Duration(minutes: 1))) &
                    t.startTime.isSmallerThanValue(
                        startLocal.add(const Duration(minutes: 1)))))
              .getSingleOrNull();

          if (exists == null) {
            await _db.into(_db.appointments).insert(
                  AppointmentsCompanion.insert(
                    title: event.title!,
                    description: Value(event.description),
                    location: Value(event.location),
                    startTime: event.start!.toLocal(),
                    endTime: Value(event.end?.toLocal()),
                    allDay: Value(event.allDay ?? false),
                  ),
                );
            imported++;
          }
        }
      }

      return CalendarSyncResult(imported: imported);
    } catch (e) {
      return CalendarSyncResult(error: e.toString());
    }
  }

  Future<CalendarSyncResult> syncToDevice() async {
    try {
      // Request permissions
      var permResult = await _plugin.hasPermissions();
      if (permResult.isSuccess && !(permResult.data ?? false)) {
        permResult = await _plugin.requestPermissions();
      }
      if (!(permResult.data ?? false)) {
        return const CalendarSyncResult(error: 'calendar_permission_denied');
      }

      // Find or create TRAUM calendar
      final calendarsResult = await _plugin.retrieveCalendars();
      if (!calendarsResult.isSuccess || calendarsResult.data == null) {
        return const CalendarSyncResult(error: 'calendar_read_failed');
      }

      String? traumCalendarId;
      for (final cal in calendarsResult.data!) {
        if (cal.name == 'TRAUM') {
          traumCalendarId = cal.id;
          break;
        }
      }

      if (traumCalendarId == null) {
        final createResult = await _plugin.createCalendar(
          'TRAUM',
          calendarColor: const Color(0xFF9B8EC4),
          localAccountName: 'TRAUM',
        );
        if (!createResult.isSuccess || createResult.data == null) {
          return const CalendarSyncResult(error: 'calendar_create_failed');
        }
        traumCalendarId = createResult.data!;
      }

      // Get all app appointments in next 90 days
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      final appts = await (_db.select(_db.appointments)
            ..where((t) => t.startTime.isBiggerOrEqualValue(cutoff)))
          .get();

      int exported = 0;

      for (final appt in appts) {
        final event = Event(
          traumCalendarId,
          title: appt.title,
          description: appt.description,
          location: appt.location,
          start: TZDateTime.from(appt.startTime, local),
          end: appt.endTime != null
              ? TZDateTime.from(appt.endTime!, local)
              : TZDateTime.from(
                  appt.startTime.add(const Duration(hours: 1)), local),
          allDay: appt.allDay,
        );

        final result = await _plugin.createOrUpdateEvent(event);
        if (result?.isSuccess == true) exported++;
      }

      return CalendarSyncResult(exported: exported);
    } catch (e) {
      return CalendarSyncResult(error: e.toString());
    }
  }
}

final calendarSyncServiceProvider = Provider<CalendarSyncService>((ref) {
  final db = ref.watch(databaseProvider);
  return CalendarSyncService(db);
});
