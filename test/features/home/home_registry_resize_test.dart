import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/features/home/home_widget_registry.dart';

void main() {
  test('nextSize cycles through a widget\'s allowed sizes', () {
    final d = homeWidgetRegistry[HomeWidgetType.water]!;
    // Start from each allowed size; nextSize must stay within allowed sizes
    // and advance (different) when there is more than one allowed size.
    for (final start in d.sizes) {
      final next = nextSize(HomeWidgetType.water, start);
      expect(d.sizes.contains(next), isTrue);
      if (d.sizes.length > 1) expect(next, isNot(start));
    }
  });

  test('nextSize is a no-op for a single allowed size', () {
    // moonCalendar-style single-size widgets stay put. Find one with 1 size.
    final single = homeWidgetRegistry.entries
        .firstWhere((e) => e.value.sizes.length == 1);
    final only = single.value.sizes.first;
    expect(nextSize(single.key, only), only);
  });

  test('group label covers all groups', () {
    for (final g in HomeWidgetGroup.values) {
      expect(homeWidgetGroupLabel(g), isNotEmpty);
    }
  });
}
