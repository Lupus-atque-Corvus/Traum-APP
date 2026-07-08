import 'dart:io';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/providers/database_provider.dart';
import '../../core/theme/colors.dart';
import '../../data/database/traum_database.dart';
import '../../l10n/app_localizations.dart';
import 'diary_camera_service.dart';
import 'diary_provider.dart';

class DiaryCaptureSheet extends ConsumerStatefulWidget {
  final String mediaPath;
  final String mediaType;
  final String date;

  const DiaryCaptureSheet({
    super.key,
    required this.mediaPath,
    required this.mediaType,
    required this.date,
  });

  @override
  ConsumerState<DiaryCaptureSheet> createState() =>
      _DiaryCaptureSheetState();
}

class _DiaryCaptureSheetState extends ConsumerState<DiaryCaptureSheet> {
  late String _mediaPath;
  late String _mediaType;
  final _noteCtrl = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _mediaPath = widget.mediaPath;
    _mediaType = widget.mediaType;
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await ref.read(diaryDaoProvider).upsertEntry(
            DiaryEntriesCompanion(
              date: Value(widget.date),
              mediaPath: Value(_mediaPath),
              mediaType: Value(_mediaType),
              note: Value(_noteCtrl.text.trim()),
              thumbnailPath: const Value(null),
              createdAt: Value(DateTime.now()),
              updatedAt: Value(DateTime.now()),
            ),
          );
      ref.invalidate(todaysDiaryEntryProvider);
      ref.invalidate(datesWithDiaryEntriesProvider);
      ref.invalidate(diaryEntriesForMonthProvider);
      ref.invalidate(diaryStreakProvider);
      ref.invalidate(totalDiaryEntriesProvider);
      if (mounted) Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _retake() async {
    final newPath = _mediaType == 'photo'
        ? await DiaryCameraService.capturePhoto(
            dateStr: widget.date, source: ImageSource.camera)
        : await DiaryCameraService.captureVideo(
            dateStr: widget.date, source: ImageSource.camera);
    if (newPath != null && mounted) {
      setState(() => _mediaPath = newPath);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isPhoto = _mediaType == 'photo';

    return Container(
      margin: EdgeInsets.only(bottom: bottom),
      decoration: const BoxDecoration(
        color: TraumColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            if (File(_mediaPath).existsSync() && isPhoto)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(File(_mediaPath),
                    height: 200, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: TraumColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Icon(Icons.videocam_outlined,
                      color: TraumColors.onBackgroundMuted, size: 40),
                ),
              ),
            const SizedBox(height: 14),
            TextField(
              controller: _noteCtrl,
              maxLines: 2,
              maxLength: 200,
              style: const TextStyle(
                  fontFamily: 'DMSans',
                  color: TraumColors.onBackground,
                  fontSize: 14),
              decoration: InputDecoration(
                hintText: l10n.diaryNoteHint,
                hintStyle: const TextStyle(
                    fontFamily: 'DMSans',
                    color: TraumColors.onBackgroundSubtle,
                    fontSize: 13),
                filled: true,
                fillColor: TraumColors.surfaceVariant,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 50,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: TraumColors.lavender,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(50)),
                ),
                child: _saving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : Text(l10n.save,
                        style: const TextStyle(
                            fontFamily: 'DMSans',
                            fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: _retake,
              child: Text(l10n.diaryRetake,
                  style: const TextStyle(
                      fontFamily: 'DMSans',
                      color: TraumColors.onBackgroundMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
