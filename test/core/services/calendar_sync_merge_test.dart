import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/services/calendar_sync_merge.dart';

void main() {
  final windowStart = DateTime(2026, 1, 1);
  final windowEnd = DateTime(2026, 12, 31);

  AppointmentSyncView apt({
    required int id,
    String? externalEventId,
    bool isAppOrigin = true,
    String title = 'Termin',
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    bool allDay = false,
  }) {
    final s = start ?? DateTime(2026, 6, 1, 10, 0);
    return AppointmentSyncView(
      id: id,
      externalEventId: externalEventId,
      isAppOrigin: isAppOrigin,
      title: title,
      description: description,
      location: location,
      start: s,
      end: end ?? s.add(const Duration(hours: 1)),
      allDay: allDay,
    );
  }

  SyncEventData event({
    String? externalId,
    String title = 'Termin',
    String? description,
    String? location,
    DateTime? start,
    DateTime? end,
    bool allDay = false,
  }) {
    final s = start ?? DateTime(2026, 6, 1, 10, 0);
    return SyncEventData(
      externalId: externalId,
      title: title,
      description: description,
      location: location,
      start: s,
      end: end ?? s.add(const Duration(hours: 1)),
      allDay: allDay,
    );
  }

  test('device event unknown in app -> pullInsert', () {
    final actions = computeSyncActions(
      appAppointments: const [],
      deviceEvents: [event(externalId: 'dev-1')],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.pullInsert);
    expect(actions.single.externalId, 'dev-1');
    expect(actions.single.appointmentId, isNull);
  });

  test('device event changed vs app copy (device origin) -> pullUpdate', () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(id: 1, externalEventId: 'dev-2', isAppOrigin: false, title: 'Alt'),
      ],
      deviceEvents: [event(externalId: 'dev-2', title: 'Neu')],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.pullUpdate);
    expect(actions.single.appointmentId, 1);
    expect(actions.single.externalId, 'dev-2');
  });

  test('app appointment without externalId -> pushInsert', () {
    final actions = computeSyncActions(
      appAppointments: [apt(id: 5, isAppOrigin: true)],
      deviceEvents: const [],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.pushInsert);
    expect(actions.single.appointmentId, 5);
    expect(actions.single.externalId, isNull);
  });

  test('app-origin appointment differs from device event -> pushUpdate', () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(id: 2, externalEventId: 'dev-3', isAppOrigin: true, title: 'App-Titel'),
      ],
      deviceEvents: [event(externalId: 'dev-3', title: 'Geraete-Titel')],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.pushUpdate);
    expect(actions.single.appointmentId, 2);
    expect(actions.single.externalId, 'dev-3');
  });

  test(
      'app-origin appointment linked but missing on device (in window) -> deleteLocal',
      () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(
          id: 3,
          externalEventId: 'dev-4',
          isAppOrigin: true,
          start: DateTime(2026, 6, 1),
        ),
      ],
      deviceEvents: const [],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.deleteLocal);
    expect(actions.single.appointmentId, 3);
  });

  test(
      'device-origin app copy missing on device (in window) -> deleteLocal',
      () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(
          id: 4,
          externalEventId: 'dev-5',
          isAppOrigin: false,
          start: DateTime(2026, 6, 1),
        ),
      ],
      deviceEvents: const [],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.deleteLocal);
    expect(actions.single.appointmentId, 4);
  });

  test('identical both sides -> none', () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(id: 6, externalEventId: 'dev-6', isAppOrigin: false),
      ],
      deviceEvents: [event(externalId: 'dev-6')],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.none);
  });

  test('event outside window is ignored', () {
    // This is the exact guard that fixes the Audit 6.5 data-loss bug: an app
    // appointment linked to a (no longer present) device event, whose OWN
    // start lies outside the currently-synced window, must NOT be deleted —
    // because the device query never covered that period in the first place,
    // its absence from deviceEvents carries no information.
    final actions = computeSyncActions(
      appAppointments: [
        apt(
          id: 7,
          externalEventId: 'dev-7',
          isAppOrigin: true,
          start: DateTime(2020, 1, 1),
        ),
      ],
      deviceEvents: const [],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, isEmpty);
  });

  test('null description on one side treated same as empty string -> none', () {
    final actions = computeSyncActions(
      appAppointments: [
        apt(id: 8, externalEventId: 'dev-8', isAppOrigin: true, description: null),
      ],
      deviceEvents: [event(externalId: 'dev-8', description: '')],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.none);
  });

  test('sub-minute time difference is ignored (minute precision) -> none', () {
    final start = DateTime(2026, 6, 1, 10, 0, 0);
    final actions = computeSyncActions(
      appAppointments: [
        apt(id: 9, externalEventId: 'dev-9', isAppOrigin: true, start: start),
      ],
      deviceEvents: [
        event(externalId: 'dev-9', start: start.add(const Duration(seconds: 30))),
      ],
      windowStart: windowStart,
      windowEnd: windowEnd,
    );
    expect(actions, hasLength(1));
    expect(actions.single.type, SyncActionType.none);
  });
}
