import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/graffiti_map/map_tile_config.dart';

void main() {
  test('standard mode: one OSM url, dark filter, OSM attribution', () {
    final urls = tileUrlTemplatesFor(MapViewMode.standard);
    expect(urls.length, 1);
    expect(urls.first, contains('tile.openstreetmap.org'));
    expect(mapModeUsesDarkFilter(MapViewMode.standard), isTrue);
    expect(mapModeAttribution(MapViewMode.standard), contains('OpenStreetMap'));
  });

  test('satellite mode: one Esri imagery url, no dark filter, Esri attribution', () {
    final urls = tileUrlTemplatesFor(MapViewMode.satellite);
    expect(urls.length, 1);
    expect(urls.first, contains('World_Imagery'));
    expect(urls.first, contains('{z}/{y}/{x}'));
    expect(mapModeUsesDarkFilter(MapViewMode.satellite), isFalse);
    expect(mapModeAttribution(MapViewMode.satellite), contains('Esri'));
  });

  test('hybrid mode: imagery base + label overlay, no dark filter', () {
    final urls = tileUrlTemplatesFor(MapViewMode.hybrid);
    expect(urls.length, 2);
    expect(urls[0], contains('World_Imagery'));
    expect(urls[1], contains('World_Boundaries_and_Places'));
    expect(mapModeUsesDarkFilter(MapViewMode.hybrid), isFalse);
  });
}
