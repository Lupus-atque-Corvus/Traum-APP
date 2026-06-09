import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme/colors.dart';

/// Hüllt eine Home-Kachel im Edit-Modus ein: Wackel-Animation,
/// Entfernen-/Resize-Buttons und Drag-&-Drop zum Umsortieren.
///
/// Hält bewusst keinen Provider-Zugriff – alles läuft über Callbacks.
class HomeEditTile extends StatefulWidget {
  const HomeEditTile({
    super.key,
    required this.index,
    required this.child,
    required this.onRemove,
    required this.onResize,
    required this.onReorder,
  });

  final int index;
  final Widget child;
  final VoidCallback onRemove;
  final VoidCallback onResize;
  final void Function(int from, int to) onReorder;

  @override
  State<HomeEditTile> createState() => _HomeEditTileState();
}

class _HomeEditTileState extends State<HomeEditTile> {
  static const double _wiggle = 0.012;

  Timer? _timer;
  double _angle = _wiggle;

  @override
  void initState() {
    super.initState();
    // Leicht versetzte Phase pro Kachel, damit nicht alle synchron wackeln.
    final phase = (widget.index.isEven) ? _wiggle : -_wiggle;
    _angle = phase;
    _timer = Timer.periodic(const Duration(milliseconds: 180), (_) {
      if (!mounted) return;
      setState(() => _angle = -_angle);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Widget _wiggleChild(Widget child) {
    return AnimatedRotation(
      turns: _angle / (2 * math.pi),
      duration: const Duration(milliseconds: 180),
      child: child,
    );
  }

  Widget _overlayed(Widget child) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        // Entfernen (oben links)
        Positioned(
          top: -6,
          left: -6,
          child: _CircleButton(
            color: TraumColors.roseRed,
            icon: Icons.close_rounded,
            onTap: widget.onRemove,
          ),
        ),
        // Resize (unten rechts)
        Positioned(
          bottom: -6,
          right: -6,
          child: _CircleButton(
            color: TraumColors.cyanBlue,
            icon: Icons.aspect_ratio,
            onTap: widget.onResize,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final wiggling = _wiggleChild(widget.child);

    return LongPressDraggable<int>(
      data: widget.index,
      feedback: Material(
        color: Colors.transparent,
        child: Transform.scale(
          scale: 1.05,
          child: Opacity(
            opacity: 0.9,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: widget.child,
            ),
          ),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: widget.child),
      child: DragTarget<int>(
        onWillAcceptWithDetails: (d) => d.data != widget.index,
        onAcceptWithDetails: (d) => widget.onReorder(d.data, widget.index),
        builder: (context, candidate, rejected) {
          final highlighted = candidate.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: highlighted
                    ? TraumColors.cyanBlue
                    : Colors.transparent,
                width: 2,
              ),
            ),
            child: _overlayed(wiggling),
          );
        },
      ),
    );
  }
}

class _CircleButton extends StatelessWidget {
  const _CircleButton({
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 16, color: Colors.white),
      ),
    );
  }
}
