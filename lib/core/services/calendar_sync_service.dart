import 'package:device_calendar/device_calendar.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/services.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../data/database/traum_database.dart';
import '../../data/preferences/preferences_repository.dart';
import 'calendar_sync_merge.dart';

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

/// Lightweight calendar descriptor returned by our native Android channel.
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

/// Event data read directly from Android CalendarContract via native channel.
class _NativeEvent {
  final String id;
  final String title;
  final String? description;
  final String? location;
  final DateTime startTime;
  final DateTime endTime;
  final bool allDay;
  final String calendarId;

  const _NativeEvent({
    required this.id,
    required this.title,
    this.description,
    this.location,
    required this.startTime,
    required this.endTime,
    this.allDay = false,
    this.calendarId = '',
  });
}

class CalendarSyncService {
  final PlanningDao _dao;
  final PreferencesRepository _prefs;
  final DeviceCalendarPlugin _plugin = DeviceCalendarPlugin();
  static const _nativeChannel = MethodChannel('traum/calendar');

  CalendarSyncService(this._dao, this._prefs);

  Future<bool> requestPermissions() async {
    var result = await _plugin.hasPermissions();
    if (result.data != true) {
      result = await _plugin.requestPermissions();
    }
    return result.data == true;
  }

  /// Lists writable calendars via native Android CalendarContract.
  /// Falls back to device_calendar on iOS or if the native call fails.
  Future<List<NativeCalendar>> getAvailableCalendars() async {
    try {
      final raw =
          await _nativeChannel.invokeMethod<List<dynamic>>('getCalendars');
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
    // iOS / fallback
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

  /// Reads events from one or more calendars directly via native Android channel.
  Future<List<_NativeEvent>> _getNativeEvents(
    List<String> calendarIds,
    DateTime start,
    DateTime end,
  ) async {
    try {
      final raw = await _nativeChannel.invokeMethod<List<dynamic>>('getEvents', {
        'calendarIds': calendarIds,
        'startMs': start.millisecondsSinceEpoch,
        'endMs': end.millisecondsSinceEpoch,
      });
      if (raw == null) return [];
      return raw.cast<Map<dynamic, dynamic>>().map((m) {
        final startMs = m['startMs'] as int? ?? 0;
        final endMs = m['endMs'] as int? ?? startMs + 3600000;
        return _NativeEvent(
          id: m['id'].toString(),
          title: m['title']?.toString() ?? '(Kein Titel)',
          description: m['description']?.toString(),
          location: m['location']?.toString(),
          startTime: DateTime.fromMillisecondsSinceEpoch(startMs),
          endTime: DateTime.fromMillisecondsSinceEpoch(endMs),
          allDay: m['allDay'] as bool? ?? false,
          calendarId: m['calendarId']?.toString() ?? '',
        );
      }).toList();
    } catch (_) {
      return [];
    }
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
    final result = await _plugin.createOrUpdateEvent(event);
    return result?.data;
  }

  Future<void> _pullInsertEvent(_NativeEvent event, DateTime now) async {
    await _dao.insertAppointment(AppointmentsCompanion.insert(
      title: event.title,
      description: Value(event.description),
      location: Value(event.location),
      startTime: event.startTime,
      endTime: Value(event.endTime),
      allDay: Value(event.allDay),
      externalEventId: Value(event.id),
      sourceCalendarId: Value(event.calendarId),
      isAppOrigin: const Value(false),
      lastSyncedAt: Value(now),
      updatedAt: Value(now),
    ));
  }

  AppointmentSyncView _toSyncView(Appointment a) => AppointmentSyncView(
        id: a.id,
        externalEventId: a.externalEventId,
        isAppOrigin: a.isAppOrigin,
        title: a.title,
        description: a.description,
        location: a.location,
        start: a.startTime,
        end: a.endTime ?? a.startTime.add(const Duration(hours: 1)),
        allDay: a.allDay,
      );

  SyncEventData _toSyncEventData(_NativeEvent e) => SyncEventData(
        externalId: e.id,
        title: e.title,
        description: e.description,
        location: e.location,
        start: e.startTime,
        end: e.endTime,
        allDay: e.allDay,
      );

  /// Push a single newly created app appointment to the primary device calendar.
  Future<void> syncNewAppointment(int appointmentId) async {
    final ids = _prefs.selectedCalendarIds;
    if (ids.isEmpty) return;
    final apt = await _dao.getAppointmentById(appointmentId);
    if (apt == null || apt.externalEventId != null) return;
    try {
      final newId = await _pushToDevice(apt, ids.first);
      if (newId != null) await _dao.updateExternalEventId(apt.id, newId);
    } catch (_) {}
  }

  /// Push an app appointment that was just edited to the device calendar.
  /// Uses `pushUpdate` semantics: if the appointment already has an
  /// [Appointment.externalEventId], [_pushToDevice] updates that exact
  /// device event (app-origin wins a conflict); otherwise it behaves like
  /// [syncNewAppointment] and creates one.
  Future<void> syncUpdatedAppointment(int appointmentId) async {
    final ids = _prefs.selectedCalendarIds;
    if (ids.isEmpty) return;
    final apt = await _dao.getAppointmentById(appointmentId);
    if (apt == null) return;
    try {
      final targetCalendarId = apt.sourceCalendarId ?? ids.first;
      final resultId = await _pushToDevice(apt, targetCalendarId);
      if (resultId != null) {
        await _dao.updateAppointmentAfterPush(
          id: apt.id,
          externalEventId: resultId,
          sourceCalendarId: targetCalendarId,
          lastSyncedAt: DateTime.now(),
        );
      }
    } catch (_) {}
  }

  Future<void> deleteAppointmentWithSync(int appointmentId) async {
    final apt = await _dao.getAppointmentById(appointmentId);
    if (apt != null && apt.externalEventId != null) {
      final ids = _prefs.selectedCalendarIds;
      if (ids.isNotEmpty) {
        try {
          await _plugin.deleteEvent(ids.first, apt.externalEventId!);
        } catch (_) {}
      }
    }
    await _dao.deleteAppointment(appointmentId);
  }

  Future<SyncResult> sync() async {
    final granted = await requestPermissions();
    if (!granted) return const SyncResult(permissionDenied: true);

    final calendarIds = _prefs.selectedCalendarIds;
    if (calendarIds.isEmpty) return const SyncResult(needsCalendarSelection: true);

    final now = DateTime.now();
    final windowStart = now.subtract(const Duration(days: 180));
    final windowEnd = now.add(const Duration(days: 365));

    // Read events from ALL selected calendars via native channel
    final deviceEvents =
        await _getNativeEvents(calendarIds, windowStart, windowEnd);
    final appAppointments = await _dao.getAllAppointments();

    final appById = {for (final a in appAppointments) a.id: a};
    final deviceById = {for (final e in deviceEvents) e.id: e};

    final actions = computeSyncActions(
      appAppointments: appAppointments.map(_toSyncView).toList(),
      deviceEvents: deviceEvents.map(_toSyncEventData).toList(),
      windowStart: windowStart,
      windowEnd: windowEnd,
    );

    int synced = 0;
    int errors = 0;

    for (final action in actions) {
      try {
        switch (action.type) {
          case SyncActionType.none:
            break;

          case SyncActionType.pullInsert:
            final event = deviceById[action.externalId];
            if (event == null) break;
            await _pullInsertEvent(event, now);
            synced++;
            break;

          case SyncActionType.pullUpdate:
            final event = deviceById[action.externalId];
            final appointmentId = action.appointmentId;
            if (event == null || appointmentId == null) break;
            await _dao.updateAppointmentFromDevice(
              id: appointmentId,
              title: event.title,
              description: event.description,
              location: event.location,
              startTime: event.startTime,
              endTime: event.endTime,
              allDay: event.allDay,
              updatedAt: now,
              sourceCalendarId: event.calendarId,
              lastSyncedAt: now,
            );
            synced++;
            break;

          case SyncActionType.pushInsert:
          case SyncActionType.pushUpdate:
            final appointmentId = action.appointmentId;
            if (appointmentId == null) break;
            final apt = appById[appointmentId];
            if (apt == null) break;
            final targetCalendarId = apt.sourceCalendarId ?? calendarIds.first;
            final resultId = await _pushToDevice(apt, targetCalendarId);
            if (resultId != null) {
              await _dao.updateAppointmentAfterPush(
                id: apt.id,
                externalEventId: resultId,
                sourceCalendarId: targetCalendarId,
                lastSyncedAt: now,
              );
              synced++;
            }
            break;

          case SyncActionType.deleteLocal:
            final appointmentId = action.appointmentId;
            if (appointmentId == null) break;
            await _dao.deleteAppointment(appointmentId);
            synced++;
            break;

          case SyncActionType.deleteRemote:
            final externalId = action.externalId;
            if (externalId == null) break;
            final apt =
                action.appointmentId != null ? appById[action.appointmentId] : null;
            final targetCalendarId = apt?.sourceCalendarId ?? calendarIds.first;
            await _plugin.deleteEvent(targetCalendarId, externalId);
            synced++;
            break;
        }
      } catch (_) {
        errors++;
      }
    }

    return SyncResult(synced: synced, errors: errors);
  }
}
