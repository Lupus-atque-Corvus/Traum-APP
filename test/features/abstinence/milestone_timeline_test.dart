import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/abstinence/widgets/milestone_timeline.dart';

void main() {
  final start = DateTime(2026, 1, 1, 0, 0, 0);
  final milestones = [
    const Milestone('24 Stunden', Duration(hours: 24)),
    const Milestone('1 Woche', Duration(days: 7)),
    const Milestone('1 Monat', Duration(days: 30)),
  ];

  group('computeMilestones', () {
    test('a milestone exactly reached on the boundary counts as reached', () {
      final now = start.add(const Duration(hours: 24));
      final result = computeMilestones(start, milestones, now);
      final first = result.firstWhere((s) => s.milestone.label == '24 Stunden');
      expect(first.reached, isTrue);
      expect(first.remaining, isNull);
    });

    test('a milestone just missed (1 second short) is not reached', () {
      final now = start.add(const Duration(hours: 24) - const Duration(seconds: 1));
      final result = computeMilestones(start, milestones, now);
      final first = result.firstWhere((s) => s.milestone.label == '24 Stunden');
      expect(first.reached, isFalse);
      expect(first.remaining, const Duration(seconds: 1));
    });

    test('marks exactly one current milestone: the nearest not-yet-reached', () {
      // 3 days elapsed: 24h milestone reached, 1 week is current, 1 month is future.
      final now = start.add(const Duration(days: 3));
      final result = computeMilestones(start, milestones, now);

      final day1 = result.firstWhere((s) => s.milestone.label == '24 Stunden');
      final week1 = result.firstWhere((s) => s.milestone.label == '1 Woche');
      final month1 = result.firstWhere((s) => s.milestone.label == '1 Monat');

      expect(day1.reached, isTrue);
      expect(day1.isCurrent, isFalse);

      expect(week1.reached, isFalse);
      expect(week1.isCurrent, isTrue);
      expect(week1.remaining, const Duration(days: 4));

      expect(month1.reached, isFalse);
      expect(month1.isCurrent, isFalse);

      // exactly one current milestone
      expect(result.where((s) => s.isCurrent).length, 1);
    });

    test('no milestone is current once all are reached', () {
      final now = start.add(const Duration(days: 400));
      final result = computeMilestones(start, milestones, now);
      expect(result.every((s) => s.reached), isTrue);
      expect(result.any((s) => s.isCurrent), isFalse);
      expect(result.every((s) => s.remaining == null), isTrue);
    });

    test('at the very start (elapsed = 0), the smallest milestone is current', () {
      final result = computeMilestones(start, milestones, start);
      expect(result.first.isCurrent, isTrue);
      expect(result.first.reached, isFalse);
    });

    test('returns milestones sorted ascending by duration regardless of input order', () {
      final unsorted = [milestones[2], milestones[0], milestones[1]];
      final result = computeMilestones(start, unsorted, start);
      expect(result.map((s) => s.milestone.duration).toList(), [
        milestones[0].duration,
        milestones[1].duration,
        milestones[2].duration,
      ]);
    });
  });

  group('formatMilestoneRemaining', () {
    test('formats >= 1 day remaining as "in N T"', () {
      expect(formatMilestoneRemaining(const Duration(days: 4)), 'in 4 T');
      expect(formatMilestoneRemaining(const Duration(days: 1, hours: 5)), 'in 1 T');
    });

    test('formats < 1 day but >= 1 hour remaining as hours', () {
      expect(formatMilestoneRemaining(const Duration(hours: 5)), 'in 5 Std.');
    });

    test('formats sub-hour remaining as "bald"', () {
      expect(formatMilestoneRemaining(const Duration(minutes: 30)), 'bald');
    });
  });
}
