import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:home_widget/home_widget.dart';

import 'core/navigation/router.dart';
import 'core/navigation/routes.dart';
import 'core/providers/preferences_provider.dart';
import 'core/theme/traum_theme.dart';
import 'l10n/app_localizations.dart';
import 'widget/widget_catalog.dart';
import 'widget/widget_update_scheduler.dart';

/// Returns true when [route] matches one of the known widget deep-link routes.
bool isKnownWidgetRoute(String? route) =>
    route != null && widgetCatalog.any((e) => e.route == route);

const MethodChannel _widgetChannel = MethodChannel('de.traum/widget');

/// Fetches the initial route triggered by a widget tap (or null).
/// Validates against [widgetCatalog] to reject arbitrary routes.
Future<String?> initialWidgetRoute() async {
  try {
    final r = await _widgetChannel.invokeMethod<String>('getInitialRoute');
    return isKnownWidgetRoute(r) ? r : null;
  } catch (_) {
    return null;
  }
}

/// Maps an incoming iOS widget URL (e.g. `traum:///budget` or `traum://budget`)
/// to a known app route, or null when unknown.
String? routeFromWidgetUri(Uri? uri) {
  if (uri == null) return null;
  final path = uri.path.isEmpty ? '/${uri.host}' : uri.path;
  return isKnownWidgetRoute(path) ? path : null;
}

class TraumApp extends ConsumerStatefulWidget {
  const TraumApp({super.key});

  @override
  ConsumerState<TraumApp> createState() => _TraumAppState();
}

class _TraumAppState extends ConsumerState<TraumApp> {
  late final AppLifecycleListener _lifecycleListener;
  StreamSubscription<Uri?>? _widgetClickSub;

  // Set to true when app is truly backgrounded (paused state).
  // Cleared after lock screen is shown on resume.
  bool _pausedForLock = false;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: _onPause,
      onResume: _onResume,
    );
    // Always lock on cold start if lock is configured.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStartupLock());
    // Navigate to the route that triggered the widget tap (cold start).
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWidgetDeepLink());
    // iOS: handle widgetURL launches + taps via home_widget.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkWidgetUriLaunch());
    _widgetClickSub = HomeWidget.widgetClicked.listen(_onWidgetUri);
  }

  @override
  void dispose() {
    _widgetClickSub?.cancel();
    _lifecycleListener.dispose();
    super.dispose();
  }

  Future<void> _checkWidgetDeepLink() async {
    final route = await initialWidgetRoute();
    if (route != null && mounted) {
      ref.read(routerProvider).go(route);
    }
  }

  /// iOS cold start: the launch URI from a tapped widget (`traum:///route`).
  Future<void> _checkWidgetUriLaunch() async {
    try {
      final uri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      _onWidgetUri(uri);
    } catch (_) {
      // No launch URI / unsupported platform — ignore.
    }
  }

  void _onWidgetUri(Uri? uri) {
    final route = routeFromWidgetUri(uri);
    if (route != null && mounted) {
      ref.read(routerProvider).go(route);
    }
  }

  void _checkStartupLock() {
    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.onboardingComplete) return;

    final biometric = ref.read(biometricLockProvider);
    final pin = ref.read(pinLockProvider);
    if (!biometric && !pin) return;

    _goToLock(biometric);
  }

  DateTime? _lastWidgetRefresh;

  /// Refreshes homescreen widget data, but skips it if the last refresh was
  /// very recent. `_onPause`/`_onResume` fire on EVERY lifecycle transition —
  /// a single permission dialog (e.g. the calendar/health permission flow)
  /// triggers several pause/resume cycles in quick succession, each of which
  /// would otherwise re-run the full widget snapshot collection (HealthConnect
  /// IPC calls + DB queries) back-to-back, visibly janking the UI mid-flow.
  void _refreshWidgetsDebounced() {
    final now = DateTime.now();
    if (_lastWidgetRefresh != null &&
        now.difference(_lastWidgetRefresh!) < const Duration(seconds: 3)) {
      return;
    }
    _lastWidgetRefresh = now;
    refreshWidgetsFromRead(ref.read); // fire-and-forget
  }

  void _onPause() {
    _refreshWidgetsDebounced();

    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.onboardingComplete) return;

    final biometric = ref.read(biometricLockProvider);
    final pin = ref.read(pinLockProvider);
    if (biometric || pin) {
      _pausedForLock = true;
    }
  }

  void _onResume() {
    _refreshWidgetsDebounced();

    // Navigate if resumed from a widget tap (singleTop re-delivery).
    _checkWidgetDeepLink();

    if (!_pausedForLock) return;
    _pausedForLock = false;

    final biometric = ref.read(biometricLockProvider);
    final pin = ref.read(pinLockProvider);
    if (!biometric && !pin) return;

    _goToLock(biometric);
  }

  void _goToLock(bool biometric) {
    final router = ref.read(routerProvider);
    if (biometric) {
      router.go(Routes.biometricLock);
    } else {
      router.go(Routes.pinEntry);
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'TRAUM',
      debugShowCheckedModeBanner: false,
      theme: TraumTheme.light,
      darkTheme: TraumTheme.dark,
      themeMode: ThemeMode.dark,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
    );
  }
}
