import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import 'diary_camera_service.dart';
import 'diary_capture_sheet.dart';
import 'diary_provider.dart';
import 'widgets/diary_calendar_grid.dart';
import 'widgets/diary_entry_card.dart';
import 'widgets/diary_year_heatmap.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final todayAsync = ref.watch(todaysDiaryEntryProvider);
    final streakAsync = ref.watch(diaryStreakProvider);
    final totalAsync = ref.watch(totalDiaryEntriesProvider);
    final recentAsync = ref.watch(recentDiaryEntriesProvider(30));
    final todayStr = DiaryCameraService.formatDate(DateTime.now());

    return Scaffold(
      backgroundColor: TraumColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.top + 8),
          ),

          // ── Header ──────────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 0),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tagebuch',
                          style: TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: TraumColors.onBackground,
                              fontSize: 24)),
                      Row(children: [
                        totalAsync.when(
                          data: (t) => Text('$t Einträge',
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackgroundMuted,
                                  fontSize: 13)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const Text(' · ',
                            style: TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontSize: 13)),
                        streakAsync.when(
                          data: (s) => Text('Streak: $s Tage',
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.lavender,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ]),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.slideshow_outlined,
                      color: TraumColors.lavender),
                  onPressed: () => context.go('/diary/slideshow'),
                ),
              ]),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // ── Heute-Card ───────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: todayAsync.when(
              data: (entry) => entry == null
                  ? _TodayEmptyCard(
                      todayStr: todayStr,
                      onCapture: (path, type) =>
                          _openCaptureSheet(context, path, type, todayStr),
                    )
                  : _TodayFilledCard(entry: entry),
              loading: () => const SizedBox(height: 80),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // ── Kalender ─────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: DiaryCalendarGrid()),

          // ── Heatmap ──────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: DiaryYearHeatmap()),

          // ── Letzte Einträge ───────────────────────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text('Letzte Einträge',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      color: TraumColors.onBackground,
                      fontSize: 16)),
            ),
          ),
          SliverToBoxAdapter(
            child: recentAsync.when(
              data: (entries) {
                if (entries.isEmpty) return const SizedBox.shrink();
                return SizedBox(
                  height: 140,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => DiaryEntryCard(entry: entries[i]),
                  ),
                );
              },
              loading: () => const SizedBox.shrink(),
              error: (_, _) => const SizedBox.shrink(),
            ),
          ),

          SliverPadding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).padding.bottom + 90),
          ),
        ],
      ),
    );
  }

  void _openCaptureSheet(
      BuildContext context, String path, String type, String dateStr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiaryCaptureSheet(
        mediaPath: path,
        mediaType: type,
        date: dateStr,
      ),
    );
  }
}

// ── Heute leer ───────────────────────────────────────────────────────────────

class _TodayEmptyCard extends StatelessWidget {
  final String todayStr;
  final void Function(String path, String type) onCapture;

  const _TodayEmptyCard({required this.todayStr, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
        Icon(Icons.photo_camera_outlined,
            size: 64,
            color: TraumColors.lavender.withValues(alpha: 0.4)),
        const SizedBox(height: 8),
        Text(_todayLabel(),
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 14)),
        const SizedBox(height: 4),
        const Text('Halte diesen Moment fest.',
            style: TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundSubtle,
                fontSize: 13)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final path = await DiaryCameraService.capturePhoto(
                    dateStr: todayStr);
                if (path != null && context.mounted) {
                  onCapture(path, 'photo');
                }
              },
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: const Text('Foto',
                  style: TextStyle(
                      fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TraumColors.lavender,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () async {
                final path = await DiaryCameraService.captureVideo(
                    dateStr: todayStr);
                if (path != null && context.mounted) {
                  onCapture(path, 'video');
                }
              },
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: const Text('Video',
                  style: TextStyle(
                      fontFamily: 'DMSans', fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: TraumColors.indigoBlue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ]),
      ]),
    );
  }

  String _todayLabel() {
    final d = DateTime.now();
    const weekdays = [
      'Montag', 'Dienstag', 'Mittwoch', 'Donnerstag',
      'Freitag', 'Samstag', 'Sonntag'
    ];
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}

// ── Heute gefüllt ────────────────────────────────────────────────────────────

class _TodayFilledCard extends StatelessWidget {
  final DiaryEntry entry;
  const _TodayFilledCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final thumbPath =
        entry.mediaType == 'video' ? entry.thumbnailPath : entry.mediaPath;
    final hasThumb = thumbPath != null && File(thumbPath).existsSync();

    return GestureDetector(
      onTap: () => context.go('/diary/entry/${entry.date}'),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          if (hasThumb)
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Image.file(
                File(thumbPath),
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.note.isNotEmpty)
                      Text(entry.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackground,
                              fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(_formatDate(entry.date),
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackgroundMuted,
                            fontSize: 12)),
                  ],
                ),
              ),
              const Icon(Icons.edit_outlined,
                  color: TraumColors.onBackgroundMuted, size: 18),
            ]),
          ),
        ]),
      ),
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const months = ['Jan','Feb','Mär','Apr','Mai','Jun',
        'Jul','Aug','Sep','Okt','Nov','Dez'];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}
