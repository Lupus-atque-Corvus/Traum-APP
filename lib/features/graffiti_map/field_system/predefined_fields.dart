import 'map_field.dart';

class PredefinedFields {
  PredefinedFields._();

  static const condition = MapField(
    key: 'condition',
    label: 'Zustand',
    type: MapFieldType.select,
    iconName: 'construction',
    options: [
      MapFieldOption(value: 'Verfallen', colorHex: 'F43F5E'),
      MapFieldOption(value: 'Teilweise erhalten', colorHex: 'F5A623'),
      MapFieldOption(value: 'Gut erhalten', colorHex: '3DD68C'),
    ],
  );

  static const access = MapField(
    key: 'access',
    label: 'Zugänglichkeit',
    type: MapFieldType.select,
    iconName: 'lock',
    options: [
      MapFieldOption(value: 'Frei zugänglich', colorHex: '3DD68C'),
      MapFieldOption(value: 'Zaun', colorHex: 'F5A623'),
      MapFieldOption(value: 'Verschlossen', colorHex: 'FF6B3D'),
      MapFieldOption(value: 'Gefährlich', colorHex: 'F43F5E'),
    ],
  );

  static const visited = MapField(
    key: 'visited',
    label: 'Status',
    type: MapFieldType.select,
    iconName: 'flag',
    options: [
      MapFieldOption(value: 'Geplant', colorHex: '5B6CF9'),
      MapFieldOption(value: 'Besucht', colorHex: '3DD68C'),
    ],
  );

  static const danger = MapField(
    key: 'danger',
    label: 'Gefahren-Hinweis',
    type: MapFieldType.text,
    iconName: 'warning',
  );

  static const hidden = MapField(
    key: 'hidden',
    label: 'Privat (nicht exportieren)',
    type: MapFieldType.toggle,
    iconName: 'visibility_off',
  );

  static const all = [condition, access, visited, danger, hidden];
}
