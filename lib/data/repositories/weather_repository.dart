import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/colors.dart';

class WeatherRepository {
  static const _timeoutSeconds = 5;
  static const _maxRetries = 2;

  Future<void> refreshOnStart(
    SharedPreferences prefs,
    BuildContext context,
  ) async {
    double? lat = prefs.getDouble('weather_lat');
    double? lon = prefs.getDouble('weather_lon');

    if (lat == null || lon == null) {
      await _requestLocationAndSave(prefs, context);
      lat = prefs.getDouble('weather_lat');
      lon = prefs.getDouble('weather_lon');
    }

    if (lat == null || lon == null) return;
    await _fetchAndCache(lat, lon, prefs);
  }

  Future<void> _requestLocationAndSave(
    SharedPreferences prefs,
    BuildContext context,
  ) async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        await showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: TraumColors.surface,
            title: const Text(
              'Standortzugriff benötigt',
              style: TextStyle(color: TraumColors.onBackground, fontFamily: 'DMSans'),
            ),
            content: const Text(
              'TRAUM benötigt deinen Standort, um das aktuelle Wetter '
              'auf der Startseite anzuzeigen.\n\n'
              'Bitte erlaube den Standortzugriff in den Systemeinstellungen.',
              style: TextStyle(color: TraumColors.onBackgroundMuted, fontFamily: 'DMSans'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text(
                  'Ohne Wetter fortfahren',
                  style: TextStyle(color: TraumColors.onBackgroundMuted),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  Geolocator.openAppSettings();
                },
                child: const Text(
                  'Einstellungen öffnen',
                  style: TextStyle(color: TraumColors.coralOrange),
                ),
              ),
            ],
          ),
        );
      }
      return;
    }

    if (permission == LocationPermission.denied) return;

    try {
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      await prefs.setDouble('weather_lat', position.latitude);
      await prefs.setDouble('weather_lon', position.longitude);
    } catch (_) {
      // Timeout oder Fehler → ohne Standort weitermachen
    }
  }

  Future<void> _fetchAndCache(
    double lat,
    double lon,
    SharedPreferences prefs,
  ) async {
    final url = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=$lat&longitude=$lon'
      '&current=temperature_2m,weathercode'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=auto',
    );

    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final response = await http
            .get(url)
            .timeout(const Duration(seconds: _timeoutSeconds));
        if (response.statusCode == 200) {
          await prefs.setString('weather_cache', response.body);
          await prefs.setInt(
              'weather_cache_ts', DateTime.now().millisecondsSinceEpoch);
          return;
        }
        break;
      } on TimeoutException {
        if (attempt == _maxRetries) break;
        await Future.delayed(Duration(seconds: attempt + 1));
      } on SocketException {
        break;
      } catch (_) {
        break;
      }
    }
  }
}
