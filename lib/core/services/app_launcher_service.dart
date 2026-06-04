import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

/// Schlankes Wertobjekt für eine installierte, startbare App.
class LauncherApp {
  final String name;
  final String packageName;
  final Uint8List? icon;

  const LauncherApp({
    required this.name,
    required this.packageName,
    required this.icon,
  });

  factory LauncherApp.fromAppInfo(AppInfo info) => LauncherApp(
        name: info.name,
        packageName: info.packageName,
        icon: info.icon,
      );
}

/// Kapselt das `installed_apps`-Plugin (Android) für das experimentelle
/// App-Launcher-Feature: Apps auflisten, einzeln nachschlagen und starten.
///
/// Icons werden im Speicher gecacht, damit Favoriten-Kacheln nicht bei jedem
/// Rebuild neu über den Plattform-Channel geladen werden müssen.
class AppLauncherService {
  final Map<String, LauncherApp> _cache = {};

  /// Alle startbaren (Nicht-System-)Apps mit Icon, alphabetisch sortiert.
  /// Bei Fehlern (z. B. fehlende Berechtigung) eine leere Liste.
  Future<List<LauncherApp>> listInstalledApps() async {
    final apps = await InstalledApps.getInstalledApps(
      excludeSystemApps: true,
      excludeNonLaunchableApps: true,
      withIcon: true,
    );
    final result = apps.map(LauncherApp.fromAppInfo).toList();
    for (final app in result) {
      _cache[app.packageName] = app;
    }
    return result;
  }

  /// Einzelne App nachschlagen (für Favoriten-Kacheln). Nutzt den Cache, fällt
  /// sonst auf einen Plugin-Lookup zurück. `null`, wenn nicht (mehr) installiert.
  Future<LauncherApp?> getApp(String packageName) async {
    final cached = _cache[packageName];
    if (cached != null) return cached;
    final info = await InstalledApps.getAppInfo(packageName);
    if (info == null) return null;
    final app = LauncherApp.fromAppInfo(info);
    _cache[packageName] = app;
    return app;
  }

  /// Startet die App. `false`, wenn sie nicht (mehr) vorhanden ist.
  Future<bool> launch(String packageName) async {
    final ok = await InstalledApps.startApp(packageName);
    return ok ?? false;
  }
}

final appLauncherServiceProvider =
    Provider<AppLauncherService>((ref) => AppLauncherService());
