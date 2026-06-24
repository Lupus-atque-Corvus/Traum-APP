import 'package:flutter/widgets.dart';

/// Globaler UI-Skalierungsfaktor für den Budget-Bereich.
///
/// Die `PIXELGENAUE_SPEZIFIKATION.md` übernimmt CSS-px aus einem 374px breiten
/// Prototyp 1:1. Auf realen (breiteren) Geräten wirkt das dicht/klein. Dieser
/// Faktor skaliert alle Budget-Design-Maße einheitlich hoch — bewusster, zentral
/// steuerbarer Bruch der 1:1-Pixeltreue zugunsten der Lesbarkeit.
///
/// - Schriftgrößen: über [BudgetTextScale] (komponiert mit der System-Textgröße).
/// - Struktur-Maße (Icon-Container, Paddings, Radien, Abstände): über [bs].
///
/// NICHT skaliert: Alpha/Opazität, `flex`, Animationsdauern, Zähler, Ratios.
const double kBudgetScale = 1.12;

/// Skaliert einen Budget-Struktur-Maßwert (px → skalierte Logikpixel).
double bs(num value) => value * kBudgetScale;

/// Hebt alle Schriftgrößen im Teilbaum um [kBudgetScale] an, ohne die
/// vom Nutzer eingestellte System-Textskalierung zu ignorieren (komponiert
/// beide Faktoren). Um jeden Budget-Screen-Body bzw. jedes Bottom-Sheet legen.
class BudgetTextScale extends StatelessWidget {
  final Widget child;
  const BudgetTextScale({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    // mq.textScaler.scale(1) ≈ aktueller System-Linearfaktor.
    final system = mq.textScaler.scale(1);
    return MediaQuery(
      data: mq.copyWith(
        textScaler: TextScaler.linear(kBudgetScale * system),
      ),
      child: child,
    );
  }
}
