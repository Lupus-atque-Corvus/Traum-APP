import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';
import '../../core/navigation/routes.dart';
import '../../core/providers/preferences_provider.dart';
import '../../core/theme/colors.dart';

class BiometricLockScreen extends ConsumerStatefulWidget {
  const BiometricLockScreen({super.key});

  @override
  ConsumerState<BiometricLockScreen> createState() =>
      _BiometricLockScreenState();
}

class _BiometricLockScreenState extends ConsumerState<BiometricLockScreen> {
  final _auth = LocalAuthentication();
  bool _authenticating = false;
  String? _errorMessage;
  List<BiometricType> _biometricTypes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _loadBiometricTypes();
      _authenticate();
    });
  }

  Future<void> _loadBiometricTypes() async {
    try {
      final types = await _auth.getAvailableBiometrics();
      if (mounted) setState(() => _biometricTypes = types);
    } catch (_) {}
  }

  Future<void> _authenticate() async {
    if (_authenticating) return;
    setState(() {
      _authenticating = true;
      _errorMessage = null;
    });

    try {
      final authenticated = await _auth.authenticate(
        localizedReason: 'TRAUM entsperren',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (!mounted) return;
      if (authenticated) {
        context.go('/');
      } else {
        setState(() {
          _errorMessage = 'Authentifizierung fehlgeschlagen';
          _authenticating = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Biometrie nicht verfügbar';
          _authenticating = false;
        });
      }
    }
  }

  IconData get _icon {
    if (_biometricTypes.contains(BiometricType.face)) {
      return Icons.face_rounded;
    }
    return Icons.fingerprint_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final pinEnabled = ref.watch(pinLockProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    gradient: TraumColors.gradientCool,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.lock_rounded,
                      color: Colors.white, size: 40),
                ),
                const SizedBox(height: 24),
                const Text(
                  'TRAUM',
                  style: TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 28,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'App ist gesperrt',
                  style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 48),
                if (_authenticating)
                  const CircularProgressIndicator(
                      color: TraumColors.indigoBlue)
                else ...[
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: TraumColors.roseRed,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: TraumColors.indigoBlue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: Icon(_icon),
                    label: const Text(
                      'Entsperren',
                      style: TextStyle(
                          fontFamily: 'DMSans', fontWeight: FontWeight.w600),
                    ),
                  ),
                  // PIN fallback if PIN is also configured
                  if (pinEnabled) ...[
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () => context.go(Routes.pinEntry),
                      child: const Text(
                        'Stattdessen PIN verwenden',
                        style: TextStyle(
                          color: TraumColors.onBackgroundMuted,
                          fontFamily: 'DMSans',
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
