import 'dart:convert';
import 'package:http/http.dart' as http;

class FoodProduct {
  final String barcode;
  final String name;
  final String? brand;
  final double kcalPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final double? servingSizeG;

  const FoodProduct({
    required this.barcode,
    required this.name,
    this.brand,
    required this.kcalPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.servingSizeG,
  });
}

class OpenFoodFactsService {
  static const _baseUrl = 'https://world.openfoodfacts.org/api/v2/product';

  Future<FoodProduct?> lookup(String barcode) async {
    try {
      final uri = Uri.parse(
        '$_baseUrl/$barcode.json?fields=product_name,brands,nutriments,serving_size',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return null;

      final body = json.decode(response.body) as Map<String, dynamic>;
      if (body['status'] != 1) return null;

      final product = body['product'] as Map<String, dynamic>? ?? {};
      final nutriments = product['nutriments'] as Map<String, dynamic>? ?? {};

      final name = (product['product_name'] as String?)?.trim() ?? '';
      if (name.isEmpty) return null;

      double n(String key) =>
          (nutriments[key] as num?)?.toDouble() ?? 0.0;

      return FoodProduct(
        barcode: barcode,
        name: name,
        brand: (product['brands'] as String?)?.split(',').first.trim(),
        kcalPer100g: n('energy-kcal_100g'),
        proteinPer100g: n('proteins_100g'),
        carbsPer100g: n('carbohydrates_100g'),
        fatPer100g: n('fat_100g'),
        servingSizeG: _parseServingSize(product['serving_size'] as String?),
      );
    } catch (_) {
      return null;
    }
  }

  double? _parseServingSize(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    return match != null ? double.tryParse(match.group(1)!) : null;
  }
}
