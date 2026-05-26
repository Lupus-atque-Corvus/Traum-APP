import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' show Value;
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/radius.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';

class DiaryScreen extends ConsumerStatefulWidget {
  const DiaryScreen({super.key});

  @override
  ConsumerState<DiaryScreen> createState() => _DiaryScreenState();
}

class _DiaryScreenState extends ConsumerState<DiaryScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  void _prevMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month - 1));

  void _nextMonth() =>
      setState(() => _month = DateTime(_month.year, _month.month + 1));

  List<DateTime?> _daysInMonth() {
    final daysInMonth = DateUtils.getDaysInMonth(_month.year, _month.month);
    final firstWeekday = DateTime(_month.year, _month.month, 1).weekday % 7;
    final cells = <DateTime?>[];
    for (int i = 0; i < firstWeekday; i++) {
      cells.add(null);
    }
    for (int d = 1; d <= daysInMonth; d++) {
      cells.add(DateTime(_month.year, _month.month, d));
    }
    return cells;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final logsAsync = ref.watch(diaryLogsStreamProvider);

    return Scaffold(
      backgroundColor: TraumColors.background,
      appBar: AppBar(
        backgroundColor: TraumColors.background,
        title: Text(l10n.diary,
            style: const TextStyle(
                color: TraumColors.onBackground,
                fontFamily: 'DMSans',
                fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: TraumColors.onBackground),
        elevation: 0,
      ),
      body: logsAsync.when(
        data: (logs) {
          final logsByDate = <String, PhotoLog>{};
          for (final log in logs) {
            final key = _dateKey(log.logDate);
            logsByDate.putIfAbsent(key, () => log);
          }
          return _buildCalendar(context, l10n, logsByDate);
        },
        loading: () => const Center(
            child: CircularProgressIndicator(color: TraumColors.coralOrange)),
        error: (e, _) => Center(child: Text(e.toString())),
      ),
    );
  }

  Widget _buildCalendar(
    BuildContext context,
    AppLocalizations l10n,
    Map<String, PhotoLog> logsByDate,
  ) {
    final cells = _daysInMonth();

    return Column(
      children: [
        // Month navigation
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: _prevMonth,
                icon: const Icon(Icons.chevron_left_rounded,
                    color: TraumColors.onBackground),
              ),
              Text(
                '${_monthName(_month.month, l10n)} ${_month.year}',
                style: const TextStyle(
                    color: TraumColors.onBackground,
                    fontFamily: 'DMSans',
                    fontWeight: FontWeight.w700,
                    fontSize: 16),
              ),
              IconButton(
                onPressed: _nextMonth,
                icon: const Icon(Icons.chevron_right_rounded,
                    color: TraumColors.onBackground),
              ),
            ],
          ),
        ),

        // Day-of-week header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: ['Su', 'Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa']
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: const TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontFamily: 'DMSans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600)),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 4),

        // Calendar grid
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                crossAxisSpacing: 4,
                mainAxisSpacing: 4,
              ),
              itemCount: cells.length,
              itemBuilder: (context, index) {
                final day = cells[index];
                if (day == null) return const SizedBox.shrink();

                final key = _dateKey(day);
                final log = logsByDate[key];
                final isToday = _isToday(day);

                return _DayCell(
                  day: day,
                  log: log,
                  isToday: isToday,
                  onTap: () => _handleDayTap(context, day, log),
                );
              },
            ),
          ),
        ),

        // Recent entries list
        if (logsByDate.isNotEmpty) ...[
          Divider(color: TraumColors.surface, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(l10n.diaryRecentEntries,
                  style: const TextStyle(
                      color: TraumColors.onBackgroundMuted,
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ),
          ),
          SizedBox(
            height: 100,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: logsByDate.length > 10 ? 10 : logsByDate.length,
              itemBuilder: (ctx, i) {
                final log = logsByDate.values.toList()[i];
                return _RecentThumb(
                  log: log,
                  onTap: () => _openViewer(context, log),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }

  Future<void> _handleDayTap(
      BuildContext context, DateTime day, PhotoLog? existing) async {
    if (existing != null) {
      _openViewer(context, existing);
    } else {
      await _addEntry(context, day);
    }
  }

  Future<void> _addEntry(BuildContext context, DateTime day) async {
    final l10n = AppLocalizations.of(context)!;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: TraumColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: TraumColors.onBackgroundSubtle,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded,
                  color: TraumColors.coralOrange),
              title: Text(l10n.takePhoto,
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans')),
              onTap: () => Navigator.pop(ctx, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded,
                  color: TraumColors.indigoBlue),
              title: Text(l10n.chooseFromGallery,
                  style: const TextStyle(
                      color: TraumColors.onBackground, fontFamily: 'DMSans')),
              onTap: () => Navigator.pop(ctx, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !context.mounted) return;

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: source, imageQuality: 85);
    if (picked == null || !context.mounted) return;

    // Copy to app documents directory for persistence
    final appDir = await getApplicationDocumentsDirectory();
    final diaryDir = Directory('${appDir.path}/diary');
    await diaryDir.create(recursive: true);
    final fileName =
        'diary_${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}.jpg';
    final savedPath = '${diaryDir.path}/$fileName';
    await File(picked.path).copy(savedPath);

    await ref.read(healthDaoProvider).insertPhotoLog(
          PhotoLogsCompanion.insert(
            logDate: day,
            imagePath: savedPath,
            category: const Value('diary'),
          ),
        );
  }

  void _openViewer(BuildContext context, PhotoLog log) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DiaryViewerScreen(log: log),
      ),
    );
  }

  String _dateKey(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  bool _isToday(DateTime day) {
    final now = DateTime.now();
    return day.year == now.year && day.month == now.month && day.day == now.day;
  }

  String _monthName(int month, AppLocalizations l10n) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}

// ── Day cell ──────────────────────────────────────────────────────────────────

class _DayCell extends StatelessWidget {
  final DateTime day;
  final PhotoLog? log;
  final bool isToday;
  final VoidCallback onTap;

  const _DayCell({
    required this.day,
    required this.log,
    required this.isToday,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(TraumRadius.card / 2),
        child: log != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(
                    File(log!.imagePath),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: TraumColors.surface,
                      child: const Icon(Icons.broken_image_rounded,
                          color: TraumColors.onBackgroundSubtle, size: 16),
                    ),
                  ),
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      padding: const EdgeInsets.all(1),
                      decoration: BoxDecoration(
                        color: Colors.black54,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${day.day}',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 8,
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              )
            : Container(
                decoration: BoxDecoration(
                  color: isToday
                      ? TraumColors.coralOrange.withAlpha(30)
                      : TraumColors.surface,
                  borderRadius: BorderRadius.circular(TraumRadius.card / 2),
                  border: isToday
                      ? Border.all(color: TraumColors.coralOrange, width: 1.5)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '${day.day}',
                    style: TextStyle(
                        color: isToday
                            ? TraumColors.coralOrange
                            : TraumColors.onBackgroundMuted,
                        fontFamily: 'DMSans',
                        fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                        fontSize: 12),
                  ),
                ),
              ),
      ),
    );
  }
}

// ── Recent thumbnail ──────────────────────────────────────────────────────────

class _RecentThumb extends StatelessWidget {
  final PhotoLog log;
  final VoidCallback onTap;

  const _RecentThumb({required this.log, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(TraumRadius.card),
          color: TraumColors.surface,
        ),
        clipBehavior: Clip.hardEdge,
        child: Image.file(
          File(log.imagePath),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Icon(Icons.broken_image_rounded,
                color: TraumColors.onBackgroundSubtle),
          ),
        ),
      ),
    );
  }
}

// ── Full-screen viewer ────────────────────────────────────────────────────────

class _DiaryViewerScreen extends ConsumerWidget {
  final PhotoLog log;
  const _DiaryViewerScreen({required this.log});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final d = log.logDate;
    final dateStr = '${d.day}.${d.month}.${d.year}';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(dateStr,
            style: const TextStyle(
                color: Colors.white, fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: TraumColors.roseRed),
            onPressed: () => _confirmDelete(context, ref, l10n),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              child: Center(
                child: Image.file(
                  File(log.imagePath),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(Icons.broken_image_rounded,
                        color: Colors.white54, size: 64),
                  ),
                ),
              ),
            ),
          ),
          if (log.note != null && log.note!.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Text(log.note!,
                  style: const TextStyle(
                      color: Colors.white, fontFamily: 'DMSans', fontSize: 14)),
            ),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, WidgetRef ref, AppLocalizations l10n) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: TraumColors.surfaceElevated,
        title: Text(l10n.confirmDelete,
            style: const TextStyle(
                color: TraumColors.onBackground, fontFamily: 'DMSans')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancel,
                style:
                    const TextStyle(color: TraumColors.onBackgroundMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.delete,
                style: const TextStyle(color: TraumColors.roseRed)),
          ),
        ],
      ),
    );
    if (confirmed == true && context.mounted) {
      await ref.read(healthDaoProvider).deletePhotoLog(log.id);
      try {
        await File(log.imagePath).delete();
      } catch (_) {}
      if (context.mounted) Navigator.pop(context);
    }
  }
}
