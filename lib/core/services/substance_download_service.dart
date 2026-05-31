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
  Stream<double> download() async* {
    await _dao.clearAll();
    for (int page = 0; page < _totalPages; page++) {
      await _downloadPage(page);
      yield (page + 1) / _totalPages;
    }
  }

  Future<void> _downloadPage(int page) async {
    final skip = page * _pageSize;
    final url =
        '$_fdaBase?limit=$_pageSize&skip=$skip&search=_exists_:openfda.generic_name';
    try {
      final response =
          await http.get(Uri.parse(url)).timeout(const Duration(seconds: 20));
      if (response.statusCode != 200) return;

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
        final id =
            'fda_${cleanName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_')}';

        final mechanism = _truncate(_firstString(r['mechanism_of_action']), 500);
        final dosage =
            _truncate(_firstString(r['dosage_and_administration']), 300);
        final warnings = _truncate(_firstString(r['warnings']), 200);
        final interactions =
            _truncate(_firstString(r['drug_interactions']), 300);

        entries.add(SubstanceDatabaseEntriesCompanion.insert(
          id: id,
          name: cleanName,
          nameLower: cleanName.toLowerCase(),
          type: 'medication',
          category: const Value('Medikament'),
          mechanism: Value(mechanism),
          commonDosage: Value(dosage),
          adverseEventsJson: Value(warnings != null
              ? jsonEncode([
                  {'name': warnings, 'frequencyPercent': null}
                ])
              : '[]'),
          interactionsJson: Value(interactions != null
              ? jsonEncode([
                  {
                    'withId': 'unknown',
                    'withName': 'Verschiedene',
                    'severity': 'moderate',
                    'description': interactions,
                  }
                ])
              : '[]'),
        ));
      }

      if (entries.isNotEmpty) {
        await _dao.bulkInsert(entries);
      }
    } catch (_) {
      // Einzelne Seiten-Fehler werden übersprungen — kein Abbruch
    }
  }

  String? _firstString(dynamic value) {
    if (value is List && value.isNotEmpty) return value.first as String?;
    if (value is String) return value;
    return null;
  }

  String? _truncate(String? s, int max) {
    if (s == null || s.isEmpty) return null;
    return s.length > max ? '${s.substring(0, max)}…' : s;
  }
}
