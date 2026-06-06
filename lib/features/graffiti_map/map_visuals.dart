import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';

/// Icon für eine Karten-Collection anhand ihres gespeicherten iconName.
IconData mapCollectionIcon(String name) => switch (name) {
      'spray' => Icons.format_paint_outlined,
      'tower' => Icons.cell_tower_outlined,
      'home_broken' => Icons.foundation_outlined,
      'building' => Icons.apartment_outlined,
      'nature' => Icons.park_outlined,
      'food' => Icons.restaurant_outlined,
      'map' => Icons.map_outlined,
      _ => Icons.location_on_outlined,
    };

/// Auswählbare Icons beim Erstellen einer eigenen Karte.
const List<String> kSelectableMapIcons = [
  'spray',
  'tower',
  'home_broken',
  'building',
  'nature',
  'food',
  'map',
];

/// Akzentfarbe einer Collection (Fallback cyanBlue).
Color mapCollectionColor(MapCollection c) => c.colorHex != null
    ? Color(int.parse('0xFF${c.colorHex}'))
    : TraumColors.cyanBlue;

/// Farbe aus einem optionalen Hex-String.
Color colorFromHex(String? hex, [Color fallback = TraumColors.cyanBlue]) =>
    hex != null ? Color(int.parse('0xFF$hex')) : fallback;

/// Icon für ein dynamisches Feld.
IconData mapFieldIcon(String? name) => switch (name) {
      'construction' => Icons.construction_outlined,
      'lock' => Icons.lock_outline,
      'flag' => Icons.flag_outlined,
      'warning' => Icons.warning_amber_rounded,
      'visibility_off' => Icons.visibility_off_outlined,
      _ => Icons.label_outline,
    };

/// Auswählbare Akzentfarben beim Erstellen einer Karte.
const List<String> kSelectableMapColors = [
  'FF6B3D',
  'F5A623',
  '3DD68C',
  '00D4D4',
  '5B6CF9',
  '9B8EC4',
  'F43F5E',
];
