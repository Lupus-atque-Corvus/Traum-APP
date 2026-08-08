import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
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

/// Lädt Fotos für alle übergebenen Marker in einer einzigen Query (statt
/// einer Query pro Marker) — bei sehr großen Collections (z.B. hundert-
/// tausende importierte Türme) macht eine Query pro Marker die Kartenansicht
/// praktisch unbenutzbar.
Future<List<MarkerWithPhotos>> _withPhotos(
    Ref ref, List<MapMarker> markers) async {
  final photosDao = ref.watch(markerPhotosDaoProvider);
  final photosByMarker =
      await photosDao.getByMarkerIds(markers.map((m) => m.id).toList());
  return markers
      .map((m) => MarkerWithPhotos(
          marker: m, photos: photosByMarker[m.id] ?? const []))
      .toList();
}

/// Invalidiert **alle** Provider, die von den Markern der aktiven Karte
/// abgeleitet sind — Karte, Galerie, Hashtag-Leiste und Kartenzentrierung.
///
/// Bewusst eine einzige Stelle: vorher invalidierte jeder Aufrufer von Hand
/// eine eigene Teilmenge. Als die Galerie in v0.8.6 auf
/// [galleryMarkersProvider] umgestellt wurde, zeigten dadurch mehrere Stellen
/// nach Löschen/Bearbeiten/Verschieben eines Markers veraltete Daten an, weil
/// sie noch den inzwischen von niemandem beobachteten Vorgänger-Provider
/// invalidierten.
void invalidateMarkerViews(WidgetRef ref) {
  ref.invalidate(markersInViewportProvider);
  ref.invalidate(galleryMarkersProvider);
  ref.invalidate(mostRecentMarkerProvider);
  ref.invalidate(allHashtagsProvider);
}

/// Lat/Lon-Rechteck des aktuell sichtbaren Kartenausschnitts.
class MapBounds {
  final double minLat;
  final double maxLat;
  final double minLon;
  final double maxLon;
  const MapBounds({
    required this.minLat,
    required this.maxLat,
    required this.minLon,
    required this.maxLon,
  });

  @override
  bool operator ==(Object other) =>
      other is MapBounds &&
      minLat == other.minLat &&
      maxLat == other.maxLat &&
      minLon == other.minLon &&
      maxLon == other.maxLon;

  @override
  int get hashCode => Object.hash(minLat, maxLat, minLon, maxLon);
}

/// Aktueller Kartenausschnitt — von der Karte bei Pan/Zoom aktualisiert
/// (entprellt). `null` bis zum ersten Kamera-Update.
final mapViewportBoundsProvider = StateProvider<MapBounds?>((ref) => null);

/// Marker der aktiven Collection, begrenzt auf den aktuellen Kartenausschnitt
/// (+ harte Obergrenze in der DAO-Query). Das ist die einzige Quelle, die an
/// den Cluster-Layer der Karte übergeben werden darf — `activeMarkersProvider`
/// lädt die komplette Collection unbegrenzt und ist bei sehr großen
/// Collections (Türme: hunderttausende Marker) dafür ungeeignet.
final markersInViewportProvider =
    FutureProvider<List<MarkerWithPhotos>>((ref) async {
  final id = ref.watch(activeCollectionProvider);
  final bounds = ref.watch(mapViewportBoundsProvider);
  if (bounds == null) return const [];
  final markers = await ref.watch(mapMarkersDaoProvider).getByCollectionInBounds(
        id,
        minLat: bounds.minLat,
        maxLat: bounds.maxLat,
        minLon: bounds.minLon,
        maxLon: bounds.maxLon,
      );
  return _withPhotos(ref, markers);
});

/// Zuletzt erstellter Marker der aktiven Collection — billige Alternative zu
/// `activeMarkersProvider.first` für die initiale Kartenzentrierung, wenn die
/// Collection sehr groß ist.
final mostRecentMarkerProvider = FutureProvider<MapMarker?>((ref) {
  final id = ref.watch(activeCollectionProvider);
  return ref.watch(mapMarkersDaoProvider).getMostRecentByCollection(id);
});

// autoDispose: every distinct query string typed while searching creates a
// new provider instance keyed on that string — without autoDispose those
// instances (and their cached marker lists) never get garbage-collected for
// the lifetime of the app, growing unbounded with every keystroke.
final markerSearchProvider = FutureProvider.autoDispose
    .family<List<MarkerWithPhotos>, String>((ref, query) async {
  final id = ref.watch(activeCollectionProvider);
  final dao = ref.watch(mapMarkersDaoProvider);
  // Beide Zweige begrenzt: bei leerer Suche würde sonst die komplette
  // Collection geladen, bei kurzen Suchbegriffen zehntausende Treffer.
  final markers = query.isEmpty
      ? await dao.getRecentByCollection(id)
      : await dao.search(id, query);
  return _withPhotos(ref, markers);
});

/// Marker für die Galerie-Ansicht — begrenzte, nach Datum absteigende Liste.
/// Bewusst NICHT [activeMarkersProvider]: der lädt die komplette Collection
/// (bei den importierten Karten hunderttausende Zeilen samt Foto-Abfrage),
/// bevor überhaupt die erste Kachel erscheinen kann.
final galleryMarkersProvider =
    FutureProvider<List<MarkerWithPhotos>>((ref) async {
  final id = ref.watch(activeCollectionProvider);
  final markers =
      await ref.watch(mapMarkersDaoProvider).getRecentByCollection(id);
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
  // Nur die Hashtag-Spalte nicht-leerer Zeilen laden statt aller Marker samt
  // aller Spalten — bei den importierten Collections (413k Türme, 82k Lost
  // Places, alle ohne Hashtags) ist das der Unterschied zwischen „lädt
  // hunderttausende Zeilen" und „liefert praktisch sofort nichts zurück".
  final raw =
      await ref.watch(mapMarkersDaoProvider).hashtagStringsForCollection(id);
  final tags = <String>{};
  for (final h in raw) {
    tags.addAll(
        h.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty));
  }
  return tags.toList()..sort();
});
