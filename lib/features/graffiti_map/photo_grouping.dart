import 'package:geolocator/geolocator.dart';

/// Ein Foto mit eigener Position für die Gruppierung.
class PhotoPoint {
  final int id;
  final int markerId;
  final double lat;
  final double lon;
  final DateTime createdAt;
  const PhotoPoint({
    required this.id,
    required this.markerId,
    required this.lat,
    required this.lon,
    required this.createdAt,
  });
}

/// Ergebnis-Cluster: zusammengehörende Fotos + gewählter Host-Marker (oder null
/// = neuer Punkt) + Schwerpunkt.
class GroupCluster {
  final List<PhotoPoint> photos;
  final int? hostMarkerId;
  final double centerLat;
  final double centerLon;
  const GroupCluster({
    required this.photos,
    required this.hostMarkerId,
    required this.centerLat,
    required this.centerLon,
  });
}

/// Clustert [photos] greedy nach [radiusMeters] und weist jedem Cluster einen
/// Host-Marker zu (der Marker mit den meisten Fotos im Cluster; jeder Marker
/// höchstens ein Cluster — sonst neuer Punkt).
List<GroupCluster> groupPhotos(List<PhotoPoint> photos, double radiusMeters) {
  if (photos.isEmpty) return const [];
  final sorted = [...photos]..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  final clusters = <List<PhotoPoint>>[];
  final cLat = <double>[];
  final cLon = <double>[];
  for (final p in sorted) {
    int best = -1;
    double bestD = double.infinity;
    for (var i = 0; i < clusters.length; i++) {
      final d = Geolocator.distanceBetween(cLat[i], cLon[i], p.lat, p.lon);
      if (d <= radiusMeters && d < bestD) {
        bestD = d;
        best = i;
      }
    }
    if (best == -1) {
      clusters.add([p]);
      cLat.add(p.lat);
      cLon.add(p.lon);
    } else {
      clusters[best].add(p);
      final n = clusters[best].length;
      cLat[best] = clusters[best].map((e) => e.lat).reduce((a, b) => a + b) / n;
      cLon[best] = clusters[best].map((e) => e.lon).reduce((a, b) => a + b) / n;
    }
  }

  final order = List.generate(clusters.length, (i) => i)
    ..sort((a, b) => clusters[b].length.compareTo(clusters[a].length));
  final usedHosts = <int>{};
  final result = List<GroupCluster?>.filled(clusters.length, null);
  for (final i in order) {
    final counts = <int, int>{};
    for (final p in clusters[i]) {
      counts[p.markerId] = (counts[p.markerId] ?? 0) + 1;
    }
    final cands = counts.keys.toList()
      ..sort((a, b) {
        final c = counts[b]!.compareTo(counts[a]!);
        return c != 0 ? c : a.compareTo(b);
      });
    int? host;
    for (final m in cands) {
      if (!usedHosts.contains(m)) {
        host = m;
        break;
      }
    }
    if (host != null) usedHosts.add(host);
    result[i] = GroupCluster(
      photos: clusters[i],
      hostMarkerId: host,
      centerLat: cLat[i],
      centerLon: cLon[i],
    );
  }
  return result.cast<GroupCluster>();
}
