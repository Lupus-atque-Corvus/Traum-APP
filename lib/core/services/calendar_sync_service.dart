import 'package:device_calendar/device_calendar.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/database/traum_database.dart';
import '../../data/preferences/preferences_repository.dart';

class SyncResult {
  final bool permissionDenied;
  final bool needsCalendarSelection;
  final int synced;
  final int errors;

  const SyncResult({
    this.permissionDenied = false,
    this.needsCalendarSelection = false,
    this.synced = 0,
    this.errors = 0,
  });
}

/// Lightweight calendar descriptor returned by our native channel.
class NativeCalendar {
  final String id;
  final String name;
  final String? accountName;
  final int? color;

  const NativeCalendar({
    required this.id,
    required this.name,
    this.accountName,
    this.color,
  });
}

class CalendarSyncService {
  final PlanningDao _dao;
  final PreferencesRepository _prefs;
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static const _nativeChannel = MethodChannel('traum/calendar');

  CalendarSyncService(this._dao, this._prefs);

  Future<bool> requestPermissions() async {
    // Check first — avoids re-prompting if already granted
    var result = await _plugin.hasPermissions();
    if (result.data != true) {
      result = await _plugin.requestPermissions();
    }
    return result.data == true;
  }

  /// Queries the Android CalendarContract directly via a native platform channel.
  /// This bypasses device_calendar's broken Calendar.id serialization on some devices.
  Future<List<NativeCalendar>> getAvailableCalendars() async {
    try {
      final raw = await _nativeChannel.invokeMethod<List<dynamic>>('getCalendars');
      if (raw != null && raw.isNotEmpty) {
        return raw
            .cast<Map<dynamic, dynamic>>()
            .map((m) => NativeCalendar(
                  id: m['id'].toString(),
                  name: m['name']?.toString() ??
                      m['accountName']?.toString() ??
                      'Kalender',
                  accountName: m['accountName']?.toString(),
                  color: m['color'] as int?,
                ))
            .toList();
      }
    } catch (_) {}
    // Fallback to device_calendar if native channel fails (e.g. on iOS)
    final result = await _plugin.retrieveCalendars();
    return result.data
            ?.where((c) => c.id != null && c.isReadOnly != true)
            .map((c) => NativeCalendar(
                  id: c.id!,
                  name: c.name ?? c.accountName ?? 'Kalender',
                  accountName: c.accountName,
                  color: c.color,
                ))
            .toList() ??
        [];
  }

  TZDateTime _toTZ(DateTime dt) => TZDateTime.from(dt, tz.local);

  Future<String?> _pushToDevice(Appointment apt, String calendarId) async {
    final event = Event(calendarId)
      ..eventId = apt.externalEventId
      ..title = apt.title
      ..description = apt.description
      ..location = apt.location
      ..start = _toTZ(apt.startTime)
      ..end = _toTZ(apt.endTime ?? apt.startTime.add(const Duration(hours: 1)))
      ..allDay = apt.allDay;
    // Note: device_calendar Event does not expose a color setter in v4.x
    final result = await _plugin.createOrUpdateEvent(event);
    return result?.data;
  }

  Future<void> _pullFromDevice(Event event) async {
    await _dao.insertAppointment(AppointmentsCompanion.insert(
      title: event.title ?? '(Kein Titel)',
      description: Value(event.description),
      location: Value(event.location),
      startTime: event.start?.toLocal() ?? DateTime.now(),
      endTime: Value(event.end?.toLocal()),
      allDay: Value(event.allDay ?? false),
      externalEventId: Value(event.eventId),
      // device_calendar v4.x Event does not expose lastModifiedDate
      updatedAt: Value(DateTime.now()),
    ));
  }

  Future<void> syncNewAppointment(int appointmentId) async {
    final calendarId = _prefs.selectedCalendarId;
    if (calendarId == null) return;
    final apt = await _dao.getAppointmentById(appointmentId);
    if (apt == null || apt.externalEventId != null) return;
    try {
      final newId = await _pushToDevice(apt, calendarId);
      if (newId != null) await _dao.updateExternalEventId(apt.id, newId);
    } catch (_) {}
  }

  Future<void> deleteAppointmentWithSync(int appointmentId) async {
    final apt = await _dao.getAppointmentById(appointmentId);
    if (apt != null && apt.externalEventId != null) {
      final calendarId = _prefs.selectedCalendarId;
      if (calendarId != null) {
        try {
          await _plugin.deleteEvent(calendarId, apt.externalEventId!);
        } catch (_) {
          // Device delete failed — local deletion still proceeds
        }
      }
    }
    await _dao.deleteAppointment(appointmentId);
  }

  Future<SyncResult> sync() async {
    final granted = await requestPermissions();
    if (!granted) return const SyncResult(permissionDenied: true);

    final calendarId = _prefs.selectedCalendarId;
    if (calendarId == null) return const SyncResult(needsCalendarSelection: true);

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 180));
    final windowEnd = now.add(const Duration(days: 365));

    final eventsResult = await _plugin.retrieveEvents(
      calendarId,
      RetrieveEventsParams(startDate: windowStart, endDate: windowEnd),
    );
    final deviceEvents = eventsResult.data?.toList() ?? [];
    final appAppointments = await _dao.getAllAppointments();

    final appByExternalId = <String, Appointment>{
      for (final a in appAppointments)
        if (a.externalEventId != null) a.externalEventId!: a,
    };
    final deviceEventIds = <String>{
      for (final e in deviceEvents)
        if (e.eventId != null) e.eventId!,
    };

    int synced = 0;
    int errors = 0;

    // Device → App: import new events + conflict resolution
    for (final event in deviceEvents) {
      try {
        if (event.eventId == null) continue;
        final existing = appByExternalId[event.eventId!];
        if (existing == null) {
          await _pullFromDevice(event);
          synced++;
        }
        // Note: device_calendar v4.x does not expose a lastModifiedDate on Event,
        // so timestamp-based conflict resolution ("newest wins") is not possible.
        // Existing local records are preserved; only genuinely new device events
        // are imported. If the package is upgraded to expose a modification
        // timestamp, updateAppointmentFromDevice() can be used here.
      } catch (_) {
        errors++;
      }
    }

    // App → Device: push new app appointments + handle device-side deletions
    for (final apt in appAppointments) {
      try {
        if (apt.externalEventId != null) {
          final inWindow = apt.startTime.isAfter(windowStart) &&
              apt.startTime.isBefore(windowEnd);
          if (inWindow && !deviceEventIds.contains(apt.externalEventId!)) {
            await _dao.deleteAppointment(apt.id);
            synced++;
          }
        } else {
          final newId = await _pushToDevice(apt, calendarId);
          if (newId != null) {
            await _dao.updateExternalEventId(apt.id, newId);
            synced++;
          }
        }
      } catch (_) {
        errors++;
      }
    }

    return SyncResult(synced: synced, errors: errors);
  }
}
