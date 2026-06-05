import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Kapselt den nativen `traum/launcher`-Channel (Android) für das
/// experimentelle Feature „TRAUM als Standard-Home-App".
///
/// Alle Aufrufe sind fehlertolerant: Bei Plattformfehlern oder auf
/// Nicht-Android-Plattformen liefert [isDefaultLauncher] `false` und
/// [requestSetDefault] ist ein No-op.
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

  /// Öffnet den System-Auswahldialog, um TRAUM als Home-App festzulegen.
  Future<void> requestSetDefault() async {
    try {
      await _channel.invokeMethod<void>('requestSetDefaultLauncher');
    } catch (_) {
      // Bewusst geschluckt — UI bleibt robust.
    }
  }
}

final launcherServiceProvider =
    Provider<LauncherService>((ref) => LauncherService());
