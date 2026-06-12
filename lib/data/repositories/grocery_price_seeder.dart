import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../database/traum_database.dart';
import '../../core/services/grocery_price_service.dart';

class GroceryPriceSeeder {
  static const _flag = 'grocery_prices_seeded_v1';

  static Future<void> seedIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool(_flag) == true) return;

    try {
      final raw =
          await rootBundle.loadString('assets/data/grocery_prices.json');
      final List<dynamic> items = jsonDecode(raw) as List<dynamic>;
      await db.batch((b) {
        for (final dynamic item in items) {
          final map = item as Map<String, dynamic>;
          final name = map['name'] as String;
          b.insert(
            db.groceryPrices,
            GroceryPricesCompanion.insert(
              name: name,
              nameNormalized: GroceryPriceService.normalizeName(name),
              category: Value(map['category'] as String?),
              avgPrice: (map['avgPrice'] as num).toDouble(),
              unit: Value(map['unit'] as String?),
            ),
          );
        }
      });
    } catch (_) {
      // Asset missing/corrupt — leave DB empty, app still works without
      // suggestions. Do not set the flag so a later run can retry.
      return;
    }

    await prefs.setBool(_flag, true);
  }
}
