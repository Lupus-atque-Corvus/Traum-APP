import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/components/traum_card.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';
import '../diary_provider.dart';

class DiaryHomeCard extends ConsumerWidget {
  const DiaryHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entryAsync = ref.watch(todaysDiaryEntryProvider);
    return entryAsync.when(
      data: (entry) => entry == null
          ? const _EmptyCard()
          : _FilledCard(entry: entry),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) => TraumCard(
        onTap: () => context.go('/diary'),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: TraumColors.lavender.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.photo_camera_outlined,
                color: TraumColors.lavender, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tagebuch',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        fontWeight: FontWeight.w600,
                        color: TraumColors.onBackground,
                        fontSize: 15)),
                Text('Noch kein Eintrag heute',
                    style: TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.add_circle_outline,
              color: TraumColors.lavender, size: 22),
        ]),
      );
}

class _FilledCard extends StatelessWidget {
  final DiaryEntry entry;
  const _FilledCard({required this.entry});

  @override
  Widget build(BuildContext context) {
    final thumbPath =
        entry.mediaType == 'video' ? entry.thumbnailPath : entry.mediaPath;
    return TraumCard(
      onTap: () => context.go('/diary/entry/${entry.date}'),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: (thumbPath != null && File(thumbPath).existsSync())
              ? Image.file(File(thumbPath),
                  width: 64, height: 64, fit: BoxFit.cover)
              : Container(
                  width: 64,
                  height: 64,
                  color: TraumColors.surfaceVariant,
                  child: const Icon(Icons.photo_outlined,
                      color: TraumColors.onBackgroundSubtle),
                ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Heutiger Eintrag',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      fontWeight: FontWeight.w600,
                      color: TraumColors.onBackground,
                      fontSize: 15)),
              if (entry.note.isNotEmpty)
                Text(entry.note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontFamily: 'DMSans',
                        color: TraumColors.onBackgroundMuted,
                        fontSize: 12)),
            ],
          ),
        ),
        const Icon(Icons.chevron_right,
            color: TraumColors.onBackgroundSubtle),
      ]),
    );
  }
}
