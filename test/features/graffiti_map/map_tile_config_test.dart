import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/graffiti_map/map_tile_config.dart';

void main() {
  test('standard mode: CartoDB Voyager url + CARTO attribution', () {
    final urls = tileUrlTemplatesFor(MapViewMode.standard);
    expect(urls.length, 1);
    expect(urls.first, contains('cartocdn.com'));
    expect(urls.first, contains('voyager'));
    expect(mapModeAttribution(MapViewMode.standard), contains('OpenStreetMap'));
    expect(mapModeAttribution(MapViewMode.standard), contains('CARTO'));
  });

  test('satellite mode: one Esri imagery url, Esri attribution', () {
    final urls = tileUrlTemplatesFor(MapViewMode.satellite);
    expect(urls.length, 1);
    expect(urls.first, contains('World_Imagery'));
    expect(urls.first, contains('{z}/{y}/{x}'));
    expect(mapModeAttribution(MapViewMode.satellite), contains('Esri'));
  });

  test('hybrid mode: imagery base + label overlay', () {
    final urls = tileUrlTemplatesFor(MapViewMode.hybrid);
    expect(urls.length, 2);
    expect(urls[0], contains('World_Imagery'));
    expect(urls[1], contains('World_Boundaries_and_Places'));
    expect(mapModeAttribution(MapViewMode.hybrid), contains('Esri'));
  });

  test('mapModeLabel returns the short label per mode', () {
    expect(mapModeLabel(MapViewMode.standard), 'Standard');
    expect(mapModeLabel(MapViewMode.satellite), 'Satellit');
    expect(mapModeLabel(MapViewMode.hybrid), 'Hybrid');
  });
}
