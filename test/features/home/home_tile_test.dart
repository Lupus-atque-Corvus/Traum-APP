import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/home/home_tile.dart';

void main() {
  test('HomeTile JSON round-trip', () {
    const t = HomeTile(type: HomeWidgetType.water, size: HomeTileSize.wide);
    final back = HomeTile.fromJson(t.toJson());
    expect(back.type, HomeWidgetType.water);
    expect(back.size, HomeTileSize.wide);
  });

  test('encode/decode list round-trip', () {
    const list = [
      HomeTile(type: HomeWidgetType.clockDate, size: HomeTileSize.wide),
      HomeTile(type: HomeWidgetType.steps, size: HomeTileSize.small),
    ];
    final decoded = decodeHomeLayout(encodeHomeLayout(list));
    expect(decoded.length, 2);
    expect(decoded.first.type, HomeWidgetType.clockDate);
  });

  test('decode skips unknown types', () {
    final decoded = decodeHomeLayout(
        '[{"type":"water","size":"small"},{"type":"___gone___","size":"small"}]');
    expect(decoded.length, 1);
    expect(decoded.single.type, HomeWidgetType.water);
  });

  test('defaultHomeLayout is non-empty and starts with clockDate', () {
    final d = defaultHomeLayout();
    expect(d, isNotEmpty);
    expect(d.first.type, HomeWidgetType.clockDate);
  });

  test('HomeWidgetType has 68 values', () {
    expect(HomeWidgetType.values.length, 68);
  });
}
