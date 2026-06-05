/// Berechnet den Ziel-Index beim horizontalen Wischen des Tab-Switchers
/// mit distanz-abhängiger Beschleunigung.
///
/// [dx] = horizontale Verschiebung seit Gestenbeginn in px (rechts positiv),
/// [startIndex] = Index zu Beginn der Geste, [count] = Anzahl der Module.
///
/// Kennlinie (zwei Gänge):
/// - Präzise (|dx| <= [threshold]): 1 Tab pro [base] px.
/// - Schnell (|dx| > [threshold]): zusätzlich 1 Tab pro [fastStep] px.
///
/// Das Ergebnis ist auf `[0, count-1]` begrenzt (kein Umlauf). Bei
/// [count] <= 0 wird 0 zurückgegeben.
int switcherIndexFor({
  required double dx,
  required int startIndex,
  required int count,
  double base = 24,
  double threshold = 96,
  double fastStep = 10,
}) {
  if (count <= 0) return 0;
  final mag = dx.abs();
  final double steps = mag <= threshold
      ? mag / base
      : threshold / base + (mag - threshold) / fastStep;
  final delta = (dx.isNegative ? -steps : steps).round();
  return (startIndex + delta).clamp(0, count - 1);
}
