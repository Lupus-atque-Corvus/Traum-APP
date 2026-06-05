import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/navigation/tab_switcher_index.dart';

void main() {
  group('switcherIndexFor', () {
    test('no movement keeps start index', () {
      expect(switcherIndexFor(dx: 0, startIndex: 3, count: 10), 3);
    });

    test('steps forward by whole steps of `step` px', () {
      expect(switcherIndexFor(dx: 64, startIndex: 2, count: 10, step: 32), 4);
    });

    test('steps backward for negative dx', () {
      expect(switcherIndexFor(dx: -96, startIndex: 5, count: 10, step: 32), 2);
    });

    test('rounds to nearest step', () {
      expect(switcherIndexFor(dx: 48, startIndex: 0, count: 10, step: 32), 2);
      expect(switcherIndexFor(dx: 40, startIndex: 0, count: 10, step: 32), 1);
    });

    test('clamps at the upper end', () {
      expect(switcherIndexFor(dx: 10000, startIndex: 8, count: 10, step: 32), 9);
    });

    test('clamps at the lower end', () {
      expect(switcherIndexFor(dx: -10000, startIndex: 2, count: 10, step: 32), 0);
    });

    test('count <= 0 returns 0', () {
      expect(switcherIndexFor(dx: 100, startIndex: 0, count: 0, step: 32), 0);
    });
  });
}
