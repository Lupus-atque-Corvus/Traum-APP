/// Pure merge logic for two-way calendar sync.
///
/// This file MUST stay free of drift/flutter/plugin imports so it can be
/// unit-tested in isolation (see test/core/services/calendar_sync_merge_test.dart).
/// [CalendarSyncService] adapts the real Drift rows / native events into the
/// DTOs below, calls [computeSyncActions], then executes the returned
/// [SyncAction]s against the DAO / device_calendar plugin.
library;

/// Read-only view of an app-side appointment, as seen by the merge function.
class AppointmentSyncView {
  final int id;
  final String? externalEventId;

  /// true = the appointment was created in the app (app is source of truth,
  /// content conflicts are resolved by pushing the app's version to the
  /// device). false = the appointment was originally imported from the
  /// device calendar (device is source of truth, conflicts pull from device).
  final bool isAppOrigin;

  final String title;
  final String? description;
  final String? location;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  const AppointmentSyncView({
    required this.id,
    this.externalEventId,
    required this.isAppOrigin,
    required this.title,
    this.description,
    this.location,
    required this.start,
    required this.end,
    required this.allDay,
  });
}

/// Read-only view of a device calendar event, as seen by the merge function.
class SyncEventData {
  final String? externalId;
  final String title;
  final String? description;
  final String? location;
  final DateTime start;
  final DateTime end;
  final bool allDay;

  const SyncEventData({
    this.externalId,
    required this.title,
    this.description,
    this.location,
    required this.start,
    required this.end,
    this.allDay = false,
  });
}

enum SyncActionType {
  /// New device event unknown to the app -> insert a local appointment copy.
  pullInsert,

  /// Linked pair differs and the device wins -> overwrite the local copy.
  pullUpdate,

  /// App appointment has no external id yet -> create it on the device.
  pushInsert,

  /// Linked pair differs and the app wins -> overwrite the device event.
  pushUpdate,

  /// Linked pair's counterpart is gone -> delete the local app copy.
  deleteLocal,

  /// Local app appointment is gone but the device event should be removed
  /// too. Not produced by [computeSyncActions] itself (deletions initiated
  /// in-app are handled immediately elsewhere, see
  /// CalendarSyncService.deleteAppointmentWithSync) — kept here so the
  /// service's action executor has a defined, symmetric case.
  deleteRemote,

  /// Nothing to do.
  none,
}

class SyncAction {
  final SyncActionType type;
  final int? appointmentId;
  final String? externalId;

  const SyncAction({
    required this.type,
    this.appointmentId,
    this.externalId,
  });
}

bool _sameMinute(DateTime a, DateTime b) =>
    a.year == b.year &&
    a.month == b.month &&
    a.day == b.day &&
    a.hour == b.hour &&
    a.minute == b.minute;

/// Compares the shared content fields of an [AppointmentSyncView] and a
/// [SyncEventData]. Title compared exactly; description/location compare
/// null and '' as equal; start/end compared to minute precision; allDay
/// compared exactly.
bool sameContent(AppointmentSyncView a, SyncEventData b) {
  if (a.title != b.title) return false;
  if ((a.description ?? '') != (b.description ?? '')) return false;
  if ((a.location ?? '') != (b.location ?? '')) return false;
  if (!_sameMinute(a.start, b.start)) return false;
  if (!_sameMinute(a.end, b.end)) return false;
  if (a.allDay != b.allDay) return false;
  return true;
}

/// Computes the set of actions needed to reconcile [appAppointments] with
/// [deviceEvents].
///
/// Matching key: an app appointment links to a device event via
/// `AppointmentSyncView.externalEventId == SyncEventData.externalId`.
///
/// [windowStart]/[windowEnd] bound the range that was actually queried on
/// the device side. They gate ONLY the "linked appointment missing on
/// device -> deleteLocal" decision: if a linked appointment's own `start`
/// falls outside that window, its absence from [deviceEvents] carries no
/// information (the device query never covered that period), so it must be
/// left untouched. This is the guard that fixes the Audit 6.5 data-loss bug,
/// where the old sync() compared the window against the app's stored start
/// date and deleted appointments whose device event simply hadn't been
/// fetched.
List<SyncAction> computeSyncActions({
  required List<AppointmentSyncView> appAppointments,
  required List<SyncEventData> deviceEvents,
  required DateTime windowStart,
  required DateTime windowEnd,
}) {
  final actions = <SyncAction>[];

  final deviceByExternalId = <String, SyncEventData>{
    for (final e in deviceEvents)
      if (e.externalId != null) e.externalId!: e,
  };
  final appLinkedIds = <String>{
    for (final a in appAppointments)
      if (a.externalEventId != null) a.externalEventId!,
  };

  for (final apt in appAppointments) {
    final linkedId = apt.externalEventId;

    if (linkedId == null) {
      actions.add(SyncAction(type: SyncActionType.pushInsert, appointmentId: apt.id));
      continue;
    }

    final deviceEvent = deviceByExternalId[linkedId];
    if (deviceEvent == null) {
      final inWindow =
          !apt.start.isBefore(windowStart) && apt.start.isBefore(windowEnd);
      if (inWindow) {
        actions.add(SyncAction(
          type: SyncActionType.deleteLocal,
          appointmentId: apt.id,
          externalId: linkedId,
        ));
      }
      continue;
    }

    if (sameContent(apt, deviceEvent)) {
      actions.add(SyncAction(
        type: SyncActionType.none,
        appointmentId: apt.id,
        externalId: linkedId,
      ));
    } else {
      actions.add(SyncAction(
        type: apt.isAppOrigin ? SyncActionType.pushUpdate : SyncActionType.pullUpdate,
        appointmentId: apt.id,
        externalId: linkedId,
      ));
    }
  }

  for (final event in deviceEvents) {
    final id = event.externalId;
    if (id == null || appLinkedIds.contains(id)) continue;
    actions.add(SyncAction(type: SyncActionType.pullInsert, externalId: id));
  }

  return actions;
}
