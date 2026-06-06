import 'package:flutter_riverpod/flutter_riverpod.dart';

enum MapViewMode { standard, satellite, hybrid }

final mapViewModeProvider =
    StateProvider<MapViewMode>((ref) => MapViewMode.standard);

const _osm = 'https://tile.openstreetmap.org/{z}/{x}/{y}.png';
const _esriImagery =
    'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
const _esriLabels =
    'https://server.arcgisonline.com/ArcGIS/rest/services/Reference/World_Boundaries_and_Places/MapServer/tile/{z}/{y}/{x}';

/// Tile URL templates for a mode, base layer first then overlays.
List<String> tileUrlTemplatesFor(MapViewMode mode) => switch (mode) {
      MapViewMode.standard => const [_osm],
      MapViewMode.satellite => const [_esriImagery],
      MapViewMode.hybrid => const [_esriImagery, _esriLabels],
    };

/// Only the standard OSM layer gets the dark invert filter.
bool mapModeUsesDarkFilter(MapViewMode mode) => mode == MapViewMode.standard;

/// Attribution string shown on the map for the given mode.
String mapModeAttribution(MapViewMode mode) => switch (mode) {
      MapViewMode.standard => 'OpenStreetMap contributors',
      MapViewMode.satellite ||
      MapViewMode.hybrid =>
        'Esri, Maxar, Earthstar Geographics',
    };

/// Short human label for the mode switcher.
String mapModeLabel(MapViewMode mode) => switch (mode) {
      MapViewMode.standard => 'Standard',
      MapViewMode.satellite => 'Satellit',
      MapViewMode.hybrid => 'Hybrid',
    };
