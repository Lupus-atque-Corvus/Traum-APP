import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/utils/validators.dart';

void main() {
  group('parseLocaleAmount', () {
    test('parses comma as decimal separator', () {
      expect(parseLocaleAmount('12,50'), 12.5);
    });

    test('parses a plain dot-decimal value unchanged', () {
      expect(parseLocaleAmount('12.50'), 12.5);
    });

    test('trims surrounding whitespace', () {
      expect(parseLocaleAmount('  9,5  '), 9.5);
    });

    test('returns null for empty input', () {
      expect(parseLocaleAmount(''), isNull);
    });

    test('returns null for non-numeric input', () {
      expect(parseLocaleAmount('abc'), isNull);
    });

    test('parses a bare integer', () {
      expect(parseLocaleAmount('7'), 7.0);
    });
  });
}
