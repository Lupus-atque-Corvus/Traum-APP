import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../diary_provider.dart';

class DiaryCalendarGrid extends ConsumerStatefulWidget {
  const DiaryCalendarGrid({super.key});

  @override
  ConsumerState<DiaryCalendarGrid> createState() => _DiaryCalendarGridState();
}

class _DiaryCalendarGridState extends ConsumerState<DiaryCalendarGrid> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final ym = (_month.year, _month.month);
    final entriesAsync = ref.watch(diaryEntriesForMonthProvider(ym));
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () => setState(
                () => _month = DateTime(_month.year, _month.month - 1)),
            child: const Icon(Icons.chevron_left,
                color: TraumColors.onBackground, size: 24),
          ),
          const Spacer(),
          Text(_monthYear(_month),
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  color: TraumColors.onBackground,
                  fontSize: 16)),
          const Spacer(),
          GestureDetector(
            onTap: () => setState(
                () => _month = DateTime(_month.year, _month.month + 1)),
            child: const Icon(Icons.chevron_right,
                color: TraumColors.onBackground, size: 24),
          ),
        ]),
        const SizedBox(height: 12),
        Row(
          children: weekdays
              .map((d) => Expanded(
                    child: Text(d,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: TraumColors.onBackgroundSubtle)),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),
        entriesAsync.when(
          data: (entries) {
            final entryMap = {for (final e in entries) e.date: e};
            final firstDay = DateTime(_month.year, _month.month, 1);
            final daysInMonth =
                DateTime(_month.year, _month.month + 1, 0).day;
            final startOffset = (firstDay.weekday - 1) % 7;
            final totalCells =
                ((startOffset + daysInMonth) / 7).ceil() * 7;

            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 7,
                      crossAxisSpacing: 4,
                      mainAxisSpacing: 4,
                      childAspectRatio: 1),
              itemCount: totalCells,
              itemBuilder: (_, i) {
                if (i < startOffset || i >= startOffset + daysInMonth) {
                  return const SizedBox.shrink();
                }
                final day = i - startOffset + 1;
                final date = DateTime(_month.year, _month.month, day);
                final dateStr =
                    '${_month.year.toString().padLeft(4, '0')}-${_month.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
                final entry = entryMap[dateStr];
                final isToday = date == today;
                final isFuture = date.isAfter(today);
                final thumbPath = entry?.mediaType == 'video'
                    ? entry?.thumbnailPath
                    : entry?.mediaPath;
                final hasThumb =
                    thumbPath != null && File(thumbPath).existsSync();

                return GestureDetector(
                  onTap: () {
                    if (entry != null) {
                      context.go('/diary/entry/$dateStr');
                    }
                  },
                  child: Opacity(
                    opacity: isFuture ? 0.3 : 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: isToday
                            ? Border.all(
                                color: TraumColors.coralOrange, width: 1.5)
                            : null,
                        image: hasThumb
                            ? DecorationImage(
                                image: FileImage(File(thumbPath)),
                                fit: BoxFit.cover)
                            : null,
                        color: hasThumb ? null : TraumColors.surfaceVariant,
                      ),
                      child: Stack(children: [
                        Positioned(
                          top: 3,
                          left: 4,
                          child: Text('$day',
                              style: TextStyle(
                                  fontFamily: 'DMSans',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: hasThumb
                                      ? Colors.white
                                      : TraumColors.onBackgroundMuted,
                                  shadows: hasThumb
                                      ? const [
                                          Shadow(
                                              color: Colors.black54,
                                              blurRadius: 3)
                                        ]
                                      : null)),
                        ),
                      ]),
                    ),
                  ),
                );
              },
            );
          },
          loading: () => const SizedBox(
              height: 200,
              child: Center(
                  child: CircularProgressIndicator(
                      color: TraumColors.lavender))),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ]),
    );
  }

  String _monthYear(DateTime d) {
    const m = ['Jan','Feb','Mär','Apr','Mai','Jun',
        'Jul','Aug','Sep','Okt','Nov','Dez'];
    return '${m[d.month - 1]} ${d.year}';
  }
}
