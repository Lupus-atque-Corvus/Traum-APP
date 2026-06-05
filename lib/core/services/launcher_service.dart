import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kapselt den nativen `traum/launcher`-Channel (Android) für das
/// experimentelle Feature „TRAUM als Standard-Home-App".
///
/// Alle Aufrufe sind fehlertolerant: Bei Plattformfehlern oder auf
/// Nicht-Android-Plattformen liefert [isDefaultLauncher] `false` und
/// [requestSetDefault] `false`.
class LauncherService {
  static const _channel = MethodChannel('traum/launcher');

  /// `true`, wenn TRAUM aktuell die Standard-Home-App ist.
  Future<bool> isDefaultLauncher() async {
    try {
      final res = await _channel.invokeMethod<bool>('isDefaultLauncher');
      return res ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Öffnet die System-Einstellung zur Auswahl der Standard-Home-App.
  /// `true`, wenn die Einstellungsseite geöffnet werden konnte; sonst `false`
  /// (z. B. Plattformfehler oder keine passende Einstellungsseite vorhanden).
  Future<bool> requestSetDefault() async {
    try {
      final ok = await _channel.invokeMethod<bool>('requestSetDefaultLauncher');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}

final launcherServiceProvider =
    Provider<LauncherService>((ref) => LauncherService());
