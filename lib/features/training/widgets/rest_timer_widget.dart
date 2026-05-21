import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

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
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _remaining = widget.durationSeconds;
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_remaining <= 1) {
        _timer.cancel();
        widget.onFinished();
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

  String get _formatted {
    final m = _remaining ~/ 60;
    final s = _remaining % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final ratio = _remaining / widget.durationSeconds;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 8),
        Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            color: TraumColors.onBackgroundSubtle,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 16),
        const Text('Pause', style: TextStyle(
          color: TraumColors.onBackgroundMuted,
          fontFamily: 'DMSans',
          fontSize: 13,
        )),
        const SizedBox(height: 8),
        Text(_formatted, style: const TextStyle(
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
        TextButton(
          onPressed: widget.onSkip,
          child: const Text('Skip', style: TextStyle(
            color: TraumColors.onBackgroundMuted,
            fontFamily: 'DMSans',
          )),
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}
