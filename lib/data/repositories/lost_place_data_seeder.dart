import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';
import 'lost_place_row.dart';

/// Spielt einen einmalig mitgelieferten Lost-Places-Datensatz (lostfoundations.org
/// + 2 öffentlich geteilte Google-My-Maps-Karten, siehe
/// `tools/build_lost_places_dataset.py`) in die Lost-Places-Collection ein —
/// analog zu [TowerDataSeeder]. Kein Netzwerkzugriff zur Laufzeit nötig.
/// Läuft nach [MapCollectionSeeder], da die Lost-Places-Collection vorher
/// existieren muss.
class LostPlaceDataSeeder {
  static const _flag = 'lost_place_data_seeded_v1';
  static const _chunkSize = 500;

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_flag) == true) return;

    try {
      final collections = await db.mapCollectionsDao.getAll();
      final lostPlaceCollection = collections
          .where((c) => c.iconName == 'home_broken')
          .firstOrNull;
      if (lostPlaceCollection == null) {
        // Lost-Places-Collection noch nicht angelegt (Seeder-Reihenfolge
        // verletzt) — kein Flag setzen, nächster Start versucht es erneut.
        return;
      }

      // Sekundär-Guard: bereits importierte Lost Places vorhanden (z.B. Flag
      // nach Neuinstallation verloren)? Dann nicht erneut einspielen.
      if (await db.mapMarkersDao.hasAnyWithExternalId(lostPlaceCollection.id)) {
        await prefs.setBool(_flag, true);
        return;
      }

      final raw = await rootBundle.loadString('assets/data/lost_places.json');
      // Parsen im Hintergrund-Isolate: Die Datei ist ~36 MB, der daraus
      // entstehende JSON-Objektgraph (82.666 Maps) ist ein Vielfaches davon.
      // Beides gleichzeitig im UI-Isolate war ein massiver Speicher-Peak beim
      // allerersten Start. `compute` gibt nur die bereits reduzierten Zeilen
      // zurück — der große Zwischenzustand entsteht und verschwindet drüben.
      final rows = await compute(parseLostPlaceRows, raw);

      var buffer = <MapMarkersCompanion>[];
      final now = DateTime.now();
      for (final r in rows) {
        buffer.add(
          MapMarkersCompanion.insert(
            collectionId: lostPlaceCollection.id,
            title: Value(r.title),
            latitude: Value(r.lat),
            longitude: Value(r.lon),
            note: Value(r.note),
            externalId: Value(r.externalId),
            createdAt: now,
          ),
        );

        if (buffer.length >= _chunkSize) {
          await db.mapMarkersDao.bulkInsertNew(buffer);
          buffer = <MapMarkersCompanion>[];
          // Zwischen Chunks an den Event-Loop abgeben, um den App-Start nicht
          // durchgehend zu blockieren (Seeder läuft ohnehin erst nach dem
          // ersten Frame).
          await Future<void>.delayed(Duration.zero);
        }
      }
      if (buffer.isNotEmpty) {
        await db.mapMarkersDao.bulkInsertNew(buffer);
      }
    } catch (e, st) {
      // Asset fehlt/kaputt oder DB-Fehler — App funktioniert auch ohne
      // vorbefüllte Lost Places weiter. Kein Flag setzen, nächster Start
      // versucht es erneut.
      debugPrint('LostPlaceDataSeeder failed: $e\n$st');
      return;
    }

    await prefs.setBool(_flag, true);
  }
}
