/// Berechnet den Ziel-Index beim horizontalen Wischen des Tab-Switchers.
///
/// [dx] = horizontale Verschiebung seit Gestenbeginn in px (rechts positiv),
/// [startIndex] = Index zu Beginn der Geste, [count] = Anzahl der Module,
/// [step] = px pro Modulschritt. Das Ergebnis ist auf `[0, count-1]` begrenzt
/// (kein Umlauf). Bei [count] <= 0 wird 0 zurückgegeben.
int switcherIndexFor({
  required double dx,
  required int startIndex,
  required int count,
  double step = 32,
}) {
  if (count <= 0) return 0;
  final delta = (dx / step).round();
  final raw = startIndex + delta;
  return raw.clamp(0, count - 1);
}
