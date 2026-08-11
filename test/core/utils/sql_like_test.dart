import 'package:flutter_test/flutter_test.dart';
import 'package:traum/core/utils/sql_like.dart';

void main() {
  group('escapeLikePattern', () {
    test('leaves plain text unchanged', () {
      expect(escapeLikePattern('hello'), 'hello');
    });

    test('escapes the percent wildcard', () {
      expect(escapeLikePattern('50%'), r'50\%');
    });

    test('escapes the underscore wildcard', () {
      expect(escapeLikePattern('a_b'), r'a\_b');
    });

    test('escapes the escape character itself', () {
      expect(escapeLikePattern(r'a\b'), r'a\\b');
    });

    // Regression test: a search field passed straight to `LIKE '%$query%'`
    // let a query of just "%" (or "%%_%") match every row, since unescaped
    // wildcards in user input are interpreted by SQLite rather than matched
    // literally.
    test('a query of only wildcard characters becomes a literal pattern',
        () {
      expect(escapeLikePattern('%%_%'), r'\%\%\_\%');
    });
  });
}
