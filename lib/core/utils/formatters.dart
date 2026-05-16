String formatCurrency(double amount, String symbol) {
  return '${amount.toStringAsFixed(2)} $symbol';
}

String formatWeight(double kg, String unitSystem) {
  if (unitSystem == 'imperial') {
    return '${(kg * 2.20462).toStringAsFixed(1)} lb';
  }
  return '${kg.toStringAsFixed(1)} kg';
}

String formatHeight(double cm, String unitSystem) {
  if (unitSystem == 'imperial') {
    final totalInches = cm / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches % 12).round();
    return "$feet' $inches\"";
  }
  return '${cm.toStringAsFixed(0)} cm';
}

String formatVolume(int ml, String unitSystem) {
  if (unitSystem == 'imperial') {
    return '${(ml / 29.5735).toStringAsFixed(0)} fl oz';
  }
  return '$ml ml';
}

String formatDurationHMS(int seconds) {
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  final s = seconds % 60;
  if (h > 0) {
    return '${h.toString().padLeft(2, '0')}:'
        '${m.toString().padLeft(2, '0')}:'
        '${s.toString().padLeft(2, '0')}';
  }
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}
