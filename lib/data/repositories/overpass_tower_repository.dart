import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

// Overpass' Apache/WAF lehnt Browser-spoofende User-Agents (z.B.
// "Mozilla/5.0 (...)") mit HTTP 406 ab — anders als bei OpenFoodFacts. Ein
// schlichter, klar App-identifizierender String kommt durch (verifiziert
// gegen die echte API).
const _userAgent =
    'TRAUM-App/1.0 (+https://github.com/Lupus-atque-Corvus/Traum-APP)';

/// Anfrage-Gebiet für einen Türme-Import: entweder der aktuelle Kartenausschnitt
/// oder eine per Namen aufgelöste OSM-Verwaltungsregion ("Bayern", "Deutschland").
sealed class OverpassAreaQuery {
  const OverpassAreaQuery();
}

class OverpassBboxQuery extends OverpassAreaQuery {
  final double south, west, north, east;
  const OverpassBboxQuery({
    required this.south,
    required this.west,
    required this.north,
    required this.east,
  });
}

class OverpassRegionQuery extends OverpassAreaQuery {
  final String name;
  const OverpassRegionQuery(this.name);
}

class OverpassTowerResult {
  /// z.B. "node/123456789" — stabil, eindeutig, dient als Dedupe-Schlüssel.
  final String osmId;
  final double latitude;
  final double longitude;
  final String? name;
  final String? towerType;
  final String? heightMeters;
  final String? operatorName;

  const OverpassTowerResult({
    required this.osmId,
    required this.latitude,
    required this.longitude,
    this.name,
    this.towerType,
    this.heightMeters,
    this.operatorName,
  });
}

/// Fehler beim Overpass-Import. [messageKey] ist ein ARB-Key, der im UI
/// aufgelöst wird — hier bewusst kein hardcodierter Text.
class OverpassImportException implements Exception {
  final String messageKey;
  const OverpassImportException(this.messageKey);

  @override
  String toString() => 'OverpassImportException($messageKey)';
}

/// Ruft Funkmasten-/Turm-Daten aus OpenStreetMap per Overpass API ab.
///
/// Anders als die Nutrition-`FoodSource`-Quellen (die bei Netzwerkfehlern
/// still `[]` zurückgeben), ist der Türme-Import eine explizite, einmalige Nutzeraktion
/// mit sichtbarem Fortschritt/Fehlerstatus — ein Fehler soll den User daher
/// sichtbar erreichen. Deshalb wirft dieses Repository eine typisierte
/// Exception statt still ein leeres Ergebnis zu liefern.
class OverpassTowerRepository {
  static const _endpoints = [
    'https://overpass-api.de/api/interpreter',
    'https://overpass.kumi.systems/api/interpreter',
  ];

  static const _bboxTagFilters = [
    '["man_made"="mast"]["tower:type"="communication"]',
    '["man_made"="tower"]',
    '["communication:mobile_phone"="yes"]',
  ];

  Future<List<OverpassTowerResult>> fetchTowers(OverpassAreaQuery query) async {
    final ql = _buildQuery(query);
    final timeout = query is OverpassRegionQuery
        ? const Duration(seconds: 60)
        : const Duration(seconds: 25);

    final client = HttpClient();
    try {
      for (final endpoint in _endpoints) {
        for (var attempt = 0; attempt < 2; attempt++) {
          if (attempt > 0) {
            await Future.delayed(const Duration(milliseconds: 600));
          }
          try {
            final (statusCode, body) =
                await _post(client, endpoint, ql).timeout(timeout);

            if (statusCode == 429 || statusCode >= 500) {
              debugPrint(
                'OverpassTowerRepository: $endpoint returned $statusCode, '
                'trying next endpoint',
              );
              break; // dieser Endpoint ist überlastet — direkt zum Fallback
            }
            if (statusCode != 200) {
              throw const OverpassImportException('mapImportErrorHttp');
            }

            final json = jsonDecode(body) as Map<String, dynamic>;
            if (query is OverpassRegionQuery) {
              final elements = json['elements'];
              final hasArea = elements is List &&
                  elements.any((e) => e is Map && e['type'] == 'area');
              if (!hasArea) {
                throw const OverpassImportException(
                    'mapImportErrorRegionNotFound');
              }
            }
            return parseOverpassResponse(json);
          } on OverpassImportException {
            rethrow;
          } catch (e) {
            debugPrint(
              'OverpassTowerRepository fetchTowers error ($endpoint, '
              'attempt $attempt): $e',
            );
          }
        }
      }
    } finally {
      client.close();
    }
    throw const OverpassImportException('mapImportErrorNetwork');
  }

  /// POST via dart:io statt package:http — Overpass' Apache lehnt Requests,
  /// bei denen der User-Agent-Header doppelt gesetzt wird (dart:io-Client-
  /// Default + eigener Header über package:http), mit 406 ab. Direktes
  /// Setzen über [HttpHeaders.set] auf dem Request vermeidet die Dopplung.
  Future<(int, String)> _post(
      HttpClient client, String endpoint, String query) async {
    final body = utf8.encode('data=${Uri.encodeQueryComponent(query)}');
    final request = await client.postUrl(Uri.parse(endpoint));
    request.headers.contentType =
        ContentType('application', 'x-www-form-urlencoded');
    request.headers.set('user-agent', _userAgent);
    request.contentLength = body.length;
    request.add(body);
    final response = await request.close();
    final responseBody = await response.transform(utf8.decoder).join();
    return (response.statusCode, responseBody);
  }

  String _buildQuery(OverpassAreaQuery query) {
    switch (query) {
      case OverpassBboxQuery():
        final bbox =
            '${query.south},${query.west},${query.north},${query.east}';
        final nodes =
            _bboxTagFilters.map((f) => '  node$f($bbox);').join('\n');
        return '[out:json][timeout:25];\n(\n$nodes\n);\nout body;';
      case OverpassRegionQuery():
        // Anführungszeichen im Namen escapen — verhindert kaputte Overpass-QL,
        // kein Sicherheitsrisiko (Overpass führt keinen beliebigen Code aus).
        final name = query.name.replaceAll('"', r'\"');
        final nodes = _bboxTagFilters
            .map((f) => '  node(area.searchArea)$f;')
            .join('\n');
        return '[out:json][timeout:60];\n'
            'area["name"="$name"]["boundary"="administrative"]->.searchArea;\n'
            '.searchArea out ids;\n'
            '(\n$nodes\n);\nout body;';
    }
  }
}

/// Reine, testbare Parse-Funktion, kein HTTP — Muster wie parseOffSearch().
/// Ignoriert `area`-Elemente (kein lat/lon) und alles ohne Koordinaten/ID;
/// nur OSM-Nodes werden importiert (keine ways/relations mit Geometrie-
/// Zentroid — bewusste Vereinfachung, deckt praktisch alle Sendemasten ab).
List<OverpassTowerResult> parseOverpassResponse(Map<String, dynamic> json) {
  final elements = json['elements'];
  if (elements is! List) return [];

  final out = <OverpassTowerResult>[];
  for (final e in elements) {
    if (e is! Map) continue;
    if (e['type'] != 'node') continue;
    final lat = (e['lat'] as num?)?.toDouble();
    final lon = (e['lon'] as num?)?.toDouble();
    final id = e['id'];
    if (lat == null || lon == null || id == null) continue;

    final tags = (e['tags'] as Map?) ?? const {};
    out.add(OverpassTowerResult(
      osmId: 'node/$id',
      latitude: lat,
      longitude: lon,
      name: (tags['name'] as String?)?.trim(),
      towerType: tags['tower:type'] as String?,
      heightMeters: tags['height'] as String?,
      operatorName: tags['operator'] as String?,
    ));
  }
  return out;
}
