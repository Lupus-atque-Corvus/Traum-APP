import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/colors.dart';
import '../../core/utils/image_decode.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'diary_camera_service.dart';
import 'diary_capture_sheet.dart';
import 'diary_edit_sheet.dart';
import 'diary_provider.dart';
import 'diary_search_screen.dart';
import 'diary_visuals.dart';
import 'widgets/diary_calendar_grid.dart';
import 'widgets/diary_entry_card.dart';
import 'widgets/diary_year_heatmap.dart';
import '../../core/components/inline_error.dart';

class DiaryScreen extends ConsumerWidget {
  const DiaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final diaryId = ref.watch(activeDiaryProvider);
    final activeDiaryAsync = ref.watch(activeDiaryInfoProvider);
    final todayAsync = ref.watch(todaysDiaryEntryProvider);
    final streakAsync = ref.watch(diaryStreakProvider);
    final totalAsync = ref.watch(totalDiaryEntriesProvider);
    final recentAsync = ref.watch(recentDiaryEntriesProvider(30));
    final ghostImagePath = ref.watch(diaryGhostImageProvider).value;
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
                GestureDetector(
                  onTap: () => _showDiarySwitcher(context, ref),
                  child: _DiarySwitchAvatar(diaryAsync: activeDiaryAsync),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => _showDiarySwitcher(context, ref),
                    child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          activeDiaryAsync.maybeWhen(
                              data: (d) => d?.name ?? l10n.diaryTitle,
                              orElse: () => l10n.diaryTitle),
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              fontWeight: FontWeight.w700,
                              color: TraumColors.onBackground,
                              fontSize: 24)),
                      Row(children: [
                        totalAsync.when(
                          data: (t) => Text(l10n.diaryTotalEntries(t),
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.onBackgroundMuted,
                                  fontSize: 13)),
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => InlineError(e),
                        ),
                        const Text(' · ',
                            style: TextStyle(
                                color: TraumColors.onBackgroundSubtle,
                                fontSize: 13)),
                        streakAsync.when(
                          data: (s) => Text(l10n.diaryStreakDays(s),
                              style: const TextStyle(
                                  fontFamily: 'DMSans',
                                  color: TraumColors.lavender,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          loading: () => const SizedBox.shrink(),
                          error: (e, _) => InlineError(e),
                        ),
                      ]),
                    ],
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.search,
                  icon: const Icon(Icons.search_rounded,
                      color: TraumColors.lavender),
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                        builder: (_) => const DiarySearchScreen()),
                  ),
                ),
                IconButton(
                  tooltip: l10n.diarySlideshow,
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
                      diaryId: diaryId,
                      todayStr: todayStr,
                      ghostImagePath: ghostImagePath,
                      onCapture: (path, type) => _openCaptureSheet(
                          context, diaryId, path, type, todayStr),
                    )
                  : _TodayFilledCard(entry: entry),
              loading: () => const SizedBox(height: 80),
              error: (e, _) => InlineError(e),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 4)),

          // ── Kalender ─────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: DiaryCalendarGrid()),

          // ── Heatmap ──────────────────────────────────────────────────────
          const SliverToBoxAdapter(child: DiaryYearHeatmap()),

          // ── Letzte Einträge ───────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Text(l10n.diaryRecentEntries,
                  style: const TextStyle(
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
              error: (e, _) => InlineError(e),
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

  void _openCaptureSheet(BuildContext context, int diaryId, String path,
      String type, String dateStr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DiaryCaptureSheet(
        diaryId: diaryId,
        mediaPath: path,
        mediaType: type,
        date: dateStr,
      ),
    );
  }

  void _showDiarySwitcher(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: TraumColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Consumer(
        builder: (ctx, ref, _) {
          final l10n = AppLocalizations.of(ctx)!;
          final diariesAsync = ref.watch(diariesProvider);
          final active = ref.watch(activeDiaryProvider);
          return diariesAsync.when(
            data: (list) => SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: TraumColors.onBackgroundSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    l10n.diarySwitcherTitle,
                    style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: TraumColors.onBackground,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...list.map((d) => _DiaryRow(
                        diary: d,
                        isActive: active == d.id,
                        onTap: () {
                          ref.read(activeDiaryProvider.notifier).set(d.id);
                          Navigator.pop(ctx);
                        },
                        onEdit: () {
                          Navigator.pop(ctx);
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (_) => DiaryEditSheet(diary: d),
                          );
                        },
                      )),
                  ListTile(
                    onTap: () {
                      Navigator.pop(ctx);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (_) => const DiaryEditSheet(),
                      );
                    },
                    leading: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: TraumColors.surfaceVariant,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.add,
                          color: TraumColors.onBackgroundMuted),
                    ),
                    title: Text(l10n.diaryNewDiary,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.lavender,
                            fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            loading: () => const Padding(
              padding: EdgeInsets.all(32),
              child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.lavender)),
            ),
            error: (e, _) => Padding(
                padding: const EdgeInsets.all(24), child: InlineError(e)),
          );
        },
      ),
    );
  }
}

class _DiaryRow extends ConsumerWidget {
  final Diary diary;
  final bool isActive;
  final VoidCallback onTap;
  final VoidCallback onEdit;

  const _DiaryRow({
    required this.diary,
    required this.isActive,
    required this.onTap,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final countAsync = ref.watch(diaryEntryCountProvider(diary.id));
    final accent = diaryColor(diary);
    return ListTile(
      onTap: onTap,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: accent.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(diaryIcon(diary.iconName), color: accent, size: 22),
      ),
      title: Text(diary.name,
          style: const TextStyle(
              fontFamily: 'DMSans',
              color: TraumColors.onBackground,
              fontWeight: FontWeight.w600)),
      subtitle: countAsync.when(
        data: (c) => Text(l10n.diaryTotalEntries(c),
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 12)),
        loading: () => const SizedBox.shrink(),
        error: (_, _) => const SizedBox.shrink(),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isActive)
            const Icon(Icons.check_circle, color: TraumColors.mintGreen),
          IconButton(
            tooltip: l10n.edit,
            icon: const Icon(Icons.edit_outlined,
                color: TraumColors.onBackgroundMuted),
            onPressed: onEdit,
          ),
        ],
      ),
    );
  }
}

/// Icon-Button vor dem Tagebuch-Namen im Header — soll auf den ersten Blick
/// erkennbar machen, dass hier mehrere Tagebücher stecken und man tippen
/// kann, um zu wechseln (statt nur der unauffällige Titel-Text selbst).
class _DiarySwitchAvatar extends StatelessWidget {
  final AsyncValue<Diary?> diaryAsync;
  const _DiarySwitchAvatar({required this.diaryAsync});

  @override
  Widget build(BuildContext context) {
    final diary = diaryAsync.value;
    final accent = diary != null ? diaryColor(diary) : TraumColors.lavender;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(clipBehavior: Clip.none, children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: accent.withValues(alpha: 0.4)),
          ),
          child: Icon(diary != null ? diaryIcon(diary.iconName) : Icons.menu_book_outlined,
              color: accent, size: 21),
        ),
        Positioned(
          right: -3,
          bottom: -3,
          child: Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: TraumColors.surfaceElevated,
              shape: BoxShape.circle,
              border: Border.all(color: TraumColors.background, width: 2),
            ),
            child: const Icon(Icons.swap_horiz,
                color: TraumColors.onBackgroundMuted, size: 11),
          ),
        ),
      ]),
    );
  }
}

// ── Heute leer ───────────────────────────────────────────────────────────────

class _TodayEmptyCard extends StatefulWidget {
  final int diaryId;
  final String todayStr;
  final String? ghostImagePath;
  final void Function(String path, String type) onCapture;

  const _TodayEmptyCard(
      {required this.diaryId,
      required this.todayStr,
      required this.ghostImagePath,
      required this.onCapture});

  @override
  State<_TodayEmptyCard> createState() => _TodayEmptyCardState();
}

class _TodayEmptyCardState extends State<_TodayEmptyCard> {
  // Verhindert, dass ein Doppel-Tap auf "Foto"/"Video" zwei parallele
  // Kamera-Flows startet, die beide unabhängig speichern und so zwei Zeilen
  // für denselben Tag anlegen könnten.
  bool _busy = false;

  Future<void> _capture(
      {required bool video}) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final path = video
          ? await DiaryCameraService.captureVideo(
              context: context,
              diaryId: widget.diaryId,
              dateStr: widget.todayStr,
              ghostImagePath: widget.ghostImagePath)
          : await DiaryCameraService.capturePhoto(
              context: context,
              diaryId: widget.diaryId,
              dateStr: widget.todayStr,
              ghostImagePath: widget.ghostImagePath);
      if (path != null && mounted) {
        widget.onCapture(path, video ? 'video' : 'photo');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
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
        Text(_todayLabel(l10n),
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundMuted,
                fontSize: 14)),
        const SizedBox(height: 4),
        Text(l10n.diaryCaptureMomentHint,
            style: const TextStyle(
                fontFamily: 'DMSans',
                color: TraumColors.onBackgroundSubtle,
                fontSize: 13)),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(
            child: ElevatedButton.icon(
              onPressed: _busy ? null : () => _capture(video: false),
              icon: const Icon(Icons.photo_camera_outlined, size: 18),
              label: Text(l10n.diaryPhotoLabel,
                  style: const TextStyle(
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
              onPressed: _busy ? null : () => _capture(video: true),
              icon: const Icon(Icons.videocam_outlined, size: 18),
              label: Text(l10n.diaryVideoLabel,
                  style: const TextStyle(
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

  String _todayLabel(AppLocalizations l10n) {
    final d = DateTime.now();
    final weekdays = l10n.weekdaysFull.split(',');
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar,
      l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep,
      l10n.monthOct, l10n.monthNov, l10n.monthDec,
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
    final l10n = AppLocalizations.of(context)!;
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
                cacheWidth:
                    decodePxFor(context, MediaQuery.sizeOf(context).width - 32),
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
                    Text(_formatDate(entry.date, l10n),
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

  String _formatDate(String dateStr, AppLocalizations l10n) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final weekdays = l10n.weekdaysShort.split(',');
    final months = [
      l10n.monthShortJan, l10n.monthShortFeb, l10n.monthShortMar,
      l10n.monthShortApr, l10n.monthShortMay, l10n.monthShortJun,
      l10n.monthShortJul, l10n.monthShortAug, l10n.monthShortSep,
      l10n.monthShortOct, l10n.monthShortNov, l10n.monthShortDec,
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}
