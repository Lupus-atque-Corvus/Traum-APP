import 'dart:convert';
import 'map_field.dart';
import 'predefined_fields.dart';

class MapTemplate {
  final String name, iconName, colorHex;
  final bool hasRating, multiPhoto;
  final int groupRadius;
  final List<MapField> fields;
  const MapTemplate({
    required this.name,
    required this.iconName,
    required this.colorHex,
    required this.hasRating,
    required this.multiPhoto,
    this.groupRadius = 50,
    required this.fields,
  });

  String buildFieldConfig() => jsonEncode({
        'rating': hasRating,
        'multiPhoto': multiPhoto,
        'groupRadius': groupRadius,
        'fields': fields.map((f) => f.toJson()).toList(),
      });
}

class MapTemplates {
  MapTemplates._();

  static const graffiti = MapTemplate(
    name: 'Graffiti',
    iconName: 'spray',
    colorHex: 'FF6B3D',
    hasRating: false,
    multiPhoto: false,
    fields: [],
  );

  static const tuerme = MapTemplate(
    name: 'Türme',
    iconName: 'tower',
    colorHex: '00D4D4',
    hasRating: true,
    multiPhoto: true,
    fields: [],
  );

  static const lostPlaces = MapTemplate(
    name: 'Lost Places',
    iconName: 'home_broken',
    colorHex: '9B8EC4',
    hasRating: true,
    multiPhoto: true,
    fields: [
      PredefinedFields.condition,
      PredefinedFields.access,
      PredefinedFields.visited,
      PredefinedFields.danger,
      PredefinedFields.hidden,
    ],
  );

  static const leer = MapTemplate(
    name: 'Eigene Karte',
    iconName: 'map',
    colorHex: '3DD68C',
    hasRating: false,
    multiPhoto: false,
    fields: [],
  );

  static const all = [graffiti, tuerme, lostPlaces, leer];
}
