import 'package:flutter/material.dart';

import '../theme/colors.dart';

/// Kompakte, bewusst unaufdringliche Fehleranzeige für fehlgeschlagene
/// Provider — als Ersatz für `error: (_, _) => const SizedBox.shrink()`.
///
/// **Warum das nötig ist:** Ein als leerer Platz gerenderter Fehler ist von
/// „noch keine Daten vorhanden" nicht zu unterscheiden. Genau daran hing der
/// „Budget-Screen ist schwarz"-Fehler, dessen Ursache zwei komplette
/// Release-Runden gekostet hat (v0.7.27/v0.7.28): Das Scheitern sah aus wie
/// eine leere Fläche, nicht wie ein Fehler.
///
/// Bewusst nur ein 16-px-Symbol statt einer Textzeile: Die Ersetzung betrifft
/// über 50 Stellen, viele davon in engen Zeilen und Kacheln — ein Symbol passt
/// überall hinein, ohne Layouts zu sprengen. Die Fehlermeldung selbst steckt
/// im Tooltip (langes Drücken) und geht zusätzlich ins Log, damit sie per
/// `adb logcat` auffindbar ist.
class InlineError extends StatelessWidget {
  final Object? error;

  /// Optionaler Hinweis, welcher Bereich betroffen ist — taucht im Log auf.
  final String? context;

  const InlineError(this.error, {super.key, this.context});

  @override
  Widget build(BuildContext buildContext) {
    assert(() {
      debugPrint('InlineError${context != null ? " ($context)" : ""}: $error');
      return true;
    }());
    return Tooltip(
      message: error?.toString() ?? 'Unbekannter Fehler',
      triggerMode: TooltipTriggerMode.longPress,
      child: const Icon(
        Icons.error_outline,
        size: 16,
        color: TraumColors.onBackgroundSubtle,
      ),
    );
  }
}
