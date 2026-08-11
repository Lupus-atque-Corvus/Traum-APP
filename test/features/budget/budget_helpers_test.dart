import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/budget/budget_helpers.dart';

void main() {
  group('fmtAmount', () {
    test('formats a typical amount with German thousands/decimal separators',
        () {
      expect(fmtAmount(1234.5), '1.234,50');
    });

    test('formats a small amount without a thousands separator', () {
      expect(fmtAmount(9.99), '9,99');
    });

    test('formats zero', () {
      expect(fmtAmount(0), '0,00');
    });

    // Regression test: a fat-fingered numpad amount (e.g. 1e44) made
    // toStringAsFixed(2) switch to scientific notation ("1e+44", no decimal
    // point at all), which crashed fmtAmount with a RangeError when it
    // unconditionally accessed index 1 of the comma-split result.
    test('does not throw for an extreme magnitude that toStringAsFixed '
        'renders in scientific notation', () {
      expect(() => fmtAmount(1e44), returnsNormally);
      expect(fmtAmount(1e44), isNotEmpty);
    });

    test('does not throw for a negative extreme magnitude', () {
      expect(() => fmtAmount(-1e44), returnsNormally);
    });
  });
}
