import 'package:drift/drift.dart';
import '../../../core/utils/sql_like.dart';
import '../traum_database.dart';

part 'map_markers_dao.g.dart';

@DriftAccessor(tables: [MapMarkers])
class MapMarkersDao extends DatabaseAccessor<TraumDatabase>
    with _$MapMarkersDaoMixin {
  MapMarkersDao(super.db);

  Future<List<MapMarker>> getByCollection(int collectionId) =>
      (select(mapMarkers)
            ..where((t) => t.collectionId.equals(collectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<MapMarker?> getById(int id) =>
      (select(mapMarkers)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// One-shot read of all markers across collections — used by home widgets.
  Future<List<MapMarker>> getAll() => (select(
    mapMarkers,
  )..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).get();

  /// Textsuche innerhalb einer Collection. Begrenzt, weil ein kurzer Suchbegriff
  /// in den importierten Collections (413k Türme, 82k Lost Places) sonst
  /// zehntausende Treffer liefert, die alle gerendert werden müssten.
  Future<List<MapMarker>> search(
    int collectionId,
    String q, {
    int limit = 500,
  }) {
    final pattern = '%${escapeLikePattern(q)}%';
    return (select(mapMarkers)
          ..where(
            (t) =>
                t.collectionId.equals(collectionId) &
                (t.note.like(pattern, escapeChar: likeEscapeChar) |
                    t.hashtags.like(pattern, escapeChar: likeEscapeChar) |
                    t.locationName.like(pattern, escapeChar: likeEscapeChar) |
                    t.title.like(pattern, escapeChar: likeEscapeChar)),
          )
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .get();
  }

  /// Neueste Marker einer Collection mit Obergrenze — für Listen-/Galerie-
  /// Ansichten, die sonst über `getByCollection` die komplette Collection
  /// laden würden.
  Future<List<MapMarker>> getRecentByCollection(
    int collectionId, {
    int limit = 500,
  }) =>
      (select(mapMarkers)
            ..where((t) => t.collectionId.equals(collectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  Future<int> insert(MapMarkersCompanion c) => into(mapMarkers).insert(c);

  Future<void> updateMarker(MapMarker m) => update(mapMarkers).replace(m);

  Future<void> deleteMarker(int id) =>
      (delete(mapMarkers)..where((t) => t.id.equals(id))).go();

  /// Fügt neue Marker gebündelt ein (z.B. beim einmaligen Türme-Daten-Seed).
  Future<int> bulkInsertNew(List<MapMarkersCompanion> rows) async {
    await batch((b) => b.insertAll(mapMarkers, rows));
    return rows.length;
  }

  /// Effiziente Prüfung (LIMIT 1), ob eine Collection bereits importierte
  /// Marker hat — Sekundär-Guard für den einmaligen Türme-Daten-Seed, ohne
  /// bei jedem App-Start alle (potenziell hunderttausende) Zeilen zu laden.
  Future<bool> hasAnyWithOsmId(int collectionId) async {
    final row =
        await (select(mapMarkers)
              ..where(
                (t) =>
                    t.collectionId.equals(collectionId) & t.osmId.isNotNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Analog zu [hasAnyWithOsmId] — Sekundär-Guard für den einmaligen
  /// Lost-Places-Daten-Seed.
  Future<bool> hasAnyWithExternalId(int collectionId) async {
    final row =
        await (select(mapMarkers)
              ..where(
                (t) =>
                    t.collectionId.equals(collectionId) &
                    t.externalId.isNotNull(),
              )
              ..limit(1))
            .getSingleOrNull();
    return row != null;
  }

  /// Gesamtzahl aller Marker über alle Collections — reine COUNT-Query statt
  /// `getAll().length`, damit z.B. der Homescreen-Widget-Refresh nicht bei
  /// jedem Zyklus hunderttausende Zeilen (Türme-Import) komplett laden muss.
  Future<int> countAll() async {
    final query = selectOnly(mapMarkers)..addColumns([mapMarkers.id.count()]);
    final row = await query.getSingle();
    return row.read(mapMarkers.id.count()) ?? 0;
  }

  /// Der zuletzt erstellte Marker einer Collection (oder `null`), z.B. für
  /// die initiale Kartenzentrierung — deutlich billiger als
  /// `getByCollection(id).first`, wenn die Collection sehr groß ist.
  Future<MapMarker?> getMostRecentByCollection(int collectionId) =>
      (select(mapMarkers)
            ..where((t) => t.collectionId.equals(collectionId))
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(1))
          .getSingleOrNull();

  /// Nur die nicht-leeren Hashtag-Strings einer Collection — nicht die
  /// kompletten Marker-Zeilen. Die Hashtag-Leiste braucht ausschließlich diese
  /// eine Spalte; importierte Datensätze (Türme/Lost Places) haben ohnehin nie
  /// Hashtags, wodurch die Bedingung `hashtags != ''` bei genau den großen
  /// Collections fast alles wegfiltert, statt hunderttausende Zeilen samt aller
  /// Spalten in den Speicher zu laden.
  Future<List<String>> hashtagStringsForCollection(int collectionId) async {
    final query = selectOnly(mapMarkers)
      ..addColumns([mapMarkers.hashtags])
      ..where(
        mapMarkers.collectionId.equals(collectionId) &
            mapMarkers.hashtags.equals('').not(),
      );
    final rows = await query.get();
    return rows
        .map((r) => r.read(mapMarkers.hashtags))
        .whereType<String>()
        .toList();
  }

  /// Marker mit einem gesetzten Hashtag, kollektionsweit — nicht auf den
  /// aktuellen Kartenausschnitt begrenzt, damit ein Hashtag-Filter wirklich
  /// alle Treffer der Sammlung findet statt nur die gerade sichtbaren. Die
  /// LIKE-Vorauswahl ist wie bei [search] begrenzt (Aufrufer prüft danach den
  /// exakten Tag anhand des kompletten, kommagetrennten `hashtags`-Felds).
  Future<List<MapMarker>> byHashtagSubstring(
    int collectionId,
    String tag, {
    int limit = 500,
  }) =>
      (select(mapMarkers)
            ..where(
              (t) =>
                  t.collectionId.equals(collectionId) &
                  t.hashtags.like(
                    '%${escapeLikePattern(tag)}%',
                    escapeChar: likeEscapeChar,
                  ),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();

  /// Marker einer Collection innerhalb eines Lat/Lon-Rechtecks (aktueller
  /// Kartenausschnitt), mit Obergrenze — verhindert, dass sehr große
  /// Collections (z.B. hunderttausende importierte Türme) komplett geladen
  /// und an den Cluster-Layer übergeben werden.
  Future<List<MapMarker>> getByCollectionInBounds(
    int collectionId, {
    required double minLat,
    required double maxLat,
    required double minLon,
    required double maxLon,
    int limit = 2000,
  }) =>
      (select(mapMarkers)
            ..where(
              (t) =>
                  t.collectionId.equals(collectionId) &
                  t.latitude.isBetweenValues(minLat, maxLat) &
                  t.longitude.isBetweenValues(minLon, maxLon),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
            ..limit(limit))
          .get();
}
