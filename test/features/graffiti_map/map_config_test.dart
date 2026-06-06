import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/graffiti_map/map_config.dart';

void main() {
  group('groupRadiusFromConfig', () {
    test('reads groupRadius from JSON', () {
      expect(groupRadiusFromConfig('{"groupRadius":100}'), 100);
    });
    test('defaults to 50 when missing', () {
      expect(groupRadiusFromConfig('{"rating":true}'), 50);
    });
    test('defaults to 50 on invalid JSON', () {
      expect(groupRadiusFromConfig('not json'), 50);
    });
  });

  group('nearestMarkerWithin', () {
    final pts = <(int, double, double)>[
      (1, 52.5200, 13.4050), // Berlin
      (2, 48.1351, 11.5820), // Munich
    ];
    test('returns id within radius', () {
      final id = nearestMarkerWithin(pts, 52.5200, 13.40559, 50);
      expect(id, 1);
    });
    test('returns null when nothing within radius', () {
      final id = nearestMarkerWithin(pts, 50.0, 8.0, 50);
      expect(id, isNull);
    });
    test('returns null for empty list', () {
      expect(nearestMarkerWithin(const [], 52.52, 13.405, 50), isNull);
    });
  });
}
