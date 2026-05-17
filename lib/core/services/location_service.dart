import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/colors.dart';

class LocationService {
  static Future<bool> requestAndSave(BuildContext context) async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (context.mounted) {
        _showSettingsDialog(
          context,
          'Standort-Dienst deaktiviert',
          'Bitte aktiviere den Standort-Dienst in den Systemeinstellungen.',
        );
      }
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.deniedForever) {
      if (context.mounted) {
        _showSettingsDialog(
          context,
          'Standortzugriff blockiert',
          'TRAUM benötigt deinen Standort für die Wetteranzeige. '
              'Bitte erlaube den Zugriff in den Systemeinstellungen.',
        );
      }
      return false;
    }

    if (permission == LocationPermission.denied) return false;

    try {
      final position = await Geolocator.getCurrentPosition()
          .timeout(const Duration(seconds: 8));
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('weather_lat', position.latitude);
      await prefs.setDouble('weather_lon', position.longitude);
      return true;
    } catch (e) {
      debugPrint('LocationService error: $e');
      return false;
    }
  }

  static void _showSettingsDialog(
      BuildContext context, String title, String message) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          title,
          style: const TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: Text(
          message,
          style: const TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Schließen',
              style: TextStyle(color: TraumColors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              Geolocator.openAppSettings();
            },
            child: const Text(
              'Einstellungen',
              style: TextStyle(
                color: TraumColors.coralOrange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
