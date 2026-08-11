import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/utils/search_debouncer.dart';

void main() {
  test('only the last call within the debounce window fires', () {
    fakeAsync((async) {
      final debouncer = SearchDebouncer();
      final settled = <String>[];

      debouncer('a', settled.add);
      async.elapse(const Duration(milliseconds: 100));
      debouncer('ab', settled.add);
      async.elapse(const Duration(milliseconds: 100));
      debouncer('abc', settled.add);
      async.elapse(const Duration(milliseconds: 300));

      expect(settled, ['abc']);
      debouncer.dispose();
    });
  });

  test('fires once per call when spaced beyond the debounce window', () {
    fakeAsync((async) {
      final debouncer = SearchDebouncer();
      final settled = <String>[];

      debouncer('a', settled.add);
      async.elapse(const Duration(milliseconds: 300));
      debouncer('b', settled.add);
      async.elapse(const Duration(milliseconds: 300));

      expect(settled, ['a', 'b']);
      debouncer.dispose();
    });
  });

  test('dispose cancels a pending call', () {
    fakeAsync((async) {
      final debouncer = SearchDebouncer();
      final settled = <String>[];

      debouncer('a', settled.add);
      debouncer.dispose();
      async.elapse(const Duration(milliseconds: 300));

      expect(settled, isEmpty);
    });
  });
}
