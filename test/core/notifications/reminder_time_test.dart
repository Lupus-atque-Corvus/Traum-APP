import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/notifications/reminder_time.dart';

void main() {
  group('ReminderTime.fromJson', () {
    test('parses the legacy bare-string format as an every-day reminder', () {
      final rt = ReminderTime.fromJson('08:00');
      expect(rt.time, '08:00');
      expect(rt.isEveryDay, isTrue);
      expect(rt.days, {1, 2, 3, 4, 5, 6, 7});
    });

    test('parses the structured format with explicit weekdays', () {
      final rt = ReminderTime.fromJson({
        'time': '20:00',
        'days': [1, 3, 5],
      });
      expect(rt.time, '20:00');
      expect(rt.isEveryDay, isFalse);
      expect(rt.days, {1, 3, 5});
    });

    test('an empty days list falls back to every day rather than an '
        'unschedulable reminder', () {
      final rt = ReminderTime.fromJson({'time': '09:00', 'days': <int>[]});
      expect(rt.isEveryDay, isTrue);
    });
  });

  group('parseReminderTimes / encodeReminderTimes', () {
    test('round-trips a mix of legacy and structured entries', () {
      const legacyJson = '["08:00", {"time":"20:00","days":[1,3,5]}]';
      final times = parseReminderTimes(legacyJson);
      expect(times, hasLength(2));
      expect(times[0].isEveryDay, isTrue);
      expect(times[1].days, {1, 3, 5});
    });

    test('encode then parse reproduces the same entries', () {
      final original = [
        ReminderTime.everyDay('08:00'),
        const ReminderTime(time: '14:00', days: {2, 4}),
      ];
      final roundTripped = parseReminderTimes(encodeReminderTimes(original));
      expect(roundTripped[0].time, '08:00');
      expect(roundTripped[0].isEveryDay, isTrue);
      expect(roundTripped[1].time, '14:00');
      expect(roundTripped[1].days, {2, 4});
    });

    test('malformed JSON returns an empty list rather than throwing', () {
      expect(parseReminderTimes('not json'), isEmpty);
      expect(parseReminderTimes(''), isEmpty);
    });

    test('empty array encodes/decodes to no reminders', () {
      expect(encodeReminderTimes([]), '[]');
      expect(parseReminderTimes('[]'), isEmpty);
    });
  });

  group('ReminderTime.copyWith', () {
    test('changes only the requested field', () {
      final rt = ReminderTime.everyDay('08:00');
      final retimed = rt.copyWith(time: '09:30');
      expect(retimed.time, '09:30');
      expect(retimed.days, rt.days);

      final redayed = rt.copyWith(days: {1, 2});
      expect(redayed.time, rt.time);
      expect(redayed.days, {1, 2});
    });
  });
}
