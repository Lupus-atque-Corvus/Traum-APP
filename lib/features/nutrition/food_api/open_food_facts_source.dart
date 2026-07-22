import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'food_source.dart';

const _offSearchUrl = 'https://world.openfoodfacts.org/cgi/search.pl';

/// OpenFoodFacts-Textsuche. Keyless (öffentliche API).
///
/// Der öffentliche `cgi/search.pl`-Endpunkt liefert nachweislich (extern
/// gegengeprüft) nicht immer 200/JSON zurück — vereinzelte Anfragen werden
/// von OFFs Bot-/Rate-Limit-Schutz stattdessen mit einer HTML-Fehlerseite
/// (Status 503, "temporarily unavailable") beantwortet, obwohl dieselbe
/// Anfrage kurz davor/danach normal funktioniert. Ein einzelner Fehlversuch
/// pro Suche würde sich für den Nutzer wie "Suche funktioniert nicht" anfühlen
/// — ein kurzer Retry behebt die meisten dieser transienten Fälle.
class OpenFoodFactsSource implements FoodSource {
  @override
  String get id => 'off';

  @override
  Future<List<FoodSearchResult>> search(String query) async {
    for (var attempt = 0; attempt < 2; attempt++) {
      if (attempt > 0) {
        await Future.delayed(const Duration(milliseconds: 600));
      }
      try {
        final uri = Uri.parse(_offSearchUrl).replace(queryParameters: {
          'search_terms': query,
          'search_simple': '1',
          'action': 'process',
          'json': '1',
          'page_size': '20',
          'fields':
              'product_name,brands,code,image_thumb_url,nutriments',
        });
        final response = await http.get(uri, headers: {
          'User-Agent':
              'Mozilla/5.0 (Linux; Android) TRAUM-App/1.0 (+https://github.com/Lupus-atque-Corvus/Traum-APP)',
        }).timeout(const Duration(seconds: 8));

        if (response.statusCode != 200) continue;
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return parseOffSearch(json);
      } catch (e) {
        debugPrint('OpenFoodFactsSource search error (attempt $attempt): $e');
      }
    }
    return [];
  }
}

/// Parst die JSON-Antwort der OFF-Textsuche in [FoodSearchResult]s.
/// Pure und testbar (kein HTTP). Defensiv gegen fehlende/kaputte Felder —
/// wirft nie, überspringt lediglich unbrauchbare Einträge.
List<FoodSearchResult> parseOffSearch(Map json) {
  final products = json['products'];
  if (products is! List) return [];

  final results = <FoodSearchResult>[];
  for (final entry in products) {
    if (entry is! Map) continue;
    final name = (entry['product_name'] as String?)?.trim();
    if (name == null || name.isEmpty) continue;

    final nutriments = entry['nutriments'];
    final n = nutriments is Map ? nutriments : const {};

    final code = entry['code'] as String?;

    results.add(FoodSearchResult(
      name: name,
      brand: entry['brands'] as String?,
      kcalPer100g: _offD(n['energy-kcal_100g']) ?? 0,
      proteinPer100g: _offD(n['proteins_100g']) ?? 0,
      carbsPer100g: _offD(n['carbohydrates_100g']) ?? 0,
      fatPer100g: _offD(n['fat_100g']) ?? 0,
      sugarPer100g: _offD(n['sugars_100g']),
      fiberPer100g: _offD(n['fiber_100g']),
      saltPer100g: _offD(n['salt_100g']),
      source: 'off',
      sourceId: code,
      barcode: code,
      imageUrl: entry['image_thumb_url'] as String?,
    ));
  }
  return results;
}

double? _offD(dynamic v) {
  if (v == null) return null;
  if (v is double) return v;
  if (v is int) return v.toDouble();
  if (v is String) return double.tryParse(v);
  return null;
}
