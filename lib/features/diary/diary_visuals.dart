import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';

/// Icon für ein Tagebuch anhand seines gespeicherten iconName.
IconData diaryIcon(String name) => switch (name) {
  'book' => Icons.menu_book_outlined,
  'heart' => Icons.favorite_outline,
  'leaf' => Icons.eco_outlined,
  'sun' => Icons.wb_sunny_outlined,
  'moon' => Icons.nightlight_outlined,
  'star' => Icons.star_outline,
  'pen' => Icons.edit_outlined,
  'plane' => Icons.flight_outlined,
  'music' => Icons.music_note_outlined,
  'camera' => Icons.photo_camera_outlined,
  _ => Icons.menu_book_outlined,
};

/// Auswählbare Icons beim Anlegen eines eigenen Tagebuchs.
const List<String> kSelectableDiaryIcons = [
  'book',
  'heart',
  'leaf',
  'sun',
  'moon',
  'star',
  'pen',
  'plane',
  'music',
  'camera',
];

/// Akzentfarbe eines Tagebuchs (Fallback lavender).
Color diaryColor(Diary d) => d.colorHex != null
    ? Color(int.parse('0xFF${d.colorHex}'))
    : TraumColors.lavender;

/// Auswählbare Akzentfarben beim Anlegen eines Tagebuchs.
const List<String> kSelectableDiaryColors = [
  '9B8EC4',
  'FF6B3D',
  'F5A623',
  '3DD68C',
  '00D4D4',
  '5B6CF9',
  'F43F5E',
];
