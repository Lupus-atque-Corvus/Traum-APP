import 'package:intl/intl.dart';

import '../../l10n/app_localizations.dart';

String formatDate(DateTime date, {String format = 'dd.MM.yyyy'}) {
  return DateFormat(format, 'de').format(date);
}

String formatDateTime(DateTime date) {
  return DateFormat('dd.MM.yyyy HH:mm', 'de').format(date);
}

String formatTime(DateTime date) {
  return DateFormat('HH:mm', 'de').format(date);
}

String greeting(String name, [AppLocalizations? l10n]) {
  final hour = DateTime.now().hour;
  String salutation;
  if (hour >= 5 && hour < 12) {
    salutation = l10n?.greetingMorning ?? 'Guten Morgen';
  } else if (hour >= 12 && hour < 18) {
    salutation = l10n?.greetingDay ?? 'Guten Tag';
  } else if (hour >= 18 && hour < 22) {
    salutation = l10n?.greetingEvening ?? 'Guten Abend';
  } else {
    salutation = l10n?.greetingNight ?? 'Gute Nacht';
  }
  if (name.isEmpty) return salutation;
  return '$salutation, $name';
}

bool isSameDay(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

DateTime startOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day);

DateTime endOfDay(DateTime date) =>
    DateTime(date.year, date.month, date.day, 23, 59, 59);

String formatDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  final s = d.inSeconds.remainder(60);
  if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}min';
  if (m > 0) return '${m}min ${s.toString().padLeft(2, '0')}s';
  return '${s}s';
}

int calculateAge(DateTime birthDate) {
  final now = DateTime.now();
  int age = now.year - birthDate.year;
  if (now.month < birthDate.month ||
      (now.month == birthDate.month && now.day < birthDate.day)) {
    age--;
  }
  return age;
}
