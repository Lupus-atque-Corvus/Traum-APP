import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/navigation/router.dart';
import 'core/navigation/routes.dart';
import 'core/providers/preferences_provider.dart';
import 'core/theme/traum_theme.dart';
import 'l10n/app_localizations.dart';

class TraumApp extends ConsumerStatefulWidget {
  const TraumApp({super.key});

  @override
  ConsumerState<TraumApp> createState() => _TraumAppState();
}

class _TraumAppState extends ConsumerState<TraumApp> {
  late final AppLifecycleListener _lifecycleListener;

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
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _checkStartupLock() {
    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.onboardingComplete) return;

    final biometric = ref.read(biometricLockProvider);
    final pin = ref.read(pinLockProvider);
    if (!biometric && !pin) return;

    _goToLock(biometric);
  }

  void _onPause() {
    final prefs = ref.read(preferencesRepositoryProvider);
    if (!prefs.onboardingComplete) return;

    final biometric = ref.read(biometricLockProvider);
    final pin = ref.read(pinLockProvider);
    if (biometric || pin) {
      _pausedForLock = true;
    }
  }

  void _onResume() {
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
