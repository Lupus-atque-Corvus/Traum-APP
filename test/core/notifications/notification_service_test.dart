import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/notifications/notification_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('medicationReminderId', () {
    test('is deterministic for the same medication and time slot', () {
      expect(NotificationService.medicationReminderId(7, 0),
          NotificationService.medicationReminderId(7, 0));
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
          final id =
              NotificationService.medicationReminderId(medicationId, slot);
          expect(fixedIds.contains(id), isFalse,
              reason: 'medicationReminderId($medicationId, $slot) = $id '
                  'collides with a fixed reminder id');
        }
      }
    });
  });

  group('hasPermission', () {
    const channel =
        MethodChannel('flutter.baseflow.com/permissions/methods');
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

    tearDown(() {
      messenger.setMockMethodCallHandler(channel, null);
    });

    test('returns true when the OS reports the permission as granted',
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async {
        expect(call.method, 'checkPermissionStatus');
        return 1; // PermissionStatus.granted
      });
      expect(await NotificationService.hasPermission(), isTrue);
    });

    test('returns false when the OS reports the permission as denied',
        () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 0);
      expect(await NotificationService.hasPermission(), isFalse);
    });

    test('returns false when permanently denied', () async {
      messenger.setMockMethodCallHandler(channel, (call) async => 4);
      expect(await NotificationService.hasPermission(), isFalse);
    });
  });
}
