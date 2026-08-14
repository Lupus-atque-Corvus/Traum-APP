import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('medicationReminderId', () {
    test('is deterministic for the same medication and time slot', () {
      expect(
        NotificationService.medicationReminderId(7, 0),
        NotificationService.medicationReminderId(7, 0),
      );
    });

    test('differs between two medications at the same time-of-day slot '
        '(regression: previously both used id = 100 + slotIndex and '
        'collided)', () {
      final medA = NotificationService.medicationReminderId(1, 0);
      final medB = NotificationService.medicationReminderId(2, 0);
      expect(medA, isNot(equals(medB)));
    });

    test('differs between two time slots of the same medication', () {
      final slot0 = NotificationService.medicationReminderId(5, 0);
      final slot1 = NotificationService.medicationReminderId(5, 1);
      expect(slot0, isNot(equals(slot1)));
    });

    test('never collides with the fixed settings-driven reminder ids '
        '(1-7) for any realistic medication id/slot', () {
      const fixedIds = {1, 2, 3, 4, 5, 6, 7};
      for (var medicationId = 1; medicationId <= 50; medicationId++) {
        for (var slot = 0; slot < 5; slot++) {
          final id = NotificationService.medicationReminderId(
            medicationId,
            slot,
          );
          expect(
            fixedIds.contains(id),
            isFalse,
            reason:
                'medicationReminderId($medicationId, $slot) = $id '
                'collides with a fixed reminder id',
          );
        }
      }
    });

    test('differs across weekdays for the same medication/slot — each '
        'selected weekday needs its own recurring alarm', () {
      final everyDay = NotificationService.medicationReminderId(3, 0);
      final monday = NotificationService.medicationReminderId(3, 0, 1);
      final tuesday = NotificationService.medicationReminderId(3, 0, 2);
      final ids = {everyDay, monday, tuesday};
      expect(
        ids,
        hasLength(3),
        reason:
            'every-day and per-weekday ids must '
            'all be distinct: $ids',
      );
    });

    test(
      'defaults to the every-day id (weekday 0) when weekday is omitted',
      () {
        expect(
          NotificationService.medicationReminderId(3, 0),
          NotificationService.medicationReminderId(3, 0, 0),
        );
      },
    );
  });

  group('supplementReminderId', () {
    test('never collides with medicationReminderId for any realistic '
        'medication/supplement id, slot, and weekday', () {
      final medicationIds = <int>{};
      for (var id = 1; id <= 100; id++) {
        for (var slot = 0; slot < 9; slot++) {
          for (var weekday = 0; weekday <= 7; weekday++) {
            medicationIds.add(
              NotificationService.medicationReminderId(id, slot, weekday),
            );
          }
        }
      }
      for (var id = 1; id <= 100; id++) {
        for (var slot = 0; slot < 9; slot++) {
          for (var weekday = 0; weekday <= 7; weekday++) {
            final suppId = NotificationService.supplementReminderId(
              id,
              slot,
              weekday,
            );
            expect(
              medicationIds.contains(suppId),
              isFalse,
              reason:
                  'supplementReminderId($id, $slot, $weekday) = '
                  '$suppId collides with a medication reminder id',
            );
          }
        }
      }
    });
  });

  group('hasPermission', () {
    const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test(
      'returns true when the OS reports the permission as granted',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'checkPermissionStatus');
          return 1; // PermissionStatus.granted
        });
        expect(await NotificationService.hasPermission(), isTrue);
      },
    );

    test(
      'returns false when the OS reports the permission as denied',
      () async {
        messenger.setMockMethodCallHandler(channel, (call) async => 0);
        expect(await NotificationService.hasPermission(), isFalse);
      },
    );

    test('returns false when permanently denied', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 4);
      expect(await NotificationService.hasPermission(), isFalse);
    });
  });
}
