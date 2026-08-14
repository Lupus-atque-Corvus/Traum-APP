import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:traum/data/repositories/lost_place_row.dart';

String _json(List<Map<String, Object?>> entries) => jsonEncode(entries);

void main() {
  test('reduziert einen Eintrag auf die Marker-Felder', () {
    final rows = parseLostPlaceRows(
      _json([
        {
          'externalId': 'lostfoundations:abc',
          'lat': 51.5,
          'lon': 7.25,
          'title': 'Alte Ziegelei',
          'description': 'Seit 1998 stillgelegt.',
          'sourceUrl': 'https://example.org/place/abc',
        },
      ]),
    );

    expect(rows, hasLength(1));
    final r = rows.single;
    expect(r.externalId, 'lostfoundations:abc');
    expect(r.lat, 51.5);
    expect(r.lon, 7.25);
    expect(r.title, 'Alte Ziegelei');
    expect(
      r.note,
      'Seit 1998 stillgelegt.\n\nQuelle: https://example.org/place/abc',
    );
  });

  test('überspringt Einträge ohne Koordinaten oder ohne externalId', () {
    final rows = parseLostPlaceRows(
      _json([
        {'externalId': 'a', 'lat': null, 'lon': 7.0, 'title': 'ohne lat'},
        {'externalId': 'b', 'lat': 51.0, 'lon': null, 'title': 'ohne lon'},
        {'externalId': '', 'lat': 51.0, 'lon': 7.0, 'title': 'leere id'},
        {'lat': 51.0, 'lon': 7.0, 'title': 'gar keine id'},
        {'externalId': 'ok', 'lat': 51.0, 'lon': 7.0, 'title': 'gültig'},
      ]),
    );

    expect(rows.map((r) => r.externalId), ['ok']);
  });

  test(
    'Notiz bleibt leer, wenn weder Beschreibung noch Quelle vorhanden sind',
    () {
      final rows = parseLostPlaceRows(
        _json([
          {'externalId': 'x', 'lat': 1.0, 'lon': 2.0, 'title': 'nur Titel'},
        ]),
      );
      expect(rows.single.note, isEmpty);
    },
  );

  test('nur Quelle vorhanden: Notiz enthält keinen führenden Leerraum', () {
    final rows = parseLostPlaceRows(
      _json([
        {
          'externalId': 'x',
          'lat': 1.0,
          'lon': 2.0,
          'title': 't',
          'sourceUrl': 'https://example.org/x',
        },
      ]),
    );
    expect(rows.single.note, 'Quelle: https://example.org/x');
  });

  test('ganzzahlige Koordinaten werden als double gelesen', () {
    // jsonDecode liefert für `51` ein int — der Cast muss das abfangen.
    final rows = parseLostPlaceRows('[{"externalId":"i","lat":51,"lon":7}]');
    expect(rows.single.lat, 51.0);
    expect(rows.single.lon, 7.0);
  });
}
