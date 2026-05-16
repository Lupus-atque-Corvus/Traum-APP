// Quellen:
// EFSA (2010): Adequate Intake 2.0L/Tag Frauen, 2.5L/Tag Männer
// DGE (Deutsche Gesellschaft für Ernährung): ~35 ml/kg KG/Tag als Faustregel
// WHO: Mindestbedarf ~1.5–2.0 L/Tag für Erwachsene
// Hyponatriämie-Schwelle: >1 L/h oder >15 L/Tag ist gefährlich — Noakes et al. 2005, CJASN

class WaterCalculator {
  /// Empfohlenes Tagesziel (Trinkmenge, ohne Mahlzeiten)
  /// Basis: 35 ml/kg KG/Tag (DGE), leichte Alterskorrektur
  static int recommendedMl(double weightKg, int age, String sex) {
    double base = weightKg * 35;
    // Über 55: leicht reduziert da Durstempfinden nachlässt (EFSA)
    if (age > 55) base *= 0.95;
    // Frauen: etwas weniger als Männer (EFSA AI: 2.0L vs 2.5L)
    if (sex == 'female') base *= 0.92;
    return base.round().clamp(1500, 4000);
  }

  /// Minimum: Unter diesem Wert besteht Dehydrations-Risiko
  /// Basis: WHO Mindestbedarf ~1.5L, EFSA Lower Reference Value
  static int minimumMl(double weightKg, String sex) {
    final base = sex == 'female' ? 1600 : 1800;
    return base;
  }

  /// Maximum: Obergrenze die nicht überschritten werden kann
  /// Basis: Hyponatriämie-Risiko steigt ab hohen Mengen — Noakes et al. 2005
  /// Konservative Obergrenze: 40 ml/kg KG/Tag, max 5.000 ml
  static int maximumMl(double weightKg) {
    return (weightKg * 40).round().clamp(3000, 5000);
  }
}
