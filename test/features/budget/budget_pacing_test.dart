import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/budget/budget_providers.dart';

void main() {
  test('pacingLeftFraction uses configured monthDay over real days-in-month', () {
    // kBudgetMonthDay defaults to 21 per spec §10.5
    expect(pacingLeftFraction(30), closeTo(21 / 30, 1e-9));
    expect(pacingLeftFraction(31), closeTo(21 / 31, 1e-9));
  });

  test('pacingLeftFraction clamps to [0,1]', () {
    expect(pacingLeftFraction(10), 1.0); // 21/10 -> clamped
  });

  test('kShowBudgetPacing default is true', () {
    expect(kShowBudgetPacing, isTrue);
  });
}
