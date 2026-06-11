import 'package:flutter/material.dart';
import '../../../core/theme/colors.dart';

/// Eine Nährstoff-Zeile: Label · "aktuell / Ziel Einheit" · Fortschrittsbalken.
/// `current == null` ⇒ nicht erfasst (zeigt "—", dezenter Balken).
class NutrientBarRow extends StatelessWidget {
  final String label;
  final double? current;
  final double goal;
  final String unit;

  const NutrientBarRow({
    super.key,
    required this.label,
    required this.current,
    required this.goal,
    required this.unit,
  });

  Color _barColor(double ratio) {
    if (ratio >= 1.0) return TraumColors.mintGreen;
    if (ratio >= 0.5) return TraumColors.cyanBlue;
    return TraumColors.amberGold;
  }

  String _fmt(double v) =>
      v >= 100 ? v.toStringAsFixed(0) : v.toStringAsFixed(v % 1 == 0 ? 0 : 1);

  @override
  Widget build(BuildContext context) {
    final tracked = current != null;
    final ratio = (tracked && goal > 0)
        ? (current! / goal).clamp(0.0, 1.0).toDouble()
        : 0.0;
    final currentText = tracked ? _fmt(current!) : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackground,
                      fontSize: 12)),
              Text('$currentText / ${_fmt(goal)} $unit',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted,
                      fontSize: 12)),
            ],
          ),
          const SizedBox(height: 3),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              backgroundColor: TraumColors.surfaceVariant,
              valueColor: AlwaysStoppedAnimation(
                  tracked ? _barColor(ratio) : TraumColors.surfaceVariant),
            ),
          ),
        ],
      ),
    );
  }
}
