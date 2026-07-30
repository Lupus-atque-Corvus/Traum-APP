import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Kopiert die gebundelte Substanz-Referenzdatenbank (`assets/substances_reference.sqlite3`,
/// ~71 MB) EINMALIG als ganze Datei in den App-Speicher — im Gegensatz zum alten
/// `SubstanceDatabaseCopier`, der Zeile für Zeile in die Drift-DB importiert hat.
/// Das erlaubt read-only Direktzugriff samt vorgebautem FTS5-Index über
/// [SubstanceReferenceDbService], ohne 71 MB zusätzlich in `traum.sqlite` zu duplizieren.
///
/// Versionierung: der Suffix `_v2` im Flag-Namen ist der Recopy-Mechanismus.
/// Wird ein künftiges Datenbank-Update ausgeliefert (neue `substances_reference.sqlite3`
/// im Asset-Bundle), muss der Suffix erhöht werden (`_v2` -> `_v3`), damit alle
/// bestehenden Installationen die neue Datei beim nächsten Start erneut kopieren.
class SubstanceReferenceDbCopier {
  static const _copiedKey = 'substance_reference_db_copied_v2';
  static const _fileName = 'substances_reference.sqlite3';

  static Future<String> targetPath() async {
    final dir = await getApplicationDocumentsDirectory();
    return p.join(dir.path, _fileName);
  }

  static Future<void> copyIfNeeded(SharedPreferences prefs) async {
    if (prefs.getBool(_copiedKey) == true) return;

    try {
      final bytes = await rootBundle.load('assets/$_fileName');
      final target = File(await targetPath());
      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      await prefs.setBool(_copiedKey, true);
    } catch (_) {
      // Copy fails atomically — next start retries.
    }
  }
}
