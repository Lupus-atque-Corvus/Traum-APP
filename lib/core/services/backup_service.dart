import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:drift/drift.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../data/database/traum_database.dart';

/// Builds the ZIP archive from already-collected entry bytes. Top-level (not
/// a method) so it can run via [compute] in a background isolate — encoding
/// is synchronous, CPU-bound work that otherwise blocks the UI isolate for
/// the whole duration of a large export (many/large diary photos or videos),
/// which looks and feels exactly like a frozen or crashed app.
Archive _decodeZipArchive(Uint8List bytes) => ZipDecoder().decodeBytes(bytes);

Uint8List _encodeZipArchive(Map<String, Uint8List> entries) {
  final archive = Archive();
  entries.forEach((name, bytes) {
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  });
  final zipBytes = ZipEncoder().encode(archive);
  if (zipBytes == null) {
    throw StateError('ZIP encoding failed');
  }
  return Uint8List.fromList(zipBytes);
}

/// Result of an export operation.
class ExportResult {
  final bool success;
  final int tableCount;
  final int rowCount;
  final int mediaCount;
  final String? error;
  const ExportResult({
    this.success = false,
    this.tableCount = 0,
    this.rowCount = 0,
    this.mediaCount = 0,
    this.error,
  });
}

/// Result of an import operation.
class ImportResult {
  final bool success;
  final int rowCount;
  final int mediaCount;
  final bool cancelled;
  final String? error;
  const ImportResult({
    this.success = false,
    this.rowCount = 0,
    this.mediaCount = 0,
    this.cancelled = false,
    this.error,
  });
}

/// Full-database backup as a ZIP archive (`backup.json` + referenced photo
/// files). Works generically over every Drift table via [GeneratedDatabase.allTables],
/// so it keeps working as the schema evolves without per-column code.
///
/// Import merges by primary key (`INSERT OR REPLACE`); media files travel inside
/// the ZIP and are restored to the app documents directory with their stored
/// paths rewritten to the new device location.
class BackupService {
  BackupService(this._db);
  final TraumDatabase _db;

  /// Bumped when the archive layout changes in a non-backwards-compatible way.
  static const int backupFormatVersion = 1;
  static const String _jsonEntryName = 'backup.json';
  static const String _mediaPrefix = 'media/';
  static const String _restoredMediaDir = 'restored_media';

  /// SQL columns (per SQL table name) that store absolute paths to photo/video
  /// files which must be bundled into the archive.
  static const Map<String, List<String>> _mediaColumns = {
    'diary_entries': ['media_path', 'thumbnail_path'],
    'marker_photos': ['photo_path', 'thumbnail_path'],
    'photo_logs': ['image_path'],
    'transactions': ['receipt_image_path'],
  };

  Map<String, TableInfo> get _tablesByName => {
        for (final t in _db.allTables) t.actualTableName: t,
      };

  // ─── Export ────────────────────────────────────────────────────────────────

  /// Builds the full backup ZIP and opens the share sheet so the user can store
  /// it wherever they like.
  ///
  /// Convenience wrapper around [buildBackupFile] + [shareFile] for callers
  /// that don't need to control the two steps separately. UI callers that
  /// show a progress indicator should use the two methods directly instead —
  /// see the doc comment on [shareFile] for why.
  Future<ExportResult> exportBackup() async {
    try {
      final built = await buildBackupFile();
      await shareFile(built.file, subject: 'TRAUM Backup');
      return ExportResult(
        success: true,
        tableCount: built.tableCount,
        rowCount: built.rowCount,
        mediaCount: built.mediaCount,
      );
    } catch (e) {
      return ExportResult(error: e.toString());
    }
  }

  /// Builds the full backup ZIP and writes it to a temp file — without
  /// sharing it yet. Split out from [exportBackup] so a caller can show a
  /// progress indicator around just this (bounded, isolate-backed) step; see
  /// [shareFile] for why the share step itself must stay outside of it.
  Future<({File file, int tableCount, int rowCount, int mediaCount})>
      buildBackupFile() async {
    final built = await buildBackupZip();
    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');
    final outFile = File(p.join(dir.path, 'traum_backup_$stamp.zip'));
    await outFile.writeAsBytes(built.zipBytes);
    return (
      file: outFile,
      tableCount: built.tableCount,
      rowCount: built.rowCount,
      mediaCount: built.mediaCount,
    );
  }

  /// Opens the OS share sheet for [file]. Deliberately NOT awaited by UI
  /// callers around a progress dialog: on Android, the completion callback
  /// for `Intent.createChooser` results is unreliable across versions and
  /// share targets — some "Save to…" targets never signal completion back to
  /// the app, so a dialog awaiting this Future can hang indefinitely even
  /// after the user has successfully saved the file. The share sheet itself
  /// is native OS UI and gives its own feedback; our app doesn't need to
  /// (and reliably can't) know when it's done.
  Future<void> shareFile(
    File file, {
    required String subject,
    String mimeType = 'application/zip',
  }) =>
      SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path, mimeType: mimeType)],
          subject: subject,
        ),
      );

  /// Serializes every table plus referenced media into ZIP bytes. Separated from
  /// [exportBackup] so it can be exercised without platform plugins.
  Future<({Uint8List zipBytes, int tableCount, int rowCount, int mediaCount})>
      buildBackupZip() async {
    final tables = <String, List<Map<String, dynamic>>>{};
    var rowCount = 0;
    for (final table in _db.allTables) {
      final name = table.actualTableName;
      final rows = await _db.customSelect('SELECT * FROM "$name"').get();
      tables[name] = rows.map((r) => _jsonSafeRow(r.data)).toList();
      rowCount += rows.length;
    }

    // Collect media files referenced by the known path columns. Reading
    // stays here (async I/O, doesn't block the UI isolate) — only the
    // synchronous ZIP encoding below moves to a background isolate.
    final entries = <String, Uint8List>{};
    final mediaManifest = <String, String>{}; // originalPath -> archive entry
    var mediaIndex = 0;
    for (final entry in _mediaColumns.entries) {
      final rows = tables[entry.key];
      if (rows == null) continue;
      for (final row in rows) {
        for (final col in entry.value) {
          final value = row[col];
          if (value is! String || value.isEmpty) continue;
          if (mediaManifest.containsKey(value)) continue;
          final file = File(value);
          if (!file.existsSync()) continue;
          final entryName = '$_mediaPrefix${mediaIndex++}_${p.basename(value)}';
          mediaManifest[value] = entryName;
          entries[entryName] = Uint8List.fromList(await file.readAsBytes());
        }
      }
    }

    final backup = <String, dynamic>{
      'formatVersion': backupFormatVersion,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'tables': tables,
      'media': mediaManifest.entries
          .map((e) => {'original': e.key, 'entry': e.value})
          .toList(),
    };
    entries[_jsonEntryName] =
        Uint8List.fromList(utf8.encode(const JsonEncoder().convert(backup)));

    final zipBytes = await compute(_encodeZipArchive, entries);

    return (
      zipBytes: zipBytes,
      tableCount: tables.length,
      rowCount: rowCount,
      mediaCount: mediaManifest.length,
    );
  }

  // ─── Selective export ────────────────────────────────────────────────────────

  /// SQL tables that belong to each export-sheet module id.
  static const Map<String, List<String>> moduleTables = {
    'training': [
      'workout_plans',
      'workout_days',
      'exercises',
      'workout_sessions',
      'workout_sets',
      'workout_day_exercises',
    ],
    'health': [
      'weight_logs',
      'body_measurements',
      'sleep_logs',
      'mood_logs',
      'photo_logs',
    ],
    'nutrition': [
      'nutrition_logs',
      'meal_templates',
      'water_logs',
      'shopping_list_items',
      'food_products',
      'meal_entries',
      'meal_template_items',
      'weekly_meal_plan',
    ],
    'supplements': ['supplements', 'supplement_logs'],
    'planning': [
      'appointments',
      'todos',
      'goals',
      'sub_tasks',
      'habits',
      'habit_logs',
    ],
    'medication': ['medications', 'medication_logs'],
    'abstinence': ['abstinence_trackers', 'abstinence_events'],
    'budget': [
      'budget_categories',
      'transactions',
      'savings_goals',
      'debts',
      'quick_templates',
      'accounts',
    ],
    'period': ['period_entries', 'cycle_calculations', 'period_symptoms'],
  };

  /// Exports the tables of the selected [modules] as a single JSON file (which
  /// can be re-imported) or, for `csv`, a ZIP of one CSV file per table.
  ///
  /// Convenience wrapper around [buildModulesFile] + [shareFile] — see the
  /// doc comment on [shareFile] for why UI callers showing a progress
  /// indicator should use the two methods directly instead.
  Future<ExportResult> exportModules(
    List<String> modules, {
    required String format,
  }) async {
    try {
      final built = await buildModulesFile(modules, format: format);
      if (built == null) {
        return const ExportResult(error: 'No modules selected');
      }
      await shareFile(built.file,
          subject: 'TRAUM Export', mimeType: built.mimeType);
      return ExportResult(
        success: true,
        tableCount: built.tableCount,
        rowCount: built.rowCount,
      );
    } catch (e) {
      return ExportResult(error: e.toString());
    }
  }

  /// Builds the selective export file (JSON or CSV-ZIP) without sharing it
  /// yet. Returns `null` if no known module tables were selected.
  Future<({File file, String mimeType, int tableCount, int rowCount})?>
      buildModulesFile(
    List<String> modules, {
    required String format,
  }) async {
    final tables = await _dumpModuleTables(modules);
    if (tables.isEmpty) return null;
    final rowCount =
        tables.values.fold<int>(0, (sum, rows) => sum + rows.length);

    final dir = await getTemporaryDirectory();
    final stamp = DateTime.now()
        .toIso8601String()
        .substring(0, 19)
        .replaceAll(':', '-');

    final File file;
    final String mimeType;
    if (format == 'csv') {
      final csvEntries = <String, Uint8List>{
        for (final entry in tables.entries)
          '${entry.key}.csv': Uint8List.fromList(utf8.encode(_toCsv(entry.value))),
      };
      final zipBytes = await compute(_encodeZipArchive, csvEntries);
      file = File(p.join(dir.path, 'traum_export_$stamp.zip'));
      await file.writeAsBytes(zipBytes);
      mimeType = 'application/zip';
    } else {
      file = File(p.join(dir.path, 'traum_export_$stamp.json'));
      await file.writeAsBytes(_encodeModulesJson(modules, tables));
      mimeType = 'application/json';
    }

    return (
      file: file,
      mimeType: mimeType,
      tableCount: tables.length,
      rowCount: rowCount,
    );
  }

  /// Builds the importable JSON bytes for the selected [modules]. Separated so
  /// it can be exercised without platform plugins.
  Future<List<int>> buildModulesJson(List<String> modules) async {
    final tables = await _dumpModuleTables(modules);
    return _encodeModulesJson(modules, tables);
  }

  Future<Map<String, List<Map<String, dynamic>>>> _dumpModuleTables(
    List<String> modules,
  ) async {
    final tableNames = <String>{};
    for (final m in modules) {
      tableNames.addAll(moduleTables[m] ?? const []);
    }
    final known = _tablesByName;
    final tables = <String, List<Map<String, dynamic>>>{};
    for (final name in tableNames) {
      if (!known.containsKey(name)) continue;
      final rows = await _db.customSelect('SELECT * FROM "$name"').get();
      tables[name] = rows.map((r) => _jsonSafeRow(r.data)).toList();
    }
    return tables;
  }

  List<int> _encodeModulesJson(
    List<String> modules,
    Map<String, List<Map<String, dynamic>>> tables,
  ) {
    final backup = <String, dynamic>{
      'formatVersion': backupFormatVersion,
      'schemaVersion': _db.schemaVersion,
      'exportedAt': DateTime.now().toIso8601String(),
      'modules': modules,
      'tables': tables,
    };
    return utf8.encode(const JsonEncoder.withIndent('  ').convert(backup));
  }

  String _toCsv(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) return '';
    final cols = rows.first.keys.toList();
    final sb = StringBuffer()..writeln(cols.map(_csvCell).join(','));
    for (final row in rows) {
      sb.writeln(cols.map((c) => _csvCell(row[c])).join(','));
    }
    return sb.toString();
  }

  String _csvCell(dynamic value) {
    if (value == null) return '';
    var s = value is Map ? jsonEncode(value) : value.toString();
    if (s.contains(',') ||
        s.contains('"') ||
        s.contains('\n') ||
        s.contains('\r')) {
      s = '"${s.replaceAll('"', '""')}"';
    }
    return s;
  }

  // ─── Import ──────────────────────────────────────────────────────────────────

  /// Lets the user pick a backup ZIP and merges it into the database.
  Future<ImportResult> importBackup() async {
    final bytes = await pickBackupFile();
    if (bytes == null) {
      return const ImportResult(cancelled: true);
    }
    return restoreFromBytes(bytes);
  }

  /// Opens the file picker only, without restoring anything yet. Split out
  /// from [importBackup] so callers can show a progress indicator around
  /// just the (potentially slow) [restoreFromBytes] step, not the native
  /// file-picker UI. Returns `null` if the user cancelled or the file
  /// couldn't be read.
  Future<List<int>?> pickBackupFile() async {
    final picked = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['zip', 'json'],
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) {
      return null;
    }
    final file = picked.files.single;
    return file.bytes ??
        (file.path != null ? await File(file.path!).readAsBytes() : null);
  }

  /// Restores a backup from raw ZIP bytes. Public so it can be unit-tested.
  Future<ImportResult> restoreFromBytes(List<int> bytes) async {
    try {
      // A ZIP starts with the local file header magic "PK"\x03\x04; anything
      // else is treated as a plain JSON backup (selective JSON export).
      final isZip = bytes.length >= 2 && bytes[0] == 0x50 && bytes[1] == 0x4B;
      Archive? archive;
      Map<String, dynamic> backup;
      if (isZip) {
        // Same reasoning as the export side: decoding a large archive is
        // synchronous, CPU-bound work — off the UI isolate so a big import
        // doesn't look like a frozen app either.
        archive = await compute(_decodeZipArchive, Uint8List.fromList(bytes));
        final jsonFile = archive!.findFile(_jsonEntryName);
        if (jsonFile == null) {
          return const ImportResult(error: 'No backup.json in archive');
        }
        backup = jsonDecode(utf8.decode(jsonFile.content as List<int>))
            as Map<String, dynamic>;
      } else {
        backup = jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
      }

      final format = backup['formatVersion'] as int? ?? 0;
      if (format > backupFormatVersion) {
        return ImportResult(
          error: 'Backup format v$format is newer than supported '
              'v$backupFormatVersion',
        );
      }
      final backupSchema = backup['schemaVersion'] as int? ?? 0;
      if (backupSchema > _db.schemaVersion) {
        return ImportResult(
          error: 'Backup schema v$backupSchema is newer than app '
              'schema v${_db.schemaVersion}',
        );
      }

      // Restore media files and build originalPath -> newPath map (ZIP only).
      final pathRewrite = archive != null
          ? await _restoreMedia(archive, backup)
          : const <String, String>{};

      final tablesJson =
          (backup['tables'] as Map).cast<String, dynamic>();
      final tablesByName = _tablesByName;

      var rowCount = 0;
      // FK enforcement must be toggled outside a transaction to take effect.
      await _db.customStatement('PRAGMA foreign_keys = OFF');
      try {
        await _db.transaction(() async {
          for (final tableEntry in tablesJson.entries) {
            final table = tablesByName[tableEntry.key];
            if (table == null) continue; // table no longer exists
            final knownCols = {for (final c in table.$columns) c.name};
            final rows = (tableEntry.value as List).cast<dynamic>();
            for (final raw in rows) {
              final row = (raw as Map).cast<String, dynamic>();
              final cols = <String>[];
              final values = <Variable>[];
              row.forEach((col, value) {
                if (!knownCols.contains(col)) return; // dropped column
                var v = value;
                if (v is Map && v.containsKey('__blob__')) {
                  v = base64Decode(v['__blob__'] as String);
                } else if (v is String && pathRewrite.containsKey(v)) {
                  v = pathRewrite[v];
                }
                cols.add(col);
                values.add(Variable(v));
              });
              if (cols.isEmpty) continue;
              final colList = cols.map((c) => '"$c"').join(', ');
              final placeholders = List.filled(cols.length, '?').join(', ');
              await _db.customInsert(
                'INSERT OR REPLACE INTO "${tableEntry.key}" '
                '($colList) VALUES ($placeholders)',
                variables: values,
                updates: {table},
              );
              rowCount++;
            }
          }
        });
      } finally {
        await _db.customStatement('PRAGMA foreign_keys = ON');
      }

      return ImportResult(
        success: true,
        rowCount: rowCount,
        mediaCount: pathRewrite.length,
      );
    } catch (e) {
      // Best-effort: make sure FKs are back on even if we threw early.
      try {
        await _db.customStatement('PRAGMA foreign_keys = ON');
      } catch (_) {}
      return ImportResult(error: e.toString());
    }
  }

  /// Extracts bundled media into the app documents directory and returns a map
  /// of original stored path -> new absolute path.
  Future<Map<String, String>> _restoreMedia(
    Archive archive,
    Map<String, dynamic> backup,
  ) async {
    final manifest = (backup['media'] as List?) ?? const [];
    if (manifest.isEmpty) return {};

    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docs.path, _restoredMediaDir));
    await mediaDir.create(recursive: true);

    final rewrite = <String, String>{};
    for (final item in manifest) {
      final m = (item as Map).cast<String, dynamic>();
      final original = m['original'] as String?;
      final entryName = m['entry'] as String?;
      if (original == null || entryName == null) continue;
      final file = archive.findFile(entryName);
      if (file == null) continue;
      final dest = File(p.join(mediaDir.path, p.basename(entryName)));
      await dest.writeAsBytes(file.content as List<int>);
      rewrite[original] = dest.path;
    }
    return rewrite;
  }

  /// Converts a raw SQLite row into JSON-safe values (base64 for any BLOBs).
  Map<String, dynamic> _jsonSafeRow(Map<String, dynamic> data) {
    return data.map((key, value) {
      if (value is Uint8List) {
        return MapEntry(key, {'__blob__': base64Encode(value)});
      }
      return MapEntry(key, value);
    });
  }
}
