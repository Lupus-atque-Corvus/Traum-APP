import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/repositories/overpass_tower_repository.dart';

void main() {
  test('parses a full node with all tags', () {
    final json = {
      'elements': [
        {
          'type': 'node',
          'id': 123456789,
          'lat': 52.5,
          'lon': 13.4,
          'tags': {
            'man_made': 'mast',
            'tower:type': 'communication',
            'name': 'Funkmast Nord',
            'height': '45',
            'operator': 'Telekom',
          },
        },
      ],
    };
    final results = parseOverpassResponse(json);
    final r = results.single;
    expect(r.osmId, 'node/123456789');
    expect(r.latitude, 52.5);
    expect(r.longitude, 13.4);
    expect(r.name, 'Funkmast Nord');
    expect(r.towerType, 'communication');
    expect(r.heightMeters, '45');
    expect(r.operatorName, 'Telekom');
  });

  test('parses a node with missing optional tags', () {
    final json = {
      'elements': [
        {'type': 'node', 'id': 1, 'lat': 1.0, 'lon': 2.0},
      ],
    };
    final r = parseOverpassResponse(json).single;
    expect(r.osmId, 'node/1');
    expect(r.name, isNull);
    expect(r.towerType, isNull);
    expect(r.heightMeters, isNull);
    expect(r.operatorName, isNull);
  });

  test('skips elements without lat/lon', () {
    final json = {
      'elements': [
        {'type': 'node', 'id': 1, 'tags': {}},
        {'type': 'node', 'id': 2, 'lat': 1.0},
      ],
    };
    expect(parseOverpassResponse(json), isEmpty);
  });

  test('ignores non-node elements (e.g. resolved area)', () {
    final json = {
      'elements': [
        {'type': 'area', 'id': 3600062611, 'tags': {'name': 'Bayern'}},
        {'type': 'node', 'id': 5, 'lat': 48.1, 'lon': 11.5},
      ],
    };
    final results = parseOverpassResponse(json);
    expect(results.length, 1);
    expect(results.single.osmId, 'node/5');
  });

  test('returns empty list when elements key missing or malformed', () {
    expect(parseOverpassResponse({}), isEmpty);
    expect(parseOverpassResponse({'elements': 'not a list'}), isEmpty);
  });

  test('skips malformed (non-Map) entries', () {
    final json = {
      'elements': [
        null,
        'garbage',
        {'type': 'node', 'id': 7, 'lat': 1.0, 'lon': 1.0},
      ],
    };
    expect(parseOverpassResponse(json).length, 1);
  });
}
