import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/colors.dart';
import '../../../core/theme/radius.dart';
import '../../../core/utils/formatters.dart';
import '../../../l10n/app_localizations.dart';

class RestTimerWidget extends StatefulWidget {
  final int durationSeconds;
  final VoidCallback onFinished;
  final VoidCallback onSkip;

  const RestTimerWidget({
    super.key,
    required this.durationSeconds,
    required this.onFinished,
    required this.onSkip,
  });

  @override
  State<RestTimerWidget> createState() => _RestTimerWidgetState();
}

class _RestTimerWidgetState extends State<RestTimerWidget> {
  late int _remaining;
  late int _total;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _total = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer.cancel();
        setState(() => _remaining = 0);
        HapticFeedback.heavyImpact();
        if (mounted) widget.onFinished();
      } else {
        setState(() => _remaining--);
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _adjust(int delta) {
    setState(() {
      _remaining = (_remaining + delta).clamp(5, 300);
      if (_remaining > _total) _total = _remaining;
    });
    HapticFeedback.selectionClick();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final ratio = _total > 0 ? (_remaining / _total).clamp(0.0, 1.0) : 0.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 32,
          height: 4,
          decoration: BoxDecoration(
            color: TraumColors.onBackgroundSubtle,
            borderRadius: BorderRadius.circular(TraumRadius.card),
          ),
        ),
        const SizedBox(height: 16),
        Text(l10n.restTimerLabel, style: const TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 13,
        )),
        const SizedBox(height: 8),
        Text(formatDurationHMS(_remaining), style: const TextStyle(
          color: TraumColors.mintGreen,
          fontFamily: 'DMSans',
          fontWeight: FontWeight.w700,
          fontSize: 48,
        )),
        const SizedBox(height: 12),
        SizedBox(
          width: 200,
          child: LinearProgressIndicator(
            value: ratio,
            backgroundColor: TraumColors.surfaceVariant,
            valueColor: const AlwaysStoppedAnimation<Color>(TraumColors.mintGreen),
            minHeight: 4,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _AdjustButton(label: '−15', onTap: () => _adjust(-15)),
            const SizedBox(width: 24),
            TextButton(
              onPressed: widget.onSkip,
              child: Text(l10n.restTimerSkip, style: const TextStyle(
                color: TraumColors.onBackgroundMuted,
                fontFamily: 'DMSans',
              )),
            ),
            const SizedBox(width: 24),
            _AdjustButton(label: '+15', onTap: () => _adjust(15)),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _AdjustButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AdjustButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: TraumColors.mintGreen,
            fontFamily: 'DMSans',
            fontWeight: FontWeight.w700,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
