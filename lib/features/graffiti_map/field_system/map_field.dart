enum MapFieldType { select, text, toggle, number }

class MapFieldOption {
  final String value;
  final String? colorHex;
  const MapFieldOption({required this.value, this.colorHex});

  Map<String, dynamic> toJson() => {'value': value, 'colorHex': colorHex};

  factory MapFieldOption.fromJson(Map<String, dynamic> j) =>
      MapFieldOption(value: j['value'] as String, colorHex: j['colorHex'] as String?);
}

class MapField {
  final String key;
  final String label;
  final MapFieldType type;
  final List<MapFieldOption> options;
  final String? iconName;
  const MapField({
    required this.key,
    required this.label,
    required this.type,
    this.options = const [],
    this.iconName,
  });

  Map<String, dynamic> toJson() => {
        'key': key,
        'label': label,
        'type': type.name,
        'options': options.map((o) => o.toJson()).toList(),
        'iconName': iconName,
      };

  factory MapField.fromJson(Map<String, dynamic> j) => MapField(
        key: j['key'] as String,
        label: j['label'] as String,
        type: MapFieldType.values.byName(j['type'] as String),
        options: (j['options'] as List? ?? [])
            .map((o) => MapFieldOption.fromJson(o as Map<String, dynamic>))
            .toList(),
        iconName: j['iconName'] as String?,
      );
}
