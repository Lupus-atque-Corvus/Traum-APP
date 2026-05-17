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

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onPause: _onPause,
      onResume: _onResume,
    );
    // Always lock on cold start if lock is configured
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkStartupLock());
  }

  void _checkStartupLock() {
    final biometricEnabled = ref.read(biometricLockProvider);
    final pinEnabled = ref.read(pinLockProvider);
    final onboarded = ref.read(preferencesRepositoryProvider).onboardingComplete;
    if (!onboarded || (!biometricEnabled && !pinEnabled)) return;

    final router = ref.read(routerProvider);
    if (biometricEnabled) {
      router.go(Routes.biometricLock);
    } else {
      router.go(Routes.pinEntry);
    }
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  void _onPause() {
    final prefs = ref.read(sharedPreferencesProvider);
    prefs.setInt('lock_timestamp', DateTime.now().millisecondsSinceEpoch);
  }

  void _onResume() {
    final biometricEnabled = ref.read(biometricLockProvider);
    final pinEnabled = ref.read(pinLockProvider);
    if (!biometricEnabled && !pinEnabled) return;

    final prefs = ref.read(sharedPreferencesProvider);
    final ts = prefs.getInt('lock_timestamp') ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - ts;
    if (elapsed > 5 * 60 * 1000) {
      if (biometricEnabled) {
        ref.read(routerProvider).go(Routes.biometricLock);
      } else {
        ref.read(routerProvider).go(Routes.pinEntry);
      }
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
