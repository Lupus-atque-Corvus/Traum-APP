import 'package:sqlite3/sqlite3.dart';
import '../models/substance_record.dart';

/// Read-only Query-Service gegen die kopierte Substanz-Referenzdatenbank
/// (`assets/substances_reference.sqlite3`, einmalig kopiert nach
/// `<appDocuments>/substances_reference.sqlite3` durch [SubstanceReferenceDbCopier]).
///
/// Bewusst KEIN Drift-`DatabaseAccessor` — die Datei ist eine separate,
/// eigenständige SQLite-Verbindung mit vorgebautem FTS5-Index, komplett
/// getrennt von der Drift-verwalteten `traum.sqlite`.
class SubstanceReferenceDbService {
  final String dbPath;
  Database? _db;
  bool _ftsAvailable = true;

  SubstanceReferenceDbService(this.dbPath);

  bool get ftsAvailable => _ftsAvailable;

  Database _open() => _db ??= sqlite3.open(dbPath, mode: OpenMode.readOnly);

  Future<List<SubstanceRecord>> search(
    String query, {
    SubstanceKlasse? klasseFilter,
    String? kategorieFilter,
    bool? pflanzlichOnly,
    int limit = 50,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return const [];
    final db = _open();

    final where = <String>[];
    final params = <Object?>[];
    if (klasseFilter != null) {
      where.add('s.klasse = ?');
      params.add(
        klasseFilter == SubstanceKlasse.supplement
            ? 'Supplemente'
            : 'Medikamente',
      );
    }
    if (kategorieFilter != null) {
      where.add('s.kategorie = ?');
      params.add(kategorieFilter);
    }
    if (pflanzlichOnly == true) {
      where.add('s.pflanzlich = 1');
    }
    final whereSql = where.isEmpty ? '' : 'AND ${where.join(' AND ')}';

    if (_ftsAvailable) {
      late final ResultSet ftsResult;
      try {
        final match = '${_escapeFts(trimmed)}*';
        ftsResult = db.select(
          'SELECT s.* FROM substances_fts f '
          'JOIN substances s ON s.id = f.rowid '
          'WHERE substances_fts MATCH ? $whereSql '
          'ORDER BY rank LIMIT ?',
          [match, ...params, limit],
        );
      } catch (_) {
        _ftsAvailable = false;
      }
      if (_ftsAvailable) {
        return ftsResult.map((r) => SubstanceRecord.fromRow(r)).toList();
      }
    }

    // Fallback ohne fts5-Modul: einfache LIKE-Suche über den Namen.
    final likeQ = '%${trimmed.toLowerCase()}%';
    final result = db.select(
      'SELECT * FROM substances s WHERE lower(s.substance) LIKE ? $whereSql '
      'ORDER BY s.substance LIMIT ?',
      [likeQ, ...params, limit],
    );
    return result.map((r) => SubstanceRecord.fromRow(r)).toList();
  }

  Future<SubstanceRecord?> findById(int id) async {
    final db = _open();
    final result = db.select('SELECT * FROM substances WHERE id = ?', [id]);
    if (result.isEmpty) return null;
    return SubstanceRecord.fromRow(result.first);
  }

  Future<List<String>> listCategories() async {
    final db = _open();
    final result = db.select(
      "SELECT DISTINCT kategorie FROM substances "
      "WHERE kategorie IS NOT NULL AND kategorie != '' "
      "ORDER BY kategorie",
    );
    return result.map((r) => r['kategorie'] as String).toList();
  }

  Future<List<TopNebenwirkung>> topNebenwirkungen(int substanceId) async {
    final db = _open();
    final result = db.select(
      'SELECT * FROM top_nebenwirkungen WHERE substance_id = ? '
      'ORDER BY meldungen DESC LIMIT 10',
      [substanceId],
    );
    return result.map((r) => TopNebenwirkung.fromRow(r)).toList();
  }

  void dispose() {
    _db?.dispose();
    _db = null;
  }

  /// Maskiert FTS5-Sonderzeichen (gleiches Muster wie `NotesDao._escapeFts`).
  String _escapeFts(String input) {
    final tokens = input
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .map((t) => '"${t.replaceAll('"', '""')}"');
    return tokens.join(' ');
  }
}
