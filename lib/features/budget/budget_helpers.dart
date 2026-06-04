String fmtAmount(double amount) {
  // German number format: 1.234,56
  final str = amount.abs().toStringAsFixed(2).replaceAll('.', ',');
  final parts = str.split(',');
  final intPart = parts[0].replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]}.',
  );
  return '$intPart,${parts[1]}';
}

String fmtTransactionDate(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final txDay = DateTime(date.year, date.month, date.day);
  if (txDay == today) return 'Heute';
  if (txDay == today.subtract(const Duration(days: 1))) return 'Gestern';
  return '${date.day}. ${_monthName(date.month)}';
}

String _monthName(int month) {
  const names = [
    'Jan', 'Feb', 'Mär', 'Apr', 'Mai', 'Jun',
    'Jul', 'Aug', 'Sep', 'Okt', 'Nov', 'Dez',
  ];
  return names[month - 1];
}
