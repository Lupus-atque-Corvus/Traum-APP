/// Ersetzt Platzhalter in Vorlagen-Inhalten.
///
/// Unterstützt:
/// - `{{title}}`        – Titel der Zielnotiz
/// - `{{date}}`         – aktuelles Datum (ISO `yyyy-MM-dd`)
/// - `{{date:FORMAT}}`  – Datum mit einfachem Format (yyyy, MM, dd)
/// - `{{time}}`         – aktuelle Uhrzeit (`HH:mm`)
class NotesTemplateService {
  NotesTemplateService._();

  static String apply(String template, {required String title, DateTime? now}) {
    final date = now ?? DateTime.now();
    var out = template;
    out = out.replaceAll('{{title}}', title);
    out = out.replaceAll('{{time}}',
        '${_two(date.hour)}:${_two(date.minute)}');
    // {{date:FORMAT}}
    out = out.replaceAllMapped(
      RegExp(r'\{\{date:([^}]+)\}\}'),
      (m) => _formatDate(date, m.group(1)!),
    );
    out = out.replaceAll('{{date}}', _isoDate(date));
    return out;
  }

  static String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${_two(d.month)}-${_two(d.day)}';

  static String _formatDate(DateTime d, String fmt) {
    return fmt
        .replaceAll('yyyy', d.year.toString().padLeft(4, '0'))
        .replaceAll('MM', _two(d.month))
        .replaceAll('dd', _two(d.day))
        .replaceAll('HH', _two(d.hour))
        .replaceAll('mm', _two(d.minute));
  }

  static String _two(int v) => v.toString().padLeft(2, '0');
}
