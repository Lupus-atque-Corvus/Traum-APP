import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/features/home/home_widget_registry.dart';

void main() {
  test('nextSize cycles through all five sizes and returns to start', () {
    var s = HomeTileSize.small;
    final seen = <HomeTileSize>{s};
    for (var i = 0; i < HomeTileSize.values.length - 1; i++) {
      s = nextSize(HomeWidgetType.water, s);
      seen.add(s);
    }
    expect(seen.length, HomeTileSize.values.length); // all distinct
    expect(nextSize(HomeWidgetType.water, s), HomeTileSize.small); // wraps
  });

  test('group label covers all groups', () {
    for (final g in HomeWidgetGroup.values) {
      expect(homeWidgetGroupLabel(g), isNotEmpty);
    }
  });
}
