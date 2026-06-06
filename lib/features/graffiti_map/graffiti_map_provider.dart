import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/providers/database_provider.dart';
import '../../data/database/traum_database.dart';

// ─── DAO-Provider ───────────────────────────────────────────────────────────
final mapCollectionsDaoProvider = Provider<MapCollectionsDao>(
    (ref) => ref.watch(databaseProvider).mapCollectionsDao);

final mapMarkersDaoProvider = Provider<MapMarkersDao>(
    (ref) => ref.watch(databaseProvider).mapMarkersDao);

final markerPhotosDaoProvider = Provider<MarkerPhotosDao>(
    (ref) => ref.watch(databaseProvider).markerPhotosDao);

// ─── Modelle ────────────────────────────────────────────────────────────────
class MarkerWithPhotos {
  final MapMarker marker;
  final List<MarkerPhoto> photos;
  const MarkerWithPhotos({required this.marker, required this.photos});
  MarkerPhoto? get firstPhoto => photos.isNotEmpty ? photos.first : null;
}

// ─── State ──────────────────────────────────────────────────────────────────
/// Aktiv gewählte Karte (Collection-ID). Default 1 = erste geseedete Karte.
final activeCollectionProvider = StateProvider<int>((ref) => 1);

/// Aktiver Hashtag-Filter (oder null).
final activeHashtagFilterProvider = StateProvider<String?>((ref) => null);

// ─── Daten-Provider ─────────────────────────────────────────────────────────
final mapCollectionsProvider =
    FutureProvider<List<MapCollection>>((ref) =>
        ref.watch(mapCollectionsDaoProvider).getAll());

final activeCollectionInfoProvider =
    FutureProvider<MapCollection?>((ref) {
  final id = ref.watch(activeCollectionProvider);
  return ref.watch(mapCollectionsDaoProvider).getById(id);
});

final collectionByIdProvider =
    FutureProvider.family<MapCollection?, int>((ref, id) =>
        ref.watch(mapCollectionsDaoProvider).getById(id));

Future<List<MarkerWithPhotos>> _withPhotos(
    Ref ref, List<MapMarker> markers) async {
  final photosDao = ref.watch(markerPhotosDaoProvider);
  final result = <MarkerWithPhotos>[];
  for (final m in markers) {
    result.add(MarkerWithPhotos(
        marker: m, photos: await photosDao.getByMarker(m.id)));
  }
  return result;
}

final activeMarkersProvider =
    FutureProvider<List<MarkerWithPhotos>>((ref) async {
  final id = ref.watch(activeCollectionProvider);
  final markers = await ref.watch(mapMarkersDaoProvider).getByCollection(id);
  return _withPhotos(ref, markers);
});

final markerSearchProvider = FutureProvider.family<List<MarkerWithPhotos>,
    String>((ref, query) async {
  final id = ref.watch(activeCollectionProvider);
  final dao = ref.watch(mapMarkersDaoProvider);
  final markers = query.isEmpty
      ? await dao.getByCollection(id)
      : await dao.search(id, query);
  return _withPhotos(ref, markers);
});

final markerByIdProvider =
    FutureProvider.family<MarkerWithPhotos?, int>((ref, id) async {
  final marker = await ref.watch(mapMarkersDaoProvider).getById(id);
  if (marker == null) return null;
  final photos = await ref.watch(markerPhotosDaoProvider).getByMarker(id);
  return MarkerWithPhotos(marker: marker, photos: photos);
});

final allHashtagsProvider = FutureProvider<List<String>>((ref) async {
  final id = ref.watch(activeCollectionProvider);
  final markers = await ref.watch(mapMarkersDaoProvider).getByCollection(id);
  final tags = <String>{};
  for (final m in markers) {
    if (m.hashtags.isNotEmpty) {
      tags.addAll(m.hashtags
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty));
    }
  }
  return tags.toList()..sort();
});
