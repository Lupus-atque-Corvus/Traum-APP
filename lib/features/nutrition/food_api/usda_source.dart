import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../data/preferences/preferences_repository.dart';
import 'food_source.dart';

const _usdaSearchUrl = 'https://api.nal.usda.gov/fdc/v1/foods/search';

// USDA FoodData Central nutrient IDs used for parsing `foodNutrients`.
const _kcalId = 1008;
const _proteinId = 1003;
const _carbsId = 1005;
const _fatId = 1004;
const _sugarId = 2000;
const _fiberId = 1079;
const _sodiumId = 1093;

/// USDA FoodData Central Textsuche. Keyless per Default (DEMO_KEY).
class UsdaSource implements FoodSource {
  final PreferencesRepository _prefs;

  UsdaSource(this._prefs);

  @override
  String get id => 'usda';

  @override
  Future<List<FoodSearchResult>> search(String query) async {
    try {
      final uri = Uri.parse(_usdaSearchUrl).replace(queryParameters: {
        'api_key': _prefs.usdaApiKey,
        'query': query,
        'pageSize': '20',
        'dataType': 'Foundation,SR Legacy',
      });
      final response = await http
          .get(uri, headers: {'User-Agent': 'TRAUM-App/1.0'})
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return [];
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return parseUsdaSearch(json);
    } catch (e) {
      debugPrint('UsdaSource search error: $e');
      return [];
    }
  }
}

/// Parst die JSON-Antwort der USDA-Textsuche in [FoodSearchResult]s.
/// Pure und testbar (kein HTTP). Defensiv gegen fehlende/kaputte Felder —
/// wirft nie, überspringt lediglich unbrauchbare Einträge.
List<FoodSearchResult> parseUsdaSearch(Map json) {
  final foods = json['foods'];
  if (foods is! List) return [];

  final results = <FoodSearchResult>[];
  for (final entry in foods) {
    if (entry is! Map) continue;
    final name = (entry['description'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    final nutrients = <int, double>{};
    final foodNutrients = entry['foodNutrients'];
    if (foodNutrients is List) {
      for (final nutrient in foodNutrients) {
        if (nutrient is! Map) continue;
        final nutrientId = nutrient['nutrientId'];
        final value = _usdaD(nutrient['value']);
        if (nutrientId is! int || value == null) continue;
        nutrients[nutrientId] = value;
      }
    }

    final sodium = nutrients[_sodiumId];

    final fdcId = entry['fdcId'];

    results.add(FoodSearchResult(
      name: name,
      kcalPer100g: nutrients[_kcalId] ?? 0,
      proteinPer100g: nutrients[_proteinId] ?? 0,
      carbsPer100g: nutrients[_carbsId] ?? 0,
      fatPer100g: nutrients[_fatId] ?? 0,
      sugarPer100g: nutrients[_sugarId],
      fiberPer100g: nutrients[_fiberId],
      saltPer100g: sodium != null ? sodium * 2.5 / 1000 : null,
      source: 'usda',
      sourceId: fdcId?.toString(),
    ));
  }
  return results;
}

double? _usdaD(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
