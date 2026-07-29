import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import '../database/traum_database.dart';
import 'overpass_tower_repository.dart';

class TowerImportProgress {
  final int total, imported, skipped, errors;
  const TowerImportProgress({
    required this.total,
    required this.imported,
    required this.skipped,
    required this.errors,
  });
}

/// Holt Türme per [OverpassTowerRepository], dedupliziert gegen bereits
/// vorhandene Marker der Ziel-Collection und fügt neue Marker gestückelt ein.
class TowerImportRepository {
  final MapMarkersDao _markersDao;
  final OverpassTowerRepository _overpass;
  const TowerImportRepository(this._markersDao, this._overpass);

  static const _chunkSize = 200;
  // ~5m Toleranz für den Koordinaten-Fallback-Dedupe.
  static const _coordToleranceDeg = 0.000045;

  Stream<TowerImportProgress> importTowers({
    required int collectionId,
    required OverpassAreaQuery query,
  }) async* {
    final results = await _overpass.fetchTowers(query);
    if (results.isEmpty) {
      yield const TowerImportProgress(
          total: 0, imported: 0, skipped: 0, errors: 0);
      return;
    }
    final existingOsmIds = await _markersDao.getOsmIds(collectionId);
    final existingCoords = await _markersDao.getCoordinates(collectionId);

    var imported = 0, skipped = 0, errors = 0;
    final toInsert = <MapMarkersCompanion>[];

    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      final dupByOsmId = existingOsmIds.contains(r.osmId);
      final dupByCoord = !dupByOsmId &&
          existingCoords.any((c) =>
              (c.$1 - r.latitude).abs() < _coordToleranceDeg &&
              (c.$2 - r.longitude).abs() < _coordToleranceDeg);

      if (dupByOsmId || dupByCoord) {
        skipped++;
      } else {
        try {
          toInsert.add(_toCompanion(collectionId, r));
        } catch (_) {
          errors++;
        }
      }

      // Checkpoint alle ~_chunkSize verarbeitete Einträge — unabhängig davon,
      // ob sie eingefügt oder übersprungen wurden. Ein reiner Insert-Zähler
      // würde bei langen Ketten übersprungener Duplikate (z.B. erneuter Import
      // desselben Gebiets) kaum noch an den UI-Thread abgeben.
      final isLast = i == results.length - 1;
      final checkpoint = (i + 1) % _chunkSize == 0;
      if (checkpoint || isLast) {
        if (toInsert.isNotEmpty) {
          imported += await _markersDao.bulkInsertNew(List.of(toInsert));
          toInsert.clear();
        }
        yield TowerImportProgress(
          total: results.length,
          imported: imported,
          skipped: skipped,
          errors: errors,
        );
        await Future.delayed(Duration.zero);
      }
    }
  }

  MapMarkersCompanion _toCompanion(int collectionId, OverpassTowerResult r) {
    final customFields = <String, dynamic>{
      'towerType': ?_mapTowerType(r.towerType),
      'towerHeight': ?r.heightMeters,
      'towerOperator': ?r.operatorName,
    };
    return MapMarkersCompanion.insert(
      collectionId: collectionId,
      title: Value(r.name ?? ''),
      latitude: Value(r.latitude),
      longitude: Value(r.longitude),
      customFields: Value(jsonEncode(customFields)),
      osmId: Value(r.osmId),
      createdAt: DateTime.now(),
    );
  }

  /// Mappt den rohen OSM `tower:type`-Tag auf eine der PredefinedFields-Optionen.
  /// `communication` ist die einzige aus den abgefragten Tags klar ableitbare
  /// Ausprägung ("Funkmast") — alles andere landet in "Sonstige", ein fehlender
  /// Tag bleibt unausgefüllt (kein Feld statt falscher Präzision). "Sendemast"
  /// ist aus diesen Tags nicht unterscheidbar und bleibt manuell editierbar.
  String? _mapTowerType(String? osmValue) => switch (osmValue) {
        null => null,
        'communication' => 'Funkmast',
        _ => 'Sonstige',
      };
}
