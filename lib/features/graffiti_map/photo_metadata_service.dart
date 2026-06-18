import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:exif/exif.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class PhotoCaptureResult {
  final String photoPath;
  final double? latitude, longitude;
  final String? locationName;
  final DateTime takenAt;
  PhotoCaptureResult({
    required this.photoPath,
    this.latitude,
    this.longitude,
    this.locationName,
    required this.takenAt,
  });
}

class PhotoMetadataService {
  static Future<PhotoCaptureResult?> captureWithMetadata(
      ImageSource source) async {
    final picked = await ImagePicker()
        .pickImage(source: source, maxWidth: 2400, imageQuality: 88);
    if (picked == null) return null;

    final savedPath = await _saveToAppStorage(picked.path);
    double? lat, lon;
    DateTime takenAt = DateTime.now();

    // EXIF lesen
    try {
      final bytes = await File(picked.path).readAsBytes();
      final tags = await readExifFromBytes(bytes);
      if (tags.containsKey('GPS GPSLatitude') &&
          tags.containsKey('GPS GPSLongitude')) {
        lat = _parseGps(tags['GPS GPSLatitude']!,
            tags['GPS GPSLatitudeRef']?.printable ?? 'N');
        lon = _parseGps(tags['GPS GPSLongitude']!,
            tags['GPS GPSLongitudeRef']?.printable ?? 'E');
      }
      if (tags.containsKey('EXIF DateTimeOriginal')) {
        takenAt = _parseExifDate(tags['EXIF DateTimeOriginal']!.printable) ??
            DateTime.now();
      }
    } catch (e) {
      debugPrint('EXIF: $e');
    }

    // Fallback aktuelle GPS-Position
    if (lat == null || lon == null) {
      try {
        var perm = await Geolocator.checkPermission();
        if (perm == LocationPermission.denied) {
          perm = await Geolocator.requestPermission();
        }
        if (perm != LocationPermission.deniedForever &&
            perm != LocationPermission.denied) {
          final pos = await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              timeLimit: Duration(seconds: 6),
            ),
          );
          lat = pos.latitude;
          lon = pos.longitude;
        }
      } catch (e) {
        debugPrint('GPS: $e');
      }
    }

    // Reverse-Geocoding
    String? locationName;
    if (lat != null && lon != null) {
      try {
        final p = await placemarkFromCoordinates(lat, lon);
        if (p.isNotEmpty) {
          locationName = [p.first.locality, p.first.country]
              .where((s) => s != null && s.isNotEmpty)
              .join(', ');
        }
      } catch (e) {
        debugPrint('Geocoding: $e');
      }
    }

    return PhotoCaptureResult(
      photoPath: savedPath,
      latitude: lat,
      longitude: lon,
      locationName: locationName,
      takenAt: takenAt,
    );
  }

  static Future<String> _saveToAppStorage(String src) async {
    final dir = await getApplicationSupportDirectory();
    final d = Directory('${dir.path}/graffitimap');
    await d.create(recursive: true);
    final dest =
        '${d.path}/photo_${DateTime.now().millisecondsSinceEpoch}.jpg';
    await File(src).copy(dest);
    return dest;
  }

  static double? _parseGps(IfdTag tag, String ref) {
    try {
      final v = tag.values.toList();
      if (v.length < 3) return null;
      double conv(dynamic r) =>
          (r as Ratio).numerator / r.denominator;
      double dec = conv(v[0]) + conv(v[1]) / 60 + conv(v[2]) / 3600;
      if (ref == 'S' || ref == 'W') dec = -dec;
      return dec;
    } catch (_) {
      return null;
    }
  }

  static DateTime? _parseExifDate(String s) {
    try {
      final p = s.split(' ');
      final d = p[0].split(':');
      final t = p[1].split(':');
      return DateTime(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
          int.parse(t[0]), int.parse(t[1]), int.parse(t[2]));
    } catch (_) {
      return null;
    }
  }
}
