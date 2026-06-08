import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';
import 'package:traum/features/home/home_widget_registry.dart';

void main() {
  test('nextSize returns current when type unregistered', () {
    expect(nextSize(HomeWidgetType.water, HomeTileSize.small),
        HomeTileSize.small);
  });

  test('group label covers all groups', () {
    for (final g in HomeWidgetGroup.values) {
      expect(homeWidgetGroupLabel(g), isNotEmpty);
    }
  });
}
