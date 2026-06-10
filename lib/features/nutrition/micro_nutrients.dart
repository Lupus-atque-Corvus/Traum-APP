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
      return MicroNutrients(Map.unmodifiable({
        for (final e in decoded.entries) e.key: (e.value as num).toDouble(),
      }));
    } catch (_) {
      return const MicroNutrients({});
    }
  }

  String toJson() => jsonEncode(values);

  String? toNullableJson() => values.isEmpty ? null : jsonEncode(values);

  MicroNutrients operator +(MicroNutrients other) {
    final result = Map<String, double>.from(values);
    other.values.forEach((k, v) => result[k] = (result[k] ?? 0) + v);
    return MicroNutrients(Map.unmodifiable(result));
  }

  MicroNutrients scale(double factor) => MicroNutrients(Map.unmodifiable(
      {for (final e in values.entries) e.key: e.value * factor}));

  double? operator [](String key) => values[key];
}

/// Rechnet eine Supplement-Dosis in die kanonische Einheit des Nährstoffs um.
/// Gibt null zurück, wenn die Einheit nicht umrechenbar ist.
double? normalizeDose(double amount, String unit, String key) {
  final meta = kNutrientByKey[key];
  if (meta == null) return null;
  final canonical = meta.unit; // 'g' | 'mg' | 'µg'
  final u = unit.trim().toLowerCase();

  // Quelle → Gramm
  double? grams;
  switch (u) {
    case 'g':
      grams = amount;
      break;
    case 'mg':
      grams = amount / 1000;
      break;
    case 'µg':
    case 'mcg':
    case 'ug':
      grams = amount / 1000000;
      break;
    case 'iu':
      // Nur Vitamin D unterstützt: 1 µg = 40 IU.
      if (key != 'vitD') return null;
      grams = (amount / 40) / 1000000;
      break;
    default:
      return null; // Kapsel, Tablette, ml, Messbecher …
  }

  // Gramm → kanonische Einheit
  switch (canonical) {
    case 'g':
      return grams;
    case 'mg':
      return grams * 1000;
    case 'µg':
      return grams * 1000000;
    default:
      return null;
  }
}

const Map<String, List<String>> _kNutrientSynonyms = {
  'vitC': ['vitamin c', 'ascorbin', 'ascorbic'],
  'vitD': ['vitamin d', 'd3', 'd2', 'cholecalciferol', 'calciferol'],
  'vitB12': ['b12', 'cobalamin'],
  'calcium': ['calcium', 'kalzium'],
  'iron': ['eisen', 'iron', 'ferro', 'bisglycinat'],
  'magnesium': ['magnesium'],
  'zinc': ['zink', 'zinc'],
  'potassium': ['kalium', 'potassium'],
  'sugar': ['zucker'],
  'fiber': ['ballaststoff', 'fiber'],
};

/// Schlägt anhand des Namens einen Nährstoff-Key vor (oder null).
String? suggestNutrientKey(String name) {
  final n = name.toLowerCase();
  for (final entry in _kNutrientSynonyms.entries) {
    for (final syn in entry.value) {
      if (n.contains(syn)) return entry.key;
    }
  }
  return null;
}

/// Beitrag eines Supplements zu den Tages-Mikros (leer, wenn nicht zuordenbar).
MicroNutrients supplementContribution({
  String? nutrientKey,
  String? dosageAmount,
  String? dosageUnit,
}) {
  if (nutrientKey == null || dosageAmount == null || dosageUnit == null) {
    return MicroNutrients.empty;
  }
  final amount = double.tryParse(dosageAmount.replaceAll(',', '.'));
  if (amount == null) return MicroNutrients.empty;
  final value = normalizeDose(amount, dosageUnit, nutrientKey);
  if (value == null) return MicroNutrients.empty;
  return MicroNutrients({nutrientKey: value});
}

/// Baut die Panel-Mikros (vitC…potassium) aus einem OFF-`nutriments`-Map.
MicroNutrients offProductMicros(Map<String, dynamic> nutriments) {
  final out = <String, double>{};
  for (final meta in kNutrientCatalog) {
    final offKey = meta.offKey;
    if (offKey == null) continue;
    final raw = nutriments[offKey];
    final grams = raw is num
        ? raw.toDouble()
        : (raw is String ? double.tryParse(raw) : null);
    if (grams == null) continue;
    out[meta.key] = grams * meta.offFactor;
  }
  return MicroNutrients(out);
}
