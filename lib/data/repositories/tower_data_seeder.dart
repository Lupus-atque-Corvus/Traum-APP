import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';

/// Spielt einen einmalig mitgelieferten Türme-Datensatz (Europa + USA/Kanada,
/// aus OpenStreetMap/Overpass zusammengetragen) in die Türme-Collection ein,
/// damit sie sofort und komplett offline verfügbar sind — kein Netzwerkzugriff
/// zur Laufzeit nötig. Läuft nach [MapCollectionSeeder], da die Türme-Collection
/// vorher existieren muss.
class TowerDataSeeder {
  static const _flag = 'tower_data_seeded_v1';
  static const _chunkSize = 500;

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_flag) == true) return;

    try {
      final collections = await db.mapCollectionsDao.getAll();
      final towerCollection =
          collections.where((c) => c.iconName == 'tower').firstOrNull;
      if (towerCollection == null) {
        // Türme-Collection noch nicht angelegt (Seeder-Reihenfolge verletzt) —
        // kein Flag setzen, nächster Start versucht es erneut.
        return;
      }

      // Sekundär-Guard: bereits importierte Türme vorhanden (z.B. Flag nach
      // Neuinstallation verloren)? Dann nicht erneut einspielen.
      if (await db.mapMarkersDao.hasAnyWithOsmId(towerCollection.id)) {
        await prefs.setBool(_flag, true);
        return;
      }

      final raw = await rootBundle.loadString('assets/data/towers.tsv');
      final lines = const LineSplitter().convert(raw);

      var buffer = <MapMarkersCompanion>[];
      final now = DateTime.now();
      for (final line in lines) {
        if (line.isEmpty) continue;
        final parts = line.split('\t');
        if (parts.length < 7) continue;
        final osmId = parts[0];
        final lat = double.tryParse(parts[1]);
        final lon = double.tryParse(parts[2]);
        if (lat == null || lon == null) continue;
        final name = parts[3];
        final towerType = parts[4];
        final height = parts[5];
        final operatorName = parts[6];

        final customFields = <String, dynamic>{
          'towerType': ?_mapTowerType(towerType),
          if (height.isNotEmpty) 'towerHeight': height,
          if (operatorName.isNotEmpty) 'towerOperator': operatorName,
        };

        buffer.add(MapMarkersCompanion.insert(
          collectionId: towerCollection.id,
          title: Value(name),
          latitude: Value(lat),
          longitude: Value(lon),
          customFields: Value(jsonEncode(customFields)),
          osmId: Value(osmId),
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
      // vorbefüllte Türme weiter. Kein Flag setzen, nächster Start versucht es
      // erneut.
      debugPrint('TowerDataSeeder failed: $e\n$st');
      return;
    }

    await prefs.setBool(_flag, true);
  }

  /// Mappt den rohen OSM `tower:type`-Tag auf eine der PredefinedFields-
  /// Optionen. `communication` ist die einzige aus den gesammelten Daten klar
  /// ableitbare Ausprägung ("Funkmast") — alles andere landet in "Sonstige",
  /// ein fehlender Tag bleibt unausgefüllt statt falscher Präzision.
  static String? _mapTowerType(String osmValue) => switch (osmValue) {
        '' => null,
        'communication' => 'Funkmast',
        _ => 'Sonstige',
      };
}
