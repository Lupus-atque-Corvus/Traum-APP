import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/navigation/routes.dart';
import '../../core/security/pin_service.dart';
import '../../core/theme/colors.dart';

class PinLockScreen extends StatefulWidget {
  const PinLockScreen({super.key});

  @override
  State<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends State<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _pin = '';
  String? _error;
  bool _verifying = false;
  late final AnimationController _shakeController;
  late final Animation<double> _shakeAnimation;

  static const _maxLength = 4;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeController, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _addDigit(String digit) {
    if (_pin.length >= _maxLength || _verifying) return;
    setState(() {
      _pin += digit;
      _error = null;
    });
    if (_pin.length == _maxLength) {
      _verify();
    }
  }

  void _removeDigit() {
    if (_pin.isEmpty || _verifying) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _verify() async {
    setState(() => _verifying = true);
    final ok = await PinService.verify(_pin);
    if (!mounted) return;
    if (ok) {
      context.go(Routes.home);
    } else {
      HapticFeedback.heavyImpact();
      await _shakeController.forward(from: 0);
      setState(() {
        _pin = '';
        _error = 'Falscher PIN. Bitte erneut versuchen.';
        _verifying = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: TraumColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
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
                  child:
                      const Icon(Icons.lock_rounded, color: Colors.white, size: 40),
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
                const SizedBox(height: 4),
                const Text(
                  'PIN eingeben',
                  style: TextStyle(
                    color: TraumColors.onBackgroundMuted,
                    fontFamily: 'DMSans',
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 40),
                AnimatedBuilder(
                  animation: _shakeAnimation,
                  builder: (_, child) {
                    final offset = (_shakeAnimation.value * 12) *
                        ((_shakeController.value < 0.5) ? 1 : -1);
                    return Transform.translate(
                      offset: Offset(offset, 0),
                      child: child,
                    );
                  },
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _maxLength,
                      (i) => AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i < _pin.length
                              ? TraumColors.indigoBlue
                              : TraumColors.surfaceVariant,
                          border: Border.all(
                            color: i < _pin.length
                                ? TraumColors.indigoBlue
                                : TraumColors.onBackgroundSubtle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: const TextStyle(
                      color: TraumColors.roseRed,
                      fontFamily: 'DMSans',
                      fontSize: 13,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 40),
                _Numpad(
                  onDigit: _addDigit,
                  onDelete: _removeDigit,
                  enabled: !_verifying,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Numpad extends StatelessWidget {
  final void Function(String) onDigit;
  final VoidCallback onDelete;
  final bool enabled;

  const _Numpad({
    required this.onDigit,
    required this.onDelete,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NumpadRow(digits: ['1', '2', '3'], onDigit: onDigit, enabled: enabled),
        const SizedBox(height: 12),
        _NumpadRow(digits: ['4', '5', '6'], onDigit: onDigit, enabled: enabled),
        const SizedBox(height: 12),
        _NumpadRow(digits: ['7', '8', '9'], onDigit: onDigit, enabled: enabled),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(width: 72),
            const SizedBox(width: 16),
            _NumpadKey(label: '0', onTap: enabled ? () => onDigit('0') : null),
            const SizedBox(width: 16),
            _NumpadDeleteKey(onTap: enabled ? onDelete : null),
          ],
        ),
      ],
    );
  }
}

class _NumpadRow extends StatelessWidget {
  final List<String> digits;
  final void Function(String) onDigit;
  final bool enabled;

  const _NumpadRow({
    required this.digits,
    required this.onDigit,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: digits.asMap().entries.map((e) {
        return Padding(
          padding: EdgeInsets.only(left: e.key > 0 ? 16 : 0),
          child: _NumpadKey(
            label: e.value,
            onTap: enabled ? () => onDigit(e.value) : null,
          ),
        );
      }).toList(),
    );
  }
}

class _NumpadKey extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;

  const _NumpadKey({required this.label, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: onTap != null ? TraumColors.surface : TraumColors.background,
          shape: BoxShape.circle,
          border: Border.all(
            color: TraumColors.surfaceVariant,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: onTap != null
                  ? TraumColors.onBackground
                  : TraumColors.onBackgroundSubtle,
              fontFamily: 'DMSans',
              fontSize: 24,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _NumpadDeleteKey extends StatelessWidget {
  final VoidCallback? onTap;

  const _NumpadDeleteKey({this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: TraumColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: TraumColors.surfaceVariant),
        ),
        child: const Center(
          child: Icon(
            Icons.backspace_outlined,
            color: TraumColors.onBackgroundMuted,
            size: 24,
          ),
        ),
      ),
    );
  }
}
