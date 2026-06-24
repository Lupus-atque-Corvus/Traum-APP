/// Globaler UI-Skalierungsfaktor für den Budget-Bereich.
///
/// Die `PIXELGENAUE_SPEZIFIKATION.md` übernimmt CSS-px aus einem 374px breiten
/// Prototyp 1:1. Auf realen (breiteren) Geräten wirkt das dicht/klein. Dieser
/// Faktor skaliert alle Budget-Design-Maße (Schriftgrößen, Icon-Container,
/// Paddings, Radien, Abstände) einheitlich hoch — bewusster, zentral steuerbarer
/// Bruch der 1:1-Pixeltreue zugunsten der Lesbarkeit.
///
/// NICHT skaliert werden: Alpha/Opazität, `flex`, Animationsdauern, Zähler.
const double kBudgetScale = 1.12;

/// Skaliert einen Budget-Design-Maßwert (px → skalierte Logikpixel).
double bs(num value) => value * kBudgetScale;
