import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../l10n/app_localizations.dart';
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
        final l10n = AppLocalizations.of(context)!;
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
            body: Center(
              child: Text(l10n.diaryEntryNotFound,
                  style: const TextStyle(
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
                    await SharePlus.instance.share(
                      ShareParams(
                        files: [XFile(entry.mediaPath)],
                        text: l10n.diaryShareText(entry.date),
                      ),
                    );
                  } else if (value == 'delete') {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (_) => AlertDialog(
                        backgroundColor: TraumColors.surface,
                        title: Text(l10n.diaryDeleteTitle,
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.onBackground)),
                        content: Text(
                            l10n.diaryDeleteMessage,
                            style: const TextStyle(
                                fontFamily: 'DMSans',
                                color: TraumColors.onBackgroundMuted)),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: Text(l10n.cancel,
                                style: const TextStyle(
                                    color: TraumColors.onBackgroundMuted)),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: Text(l10n.delete,
                                style: const TextStyle(color: TraumColors.roseRed)),
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
                  PopupMenuItem(
                    value: 'share',
                    child: Text(l10n.diaryShareLabel,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            color: TraumColors.onBackground)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Text(l10n.delete,
                        style: const TextStyle(
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
                    Text(_formatDate(entry.date, l10n),
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

  String _formatDate(String dateStr, AppLocalizations l10n) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    final weekdays = l10n.weekdaysShort.split(',');
    final months = [
      l10n.monthJan, l10n.monthFeb, l10n.monthMar,
      l10n.monthApr, l10n.monthMay, l10n.monthJun,
      l10n.monthJul, l10n.monthAug, l10n.monthSep,
      l10n.monthOct, l10n.monthNov, l10n.monthDec,
    ];
    return '${weekdays[d.weekday - 1]}, ${d.day}. ${months[d.month - 1]} ${d.year}';
  }
}
