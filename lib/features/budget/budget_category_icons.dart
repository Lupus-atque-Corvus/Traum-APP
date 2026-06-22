import 'package:flutter/material.dart';

const Map<String, IconData> kBudgetCategoryIcons = {
  // Wohnen & Haushalt
  'home': Icons.home_outlined,
  'electrical': Icons.electrical_services_outlined,
  'water': Icons.water_drop_outlined,
  'tools': Icons.build_outlined,
  'cleaning': Icons.cleaning_services_outlined,
  // Essen & Trinken
  'restaurant': Icons.restaurant_outlined,
  'local_grocery_store': Icons.local_grocery_store_outlined,
  'coffee': Icons.coffee_outlined,
  'fastfood': Icons.fastfood_outlined,
  'cake': Icons.cake_outlined,
  // Transport
  'directions_car': Icons.directions_car_outlined,
  'train': Icons.train_outlined,
  'directions_bike': Icons.directions_bike_outlined,
  'flight': Icons.flight_outlined,
  'local_gas_station': Icons.local_gas_station_outlined,
  // Gesundheit
  'medical_services': Icons.medical_services_outlined,
  'pharmacy': Icons.local_pharmacy_outlined,
  'fitness': Icons.fitness_center_outlined,
  'spa': Icons.spa_outlined,
  'psychology': Icons.psychology_outlined,
  // Shopping & Freizeit
  'shopping_bag': Icons.shopping_bag_outlined,
  'sports_esports': Icons.sports_esports_outlined,
  'movie': Icons.movie_outlined,
  'music_note': Icons.music_note_outlined,
  'sports_soccer': Icons.sports_soccer_outlined,
  // Finanzen
  'savings': Icons.savings_outlined,
  'credit_card': Icons.credit_card_outlined,
  'account_balance': Icons.account_balance_outlined,
  'trending_up': Icons.trending_up,
  'receipt': Icons.receipt_outlined,
  // Bildung & Beruf
  'school': Icons.school_outlined,
  'work': Icons.work_outlined,
  'laptop': Icons.laptop_outlined,
  'book': Icons.book_outlined,
  'science': Icons.science_outlined,
  // Sonstiges
  'category': Icons.category_outlined,
  'star': Icons.star_outline,
  'favorite': Icons.favorite_outline,
  'pets': Icons.pets_outlined,
  'child_care': Icons.child_care_outlined,
};

IconData iconFromName(String? name) {
  if (name == null) return Icons.category_outlined;
  return kBudgetCategoryIcons[name] ?? Icons.category_outlined;
}

/// Renders a category glyph from a stored value that may be either a Material
/// icon name (from the icon picker) or a literal emoji character.
///
/// Known icon names render as the mapped [Icon]; anything else (emoji) renders
/// as [Text]. Falls back to a generic category icon when [value] is empty.
Widget budgetCategoryGlyph(String? value,
    {required Color color, double size = 20}) {
  if (value == null || value.isEmpty) {
    return Icon(Icons.category_outlined, color: color, size: size);
  }
  final iconData = kBudgetCategoryIcons[value];
  if (iconData != null) {
    return Icon(iconData, color: color, size: size);
  }
  return Text(value, style: TextStyle(fontSize: size * 0.9));
}

/// Returns an emoji prefix (with trailing space) for inline text labels, or an
/// empty string when [value] is an icon name (which has no textual glyph).
String budgetCategoryEmojiPrefix(String? value) {
  if (value == null || value.isEmpty) return '';
  if (kBudgetCategoryIcons.containsKey(value)) return '';
  return '$value ';
}
