import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/budget/budget_stats_screen.dart';

void main() {
  test('buildDonutSlices fractions sum to 1 and sort desc', () {
    final slices = buildDonutSlices({1: 850, 2: 412, 3: 238}, const []);
    final total = slices.fold(0.0, (s, x) => s + x.fraction);
    expect(total, closeTo(1.0, 1e-9));
    expect(slices.first.amount, 850); // largest first
  });
}
