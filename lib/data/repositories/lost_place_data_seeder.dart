import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

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
      final lostPlaceCollection =
          collections.where((c) => c.iconName == 'home_broken').firstOrNull;
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
      final entries = jsonDecode(raw) as List<dynamic>;

      var buffer = <MapMarkersCompanion>[];
      final now = DateTime.now();
      for (final entry in entries) {
        final e = entry as Map<String, dynamic>;
        final lat = (e['lat'] as num?)?.toDouble();
        final lon = (e['lon'] as num?)?.toDouble();
        if (lat == null || lon == null) continue;
        final externalId = e['externalId'] as String?;
        if (externalId == null || externalId.isEmpty) continue;
        final title = (e['title'] as String?) ?? '';
        final description = (e['description'] as String?) ?? '';
        final sourceUrl = (e['sourceUrl'] as String?) ?? '';

        final noteParts = <String>[
          if (description.isNotEmpty) description,
          if (sourceUrl.isNotEmpty) 'Quelle: $sourceUrl',
        ];

        buffer.add(MapMarkersCompanion.insert(
          collectionId: lostPlaceCollection.id,
          title: Value(title),
          latitude: Value(lat),
          longitude: Value(lon),
          note: Value(noteParts.join('\n\n')),
          externalId: Value(externalId),
          createdAt: now,
        ));

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
