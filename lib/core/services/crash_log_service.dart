import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Lokales Absturz-/Fehler-Logging ohne Cloud-Dienst — schreibt uncaught
/// Fehler (Flutter-Framework, Platform-Dispatcher, Dart-Zone) als
/// Klartext-Zeilen in eine lokale Logdatei. Ersetzt keine echte
/// Crash-Reporting-Infrastruktur (kein Dashboard, keine Symbolication),
/// reicht aber aus, um nach einem gemeldeten Absturz die Ursache aus dem
/// exportierten Backup zu rekonstruieren, ohne dass der Nutzer erst
/// `adb logcat` mitschneiden muss — siehe [readForExport], eingebunden in
/// `BackupService.buildBackupZip`.
class CrashLogService {
  CrashLogService._();

  static const _fileName = 'crash_log.txt';
  static const _maxBytes = 1024 * 1024; // 1 MB, danach wird rotiert

  static File? _file;

  static Future<File> _logFile() async {
    final cached = _file;
    if (cached != null) return cached;
    final dir = await getApplicationSupportDirectory();
    final file = File('${dir.path}/$_fileName');
    _file = file;
    return file;
  }

  /// Registriert die Flutter-Framework- und Platform-Dispatcher-Fehler-
  /// Handler. Muss vor `runApp()` aufgerufen werden (innerhalb der von
  /// [runGuarded] geöffneten Zone).
  static void installFrameworkHandlers() {
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (FlutterErrorDetails details) {
      previousOnError?.call(details);
      unawaited(
          _append('FLUTTER', details.exceptionAsString(), details.stack));
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      unawaited(_append('PLATFORM', error.toString(), stack));
      return true;
    };
  }

  /// Wickelt [body] (üblicherweise der komplette `main()`-Rumpf inkl.
  /// `runApp()`) in eine `runZonedGuarded`-Zone — fängt so auch Fehler in
  /// nicht-awaiteten Futures außerhalb des Flutter-Fehlerpfads ab.
  static void runGuarded(FutureOr<void> Function() body) {
    runZonedGuarded(body, (error, stack) {
      unawaited(_append('ZONE', error.toString(), stack));
    });
  }

  static Future<void> _append(
      String source, String message, StackTrace? stack) async {
    try {
      final file = await _logFile();
      if (await file.exists() && await file.length() > _maxBytes) {
        // Einfache Rotation statt unbegrenztem Wachstum — für
        // Diagnosezwecke reicht der jeweils letzte ~1 MB.
        await file.writeAsString('', mode: FileMode.write);
      }
      final buffer = StringBuffer()
        ..writeln('[${DateTime.now().toIso8601String()}] [$source] $message');
      if (stack != null) buffer.writeln(stack.toString());
      buffer.writeln('---');
      await file.writeAsString(buffer.toString(),
          mode: FileMode.append, flush: true);
    } catch (_) {
      // Logging selbst darf nie einen weiteren, unbehandelten Fehler
      // auslösen — bewusst still.
    }
  }

  /// Aktueller Loginhalt für den Backup-Export, oder `null` falls (noch)
  /// keine Datei existiert oder sie leer ist.
  static Future<Uint8List?> readForExport() async {
    try {
      final file = await _logFile();
      if (!await file.exists()) return null;
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) return null;
      return Uint8List.fromList(bytes);
    } catch (_) {
      return null;
    }
  }

  /// Schreibt direkt einen Log-Eintrag, ohne über `runGuarded`/den
  /// Framework-Handler zu gehen — für deterministische Tests der
  /// Rotations-/Lese-Logik ohne Zeitabhängigkeit auf einen echten Zone-Fehler.
  @visibleForTesting
  static Future<void> logForTest(String source, String message,
          [StackTrace? stack]) =>
      _append(source, message, stack);

  /// Setzt den gecachten Dateipfad zurück — nötig, damit Tests mit
  /// wechselndem `PathProviderPlatform.instance` (je ein frisches Temp-Dir
  /// pro Testfall) nicht versehentlich den Pfad des vorherigen Testfalls
  /// weiterverwenden.
  @visibleForTesting
  static void debugResetForTest() => _file = null;
}
