import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/navigation/tab_switcher_index.dart';

void main() {
  group('switcherIndexFor (distance acceleration)', () {
    test('no movement keeps start index', () {
      expect(switcherIndexFor(dx: 0, startIndex: 3, count: 10), 3);
    });

    test('precise gear: 1 tab per base px below threshold', () {
      expect(switcherIndexFor(dx: 24, startIndex: 0, count: 20), 1);
      expect(switcherIndexFor(dx: 48, startIndex: 0, count: 20), 2);
      expect(switcherIndexFor(dx: 96, startIndex: 0, count: 20), 4); // at threshold
    });

    test('fast gear accelerates beyond threshold', () {
      // 96 -> 4 tabs; +24px / 10 = 2.4 -> round(6.4) = 6
      expect(switcherIndexFor(dx: 120, startIndex: 0, count: 20), 6);
      // 96 -> 4 tabs; +50px / 10 = 5 -> 9
      expect(switcherIndexFor(dx: 146, startIndex: 0, count: 20), 9);
    });

    test('works backward (negative dx)', () {
      expect(switcherIndexFor(dx: -96, startIndex: 8, count: 20), 4);
    });

    test('clamps at the upper end', () {
      expect(switcherIndexFor(dx: 10000, startIndex: 8, count: 10), 9);
    });

    test('clamps at the lower end', () {
      expect(switcherIndexFor(dx: -10000, startIndex: 2, count: 10), 0);
    });

    test('count <= 0 returns 0', () {
      expect(switcherIndexFor(dx: 100, startIndex: 0, count: 0), 0);
    });

    test('clamps an out-of-range high startIndex', () {
      expect(switcherIndexFor(dx: 0, startIndex: 99, count: 5), 4);
    });

    test('clamps a negative startIndex', () {
      expect(switcherIndexFor(dx: 0, startIndex: -1, count: 5), 0);
    });
  });
}
