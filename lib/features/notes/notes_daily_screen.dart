import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../core/navigation/routes.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'notes_providers.dart';
import 'notes_template_service.dart';
import 'widgets/notes_common.dart';

/// Tagesnotizen-Übersicht mit `table_calendar`.
class NotesDailyScreen extends ConsumerStatefulWidget {
  const NotesDailyScreen({super.key});

  @override
  ConsumerState<NotesDailyScreen> createState() => _NotesDailyScreenState();
}

class _NotesDailyScreenState extends ConsumerState<NotesDailyScreen> {
  DateTime _focused = DateTime.now();
  DateTime _selected = DateTime.now();

  String _isoDate(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _openOrCreate(DateTime date) async {
    final repo = ref.read(notesRepositoryProvider);
    final existing = await repo.getDailyNote(date);
    if (existing != null) {
      if (mounted) context.push(Routes.noteDetailPath(existing.id));
      return;
    }
    // Optional aus Daily-Vorlage befüllen.
    final templates = await repo.watchTemplates().first;
    final daily = templates.where((t) => t.name.toLowerCase() == 'daily');
    final title = _isoDate(date);
    final content = daily.isNotEmpty
        ? NotesTemplateService.apply(daily.first.content,
            title: title, now: date)
        : '';
    final id = await repo.createNote(
      title: title,
      content: content,
      isDaily: true,
      dailyDate: DateTime(date.year, date.month, date.day),
    );
    if (mounted) context.push(Routes.noteDetailPath(id));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final daily = ref.watch(dailyNotesStreamProvider);
    final dailyNotes = daily.valueOrNull ?? const <Note>[];
    final byDay = <DateTime, Note>{
      for (final n in dailyNotes)
        if (n.dailyDate != null)
          DateTime(n.dailyDate!.year, n.dailyDate!.month, n.dailyDate!.day): n,
    };

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        elevation: 0,
        leading: BackButton(
            color: TraumColors.onBackground, onPressed: () => context.pop()),
        title: Text(l10n.notes_daily,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackground,
                fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: TraumColors.surface,
              borderRadius: BorderRadius.circular(TraumRadius.card),
              border: Border.all(color: TraumColors.surfaceVariant),
            ),
            child: TableCalendar<Note>(
              firstDay: DateTime.utc(2015, 1, 1),
              lastDay: DateTime.utc(2100, 12, 31),
              focusedDay: _focused,
              selectedDayPredicate: (d) => isSameDay(d, _selected),
              eventLoader: (day) {
                final key = DateTime(day.year, day.month, day.day);
                return byDay.containsKey(key) ? [byDay[key]!] : const [];
              },
              onDaySelected: (selected, focused) {
                setState(() {
                  _selected = selected;
                  _focused = focused;
                });
                _openOrCreate(selected);
              },
              calendarStyle: CalendarStyle(
                defaultTextStyle: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackground),
                weekendTextStyle: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted),
                outsideTextStyle: const TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackgroundSubtle),
                todayDecoration: BoxDecoration(
                  color: kNotesAccent.withValues(alpha: 0.25),
                  shape: BoxShape.circle,
                ),
                selectedDecoration: const BoxDecoration(
                  color: kNotesAccent,
                  shape: BoxShape.circle,
                ),
                markerDecoration: const BoxDecoration(
                  color: TraumColors.cyanBlue,
                  shape: BoxShape.circle,
                ),
              ),
              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle: TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackground,
                    fontWeight: FontWeight.w700),
                leftChevronIcon: Icon(Icons.chevron_left_rounded,
                    color: TraumColors.onBackgroundMuted),
                rightChevronIcon: Icon(Icons.chevron_right_rounded,
                    color: TraumColors.onBackgroundMuted),
              ),
              daysOfWeekStyle: const DaysOfWeekStyle(
                weekdayStyle: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackgroundMuted),
                weekendStyle: TextStyle(
                    fontFamily: 'DMSans', color: TraumColors.onBackgroundSubtle),
              ),
            ),
          ),
          Expanded(
            child: dailyNotes.isEmpty
                ? NotesEmptyState(
                    icon: Icons.today_rounded, message: l10n.notes_no_daily)
                : ListView(
                    children: ([...dailyNotes]
                          ..sort((a, b) =>
                              (b.dailyDate ?? b.createdAt)
                                  .compareTo(a.dailyDate ?? a.createdAt)))
                        .map((n) => NoteListTile(
                              note: n,
                              onTap: () =>
                                  context.push(Routes.noteDetailPath(n.id)),
                            ))
                        .toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
