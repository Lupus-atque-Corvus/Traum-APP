import 'package:flutter_test/flutter_test.dart';
import 'package:traum/features/graffiti_map/photo_grouping.dart';

PhotoPoint p(int id, int marker, double lat, double lon, int min) => PhotoPoint(
      id: id,
      markerId: marker,
      lat: lat,
      lon: lon,
      createdAt: DateTime(2026, 1, 1, 0, min),
    );

void main() {
  test('empty input yields no clusters', () {
    expect(groupPhotos(const [], 50), isEmpty);
  });

  test('single photo: one cluster hosted by its marker', () {
    final c = groupPhotos([p(1, 10, 52.52, 13.405, 0)], 50);
    expect(c.length, 1);
    expect(c.single.hostMarkerId, 10);
    expect(c.single.photos.single.id, 1);
  });

  test('two near photos from different markers merge; host has more photos', () {
    final c = groupPhotos([
      p(1, 10, 52.5200, 13.4050, 0),
      p(2, 10, 52.5200, 13.4051, 1),
      p(3, 20, 52.5201, 13.4050, 2),
    ], 80);
    expect(c.length, 1);
    expect(c.single.hostMarkerId, 10);
    expect(c.single.photos.length, 3);
  });

  test('two far photos from same marker split into two clusters', () {
    final c = groupPhotos([
      p(1, 10, 52.5200, 13.4050, 0),
      p(2, 10, 48.1351, 11.5820, 1),
    ], 50);
    expect(c.length, 2);
    final hosts = c.map((g) => g.hostMarkerId).toList();
    expect(hosts.contains(10), isTrue);
    expect(hosts.contains(null), isTrue);
  });
}
