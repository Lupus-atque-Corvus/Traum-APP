import 'dart:convert';

/// Eine bereits aufbereitete Lost-Place-Zeile — genau die Felder, die in
/// `map_markers` landen, nichts weiter.
class LostPlaceRow {
  final String externalId;
  final double lat;
  final double lon;
  final String title;
  final String note;

  const LostPlaceRow({
    required this.externalId,
    required this.lat,
    required this.lon,
    required this.title,
    required this.note,
  });
}

/// Parst den gebündelten Lost-Places-Datensatz und reduziert ihn direkt auf
/// [LostPlaceRow]s.
///
/// Läuft über `compute()` in einem Hintergrund-Isolate (siehe
/// `LostPlaceDataSeeder`): Die JSON-Datei ist ~36 MB, der beim Dekodieren
/// entstehende Objektgraph (82.666 Maps mit je sechs Feldern) ein Vielfaches
/// davon. Beides gleichzeitig im UI-Isolate war beim allerersten App-Start ein
/// massiver Speicher-Peak. Weil diese Funktion die Daten noch im
/// Hintergrund-Isolate zusammenstreicht, wandert nur das Reduzierte zurück.
///
/// Muss eine Top-Level-Funktion sein — `compute` kann keine Closures oder
/// Instanzmethoden übertragen.
List<LostPlaceRow> parseLostPlaceRows(String raw) {
  final entries = jsonDecode(raw) as List<dynamic>;
  final rows = <LostPlaceRow>[];
  for (final entry in entries) {
    final e = entry as Map<String, dynamic>;
    final lat = (e['lat'] as num?)?.toDouble();
    final lon = (e['lon'] as num?)?.toDouble();
    if (lat == null || lon == null) continue;
    final externalId = e['externalId'] as String?;
    if (externalId == null || externalId.isEmpty) continue;

    final description = (e['description'] as String?) ?? '';
    final sourceUrl = (e['sourceUrl'] as String?) ?? '';
    final noteParts = <String>[
      if (description.isNotEmpty) description,
      if (sourceUrl.isNotEmpty) 'Quelle: $sourceUrl',
    ];

    rows.add(
      LostPlaceRow(
        externalId: externalId,
        lat: lat,
        lon: lon,
        title: (e['title'] as String?) ?? '',
        note: noteParts.join('\n\n'),
      ),
    );
  }
  return rows;
}
