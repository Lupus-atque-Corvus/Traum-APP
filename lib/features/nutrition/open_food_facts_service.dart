import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:drift/drift.dart' show Value;
import '../../data/database/traum_database.dart';

class OpenFoodFactsService {
  static const _baseUrl =
      'https://world.openfoodfacts.org/api/v0/product';

  static Future<FoodProductsCompanion?> fetchProduct(
      String barcode) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/$barcode.json'),
            headers: {'User-Agent': 'TRAUM-App/1.0'},
          )
          .timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) return null;
      final json =
          jsonDecode(response.body) as Map<String, dynamic>;
      if (json['status'] != 1) return null;

      final product = json['product'] as Map<String, dynamic>;
      final nutriments =
          product['nutriments'] as Map<String, dynamic>? ?? {};

      final name =
          (product['product_name'] as String?)?.trim() ??
          (product['product_name_de'] as String?)?.trim() ??
          'Unbekanntes Produkt';

      return FoodProductsCompanion.insert(
        barcode: Value(barcode),
        name: name.isEmpty ? 'Unbekanntes Produkt' : name,
        brand: Value(product['brands'] as String?),
        imageUrl: Value(product['image_thumb_url'] as String?),
        caloriesPer100g:
            _d(nutriments['energy-kcal_100g']) ?? 0,
        proteinPer100g:
            _d(nutriments['proteins_100g']) ?? 0,
        carbsPer100g:
            _d(nutriments['carbohydrates_100g']) ?? 0,
        fatPer100g: _d(nutriments['fat_100g']) ?? 0,
        sugarPer100g:
            Value(_d(nutriments['sugars_100g'])),
        fiberPer100g:
            Value(_d(nutriments['fiber_100g'])),
        saltPer100g:
            Value(_d(nutriments['salt_100g'])),
        saturatedFatPer100g:
            Value(_d(nutriments['saturated-fat_100g'])),
        isCustom: const Value(false),
        createdAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('OpenFoodFacts error: $e');
      return null;
    }
  }

  static double? _d(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    if (v is String) return double.tryParse(v);
    return null;
  }
}
