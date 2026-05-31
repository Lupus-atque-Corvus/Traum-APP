import 'dart:convert';
import 'package:drift/drift.dart' show Value;
import 'package:http/http.dart' as http;
import '../../data/database/traum_database.dart';

class SubstanceDownloadService {
  final SubstanceDatabaseDao _dao;

  static const _pageSize = 100;
  static const _totalPages = 50; // 5.000 Einträge
  static const _fdaBase = 'https://api.fda.gov/drug/label.json';

  SubstanceDownloadService(this._dao);

  /// Lädt Medikamente aus openFDA und speichert sie lokal.
  /// Yielded den Fortschritt als Wert zwischen 0.0 und 1.0.
  /// Wirft eine Exception wenn am Ende 0 Einträge gespeichert wurden.
  Stream<double> download() async* {
    final allEntries = <SubstanceDatabaseEntriesCompanion>[];
    final client = http.Client();

    try {
      for (int page = 0; page < _totalPages; page++) {
        final pageEntries = await _downloadPage(page, client);
        allEntries.addAll(pageEntries);
        yield (page + 1) / _totalPages;
        // Kurze Pause um Rate-Limiting zu vermeiden
        if (page < _totalPages - 1) {
          await Future.delayed(const Duration(milliseconds: 300));
        }
      }
    } finally {
      client.close();
    }

    if (allEntries.isEmpty) {
      throw Exception(
          'Download fehlgeschlagen: Keine Einträge heruntergeladen. Bitte Internetverbindung prüfen.');
    }

    // Erst wenn alle Daten da sind: altes DB leeren und neu befüllen
    await _dao.clearAll();
    await _dao.bulkInsert(allEntries);
  }

  Future<List<SubstanceDatabaseEntriesCompanion>> _downloadPage(
      int page, http.Client client) async {
    final skip = page * _pageSize;
    final url =
        '$_fdaBase?limit=$_pageSize&skip=$skip&search=_exists_:openfda.generic_name';
    try {
      final response = await client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return [];

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final results =
          (data['results'] as List?)?.cast<Map<String, dynamic>>() ?? [];

      final entries = <SubstanceDatabaseEntriesCompanion>[];
      for (final r in results) {
        final openfda = r['openfda'] as Map<String, dynamic>? ?? {};
        final genericNames =
            (openfda['generic_name'] as List?)?.cast<String>() ?? [];
        final brandNames =
            (openfda['brand_name'] as List?)?.cast<String>() ?? [];
        final name = genericNames.firstOrNull ?? brandNames.firstOrNull;
        if (name == null || name.trim().isEmpty) continue;

        final cleanName = name.trim();
        final slug =
            cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
        final id = 'fda_$slug';

        final mechanism =
            _truncate(_firstStringSafe(r['mechanism_of_action']), 500);
        final dosage =
            _truncate(_firstStringSafe(r['dosage_and_administration']), 300);
        // adverse_reactions ist die Nebenwirkungsliste; warnings ist der Blackbox-Warning
        final adverseRaw =
            _truncate(_firstStringSafe(r['adverse_reactions']), 200);
        final interactionsRaw =
            _truncate(_firstStringSafe(r['drug_interactions']), 300);

        entries.add(SubstanceDatabaseEntriesCompanion.insert(
          id: id,
          name: cleanName,
          nameLower: cleanName.toLowerCase(),
          type: 'medication',
          category: const Value('Medikament'),
          mechanism: Value(mechanism),
          commonDosage: Value(dosage),
          adverseEventsJson: Value(adverseRaw != null
              ? jsonEncode([
                  {'name': adverseRaw, 'frequencyPercent': null}
                ])
              : '[]'),
          interactionsJson: Value(interactionsRaw != null
              ? jsonEncode([
                  {
                    'withId': 'unknown',
                    'withName': 'Verschiedene',
                    'severity': 'moderate',
                    'description': interactionsRaw,
                  }
                ])
              : '[]'),
        ));
      }
      return entries;
    } catch (_) {
      // Einzelne Seiten-Fehler werden übersprungen — kein Abbruch
      return [];
    }
  }

  String? _firstStringSafe(dynamic value) {
    if (value is List && value.isNotEmpty) {
      final first = value.first;
      return first is String ? first : null;
    }
    if (value is String) return value;
    return null;
  }

  String? _truncate(String? s, int max) {
    if (s == null || s.isEmpty) return null;
    return s.length > max ? '${s.substring(0, max)}…' : s;
  }
}
