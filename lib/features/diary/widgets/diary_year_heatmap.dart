import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/colors.dart';
import '../diary_provider.dart';

class DiaryYearHeatmap extends ConsumerWidget {
  const DiaryYearHeatmap({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final datesAsync = ref.watch(datesWithDiaryEntriesProvider);
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
        datesAsync.when(
          data: (dates) {
            const totalDays = 365;
            final withEntries = dates.length;
            final pct = (withEntries / totalDays * 100).toStringAsFixed(0);
            return Row(children: [
              Text('${now.year}',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      color: TraumColors.onBackground,
                      fontSize: 16)),
              const Spacer(),
              Text('$withEntries Einträge · $pct% Tage',
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      fontSize: 12,
                      color: TraumColors.onBackgroundMuted)),
            ]);
          },
          loading: () => const Text('Jahresübersicht',
              style: TextStyle(
                  fontFamily: 'DMSans',
                  fontWeight: FontWeight.w600,
                  color: TraumColors.onBackground,
                  fontSize: 16)),
          error: (_, _) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 12),
        datesAsync.when(
          data: (dates) {
            final startDate = today.subtract(const Duration(days: 364));
            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(53, (week) {
                  return Column(
                    children: List.generate(7, (dayOfWeek) {
                      final date =
                          startDate.add(Duration(days: week * 7 + dayOfWeek));
                      if (date.isAfter(today)) {
                        return const SizedBox(width: 10, height: 10);
                      }
                      final dateStr =
                          '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                      final hasEntry = dates.contains(dateStr);
                      final isToday = date == today;
                      return Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.all(1),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          color: isToday
                              ? TraumColors.coralOrange
                              : hasEntry
                                  ? TraumColors.lavender
                                  : TraumColors.surfaceVariant,
                        ),
                      );
                    }),
                  );
                }),
              ),
            );
          },
          loading: () => const Center(
              child: CircularProgressIndicator(
                  color: TraumColors.lavender, strokeWidth: 2)),
          error: (_, _) => const SizedBox.shrink(),
        ),
      ]),
    );
  }
}
