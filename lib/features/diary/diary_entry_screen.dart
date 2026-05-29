import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import 'diary_provider.dart';

class DiaryEntryScreen extends ConsumerWidget {
  final String date;
  const DiaryEntryScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DiaryEntryBody(date: date);
  }
}

class _DiaryEntryBody extends ConsumerWidget {
  final String date;
  const _DiaryEntryBody({required this.date});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dao = ref.watch(diaryDaoProvider);

    return FutureBuilder(
      future: dao.getEntryForDate(date),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: TraumColors.background,
            body: Center(
              child: CircularProgressIndicator(color: TraumColors.lavender),
            ),
          );
        }

        final entry = snapshot.data;

        if (entry == null) {
          return Scaffold(
            backgroundColor: TraumColors.background,
            appBar: AppBar(
              backgroundColor: Colors.transparent,
              leading: const BackButton(color: Colors.white),
              elevation: 0,
            ),
            body: const Center(
              child: Text('Eintrag nicht gefunden',
                  style: TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted)),
            ),
          );
        }

        final mediaPath = entry.mediaPath;
        final fileExists = File(mediaPath).existsSync();

        return Scaffold(
          backgroundColor: Colors.black,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: const BackButton(color: Colors.white),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.white),
                color: TraumColors.surface,
                onSelected: (value) async {
                  if (value == 'share') {
                    await Share.shareXFiles(
                      [XFile(entry.mediaPath)],
                      text: 'Tagebucheintrag ${entry.date}',
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: TraumColors.surface,
                        title: const Text('Eintrag löschen?',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.onBackground)),
                        content: const Text(
                            'Der Eintrag und die Mediendatei werden dauerhaft gelöscht.',
                            style: TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.onBackgroundMuted)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Abbrechen',
                                style: TextStyle(
                                    color: TraumColors.onBackgroundMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Löschen',
                                style: TextStyle(color: TraumColors.roseRed)),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true && context.mounted) {
                      try {
                        final f = File(entry.mediaPath);
                        if (await f.exists()) await f.delete();
                      } catch (_) {}
                      await ref.read(diaryDaoProvider).deleteEntry(entry.id);
                      ref.invalidate(todaysDiaryEntryProvider);
                      ref.invalidate(datesWithDiaryEntriesProvider);
                      ref.invalidate(diaryEntriesForMonthProvider);
                      if (context.mounted) context.go('/diary');
                    }
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'share',
                    child: Text('Teilen',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground)),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Löschen',
                        style: TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.roseRed)),
                  ),
                ],
              ),
            ],
          ),
          body: Column(children: [
            Expanded(
              flex: 7,
              child: fileExists
                  ? Image.file(File(mediaPath),
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover)
                  : Container(
                      color: TraumColors.surfaceVariant,
                      child: const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: TraumColors.onBackgroundSubtle, size: 60),
                      ),
                    ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                color: TraumColors.surface,
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_formatDate(entry.date),
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            color: TraumColors.onBackground,
                            fontSize: 16)),
                    if (entry.note.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(entry.note,
                          style: const TextStyle(
                              fontFamily: 'DMSans',
                              color: TraumColors.onBackground,
                              fontSize: 14)),
                    ],
                  ],
                ),
              ),
            ),
          ]),
        );
      },
    );
  }

  String _formatDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const weekdays = ['Mo', 'Di', 'Mi', 'Do', 'Fr', 'Sa', 'So'];
    const months = [
      'Januar', 'Februar', 'März', 'April', 'Mai', 'Juni',
      'Juli', 'August', 'September', 'Oktober', 'November', 'Dezember'
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}
