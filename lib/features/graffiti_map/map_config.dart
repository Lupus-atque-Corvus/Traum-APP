import 'dart:convert';
import 'package:geolocator/geolocator.dart';

/// Per-map photo grouping radius in meters (default 50).
double groupRadiusFromConfig(String fieldConfig) {
  try {
    final m = jsonDecode(fieldConfig) as Map<String, dynamic>;
    final v = m['groupRadius'];
    if (v is num) return v.toDouble();
  } catch (_) {}
  return 50;
}

/// Whether photos should be auto-grouped by radius for this map (default false).
bool autoGroupFromConfig(String fieldConfig) {
  try {
    final m = jsonDecode(fieldConfig) as Map<String, dynamic>;
    return m['autoGroup'] == true;
  } catch (_) {}
  return false;
}

/// Returns the id of the nearest marker within [radiusMeters] of (lat,lon),
/// or null if none. [markers] is a list of (id, lat, lon).
int? nearestMarkerWithin(
  List<(int, double, double)> markers,
  double lat,
  double lon,
  double radiusMeters,
) {
  int? bestId;
  double bestDist = double.infinity;
  for (final (id, mlat, mlon) in markers) {
    final d = Geolocator.distanceBetween(lat, lon, mlat, mlon);
    if (d <= radiusMeters && d < bestDist) {
      bestDist = d;
      bestId = id;
    }
  }
  return bestId;
}
