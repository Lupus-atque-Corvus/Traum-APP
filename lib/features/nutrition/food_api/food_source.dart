/// Ein einzelnes Suchergebnis aus einer externen (oder lokalen) Lebensmittel-Quelle.
///
/// Wird von [FoodSource]-Implementierungen produziert; die Aggregation/Dedupe
/// über mehrere Quellen hinweg passiert NICHT hier (siehe Task 6.3).
class FoodSearchResult {
  final String name;
  final String? brand;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? sugarPer100g;
  final double? fiberPer100g;
  final double? saltPer100g;

  /// 'local' | 'off' | 'usda'
  final String source;

  /// z.B. OFF-Barcode, USDA fdcId (als String).
  final String? sourceId;
  final String? barcode;
  final String? imageUrl;

  const FoodSearchResult({
    required this.name,
    this.brand,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.sugarPer100g,
    this.fiberPer100g,
    this.saltPer100g,
    required this.source,
    this.sourceId,
    this.barcode,
    this.imageUrl,
  });

  /// 0..1 — Anteil gefüllter Nährwertfelder (für Ranking).
  ///
  /// Berücksichtigt werden 7 Nährwertfelder: kcal, Protein, Kohlenhydrate,
  /// Fett, Zucker, Ballaststoffe, Salz. Die vier Pflichtfelder (kcal/
  /// Protein/Kohlenhydrate/Fett) zählen als "gefüllt", sobald sie != 0 sind
  /// (0 ist der Default bei fehlenden Werten und damit nicht aussagekräftig);
  /// die drei optionalen Felder (Zucker/Ballaststoffe/Salz) zählen als
  /// gefüllt, wenn sie nicht null sind.
  double get completeness {
    const totalFields = 7;
    var filled = 0;
    if (kcalPer100g != 0) filled++;
    if (proteinPer100g != 0) filled++;
    if (carbsPer100g != 0) filled++;
    if (fatPer100g != 0) filled++;
    if (sugarPer100g != null) filled++;
    if (fiberPer100g != null) filled++;
    if (saltPer100g != null) filled++;
    return filled / totalFields;
  }
}

/// Abstraktion über externe Lebensmittel-Text-Suchen (OpenFoodFacts, USDA, …).
///
/// Implementierungen MÜSSEN bei Netzwerkfehlern/Timeouts eine leere Liste
/// zurückgeben statt zu werfen (offline-first / graceful degradation).
abstract class FoodSource {
  /// Stabiler Bezeichner der Quelle, z.B. 'off' oder 'usda'.
  String get id;

  Future<List<FoodSearchResult>> search(String query);
}
