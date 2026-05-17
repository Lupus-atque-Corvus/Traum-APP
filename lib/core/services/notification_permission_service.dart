import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../theme/colors.dart';

class NotificationPermissionService {
  static Future<bool> requestPermission(BuildContext context) async {
    final status = await Permission.notification.status;
    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      if (context.mounted) _showSettingsDialog(context);
      return false;
    }

    final result = await Permission.notification.request();

    if (result.isPermanentlyDenied && context.mounted) {
      _showSettingsDialog(context);
      return false;
    }

    return result.isGranted;
  }

  static void _showSettingsDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surface,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Benachrichtigungen blockiert',
          style: TextStyle(
            color: TraumColors.onBackground,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
          ),
        ),
        content: const Text(
          'TRAUM benötigt Benachrichtigungen für Medikamenten-Erinnerungen '
          'und Aufgaben. Bitte erlaube sie in den Systemeinstellungen.',
          style: TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'Später',
              style: TextStyle(color: TraumColors.onBackgroundMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              openAppSettings();
            },
            child: const Text(
              'Einstellungen öffnen',
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
