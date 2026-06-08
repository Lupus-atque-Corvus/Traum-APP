import 'package:drift/drift.dart' show Value;
import '../../data/database/traum_database.dart';
import 'photo_grouping.dart';

/// Gruppiert alle Fotos einer Collection anhand [radiusMeters] neu.
///
/// Host-Marker behalten ihre Metadaten; verschmolzene Nebenmarker werden
/// gelöscht; beim Verkleinern entstehende Cluster werden zu neuen Punkten.
/// Bewusst fotolose Punkte (nie ein Foto gehabt) bleiben unberührt.
Future<void> regroupCollection(
    TraumDatabase db, int collectionId, double radiusMeters) async {
  final markers = await db.mapMarkersDao.getByCollection(collectionId);
  final photos = await db.markerPhotosDao.getByCollection(collectionId);
  if (photos.isEmpty) return;

  final markerById = {for (final m in markers) m.id: m};
  final points = <PhotoPoint>[];
  for (final p in photos) {
    final lat = p.latitude ?? markerById[p.markerId]?.latitude;
    final lon = p.longitude ?? markerById[p.markerId]?.longitude;
    if (lat == null || lon == null) continue;
    points.add(PhotoPoint(
      id: p.id,
      markerId: p.markerId,
      lat: lat,
      lon: lon,
      createdAt: p.createdAt,
    ));
  }
  if (points.isEmpty) return;

  final clusters = groupPhotos(points, radiusMeters);

  await db.transaction(() async {
    final keptHosts = <int>{};
    for (final c in clusters) {
      int hostId;
      if (c.hostMarkerId != null) {
        hostId = c.hostMarkerId!;
        final host = markerById[hostId]!;
        await db.mapMarkersDao.updateMarker(host.copyWith(
          latitude: Value(c.centerLat),
          longitude: Value(c.centerLon),
        ));
      } else {
        hostId = await db.mapMarkersDao.insert(MapMarkersCompanion.insert(
          collectionId: collectionId,
          latitude: Value(c.centerLat),
          longitude: Value(c.centerLon),
          createdAt: DateTime.now(),
        ));
      }
      keptHosts.add(hostId);
      for (final p in c.photos) {
        if (p.markerId != hostId) {
          await db.markerPhotosDao.moveToMarker(p.id, hostId);
        }
      }
    }
    // Marker löschen, die zuvor Fotos hatten, jetzt aber keine mehr und nicht Host sind.
    for (final m in markers) {
      if (keptHosts.contains(m.id)) continue;
      final hadPhotos = photos.any((p) => p.markerId == m.id);
      if (!hadPhotos) continue; // bewusst fotoloser Punkt
      final remaining = await db.markerPhotosDao.getByMarker(m.id);
      if (remaining.isEmpty) {
        await db.mapMarkersDao.deleteMarker(m.id);
      }
    }
  });
}
