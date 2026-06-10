import 'dart:convert';

/// Metadaten zu einem getrackten Nährstoff.
class NutrientMeta {
  final String key;
  final String label;
  final String unit; // 'g' | 'mg' | 'µg'
  final double dailyRef;
  final String? offKey; // OpenFoodFacts nutriment key (nur Panel-Nährstoffe)
  final double offFactor; // OFF liefert Gramm → × offFactor = kanonische Einheit
  final int order;

  const NutrientMeta({
    required this.key,
    required this.label,
    required this.unit,
    required this.dailyRef,
    required this.order,
    this.offKey,
    this.offFactor = 1,
  });
}

/// Zentraler Katalog. Reihenfolge = Anzeige-Reihenfolge.
const List<NutrientMeta> kNutrientCatalog = [
  NutrientMeta(key: 'sugar', label: 'Zucker', unit: 'g', dailyRef: 50, order: 0),
  NutrientMeta(key: 'fiber', label: 'Ballaststoffe', unit: 'g', dailyRef: 30, order: 1),
  NutrientMeta(key: 'satFat', label: 'Ges. Fettsäuren', unit: 'g', dailyRef: 20, order: 2),
  NutrientMeta(key: 'salt', label: 'Salz', unit: 'g', dailyRef: 6, order: 3),
  NutrientMeta(key: 'vitC', label: 'Vitamin C', unit: 'mg', dailyRef: 90, order: 4, offKey: 'vitamin-c_100g', offFactor: 1000),
  NutrientMeta(key: 'vitD', label: 'Vitamin D', unit: 'µg', dailyRef: 20, order: 5, offKey: 'vitamin-d_100g', offFactor: 1000000),
  NutrientMeta(key: 'vitB12', label: 'Vitamin B12', unit: 'µg', dailyRef: 4, order: 6, offKey: 'vitamin-b12_100g', offFactor: 1000000),
  NutrientMeta(key: 'calcium', label: 'Calcium', unit: 'mg', dailyRef: 1000, order: 7, offKey: 'calcium_100g', offFactor: 1000),
  NutrientMeta(key: 'iron', label: 'Eisen', unit: 'mg', dailyRef: 14, order: 8, offKey: 'iron_100g', offFactor: 1000),
  NutrientMeta(key: 'magnesium', label: 'Magnesium', unit: 'mg', dailyRef: 400, order: 9, offKey: 'magnesium_100g', offFactor: 1000),
  NutrientMeta(key: 'zinc', label: 'Zink', unit: 'mg', dailyRef: 10, order: 10, offKey: 'zinc_100g', offFactor: 1000),
  NutrientMeta(key: 'potassium', label: 'Kalium', unit: 'mg', dailyRef: 3500, order: 11, offKey: 'potassium_100g', offFactor: 1000),
];

final Map<String, NutrientMeta> kNutrientByKey = {
  for (final n in kNutrientCatalog) n.key: n
};

/// Map key→Wert in kanonischer Einheit. Nur vorhandene Keys = „erfasst".
class MicroNutrients {
  final Map<String, double> values;
  const MicroNutrients(this.values);

  static const empty = MicroNutrients({});

  factory MicroNutrients.fromJson(String? json) {
    if (json == null || json.isEmpty) return const MicroNutrients({});
    try {
      final decoded = jsonDecode(json) as Map<String, dynamic>;
      return MicroNutrients({
        for (final e in decoded.entries) e.key: (e.value as num).toDouble(),
      });
    } catch (_) {
      return const MicroNutrients({});
    }
  }

  String toJson() => jsonEncode(values);

  String? toNullableJson() => values.isEmpty ? null : jsonEncode(values);

  MicroNutrients operator +(MicroNutrients other) {
    final result = Map<String, double>.from(values);
    other.values.forEach((k, v) => result[k] = (result[k] ?? 0) + v);
    return MicroNutrients(result);
  }

  MicroNutrients scale(double factor) =>
      MicroNutrients({for (final e in values.entries) e.key: e.value * factor});

  double? operator [](String key) => values[key];
}
