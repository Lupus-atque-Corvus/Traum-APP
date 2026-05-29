import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/colors.dart';
import '../../../data/database/traum_database.dart';

class DiaryEntryCard extends StatelessWidget {
  final DiaryEntry entry;
  const DiaryEntryCard({super.key, required this.entry});

  @override
  Widget build(BuildContext context) {
    final thumbPath =
        entry.mediaType == 'video' ? entry.thumbnailPath : entry.mediaPath;
    return GestureDetector(
      onTap: () => context.go('/diary/entry/${entry.date}'),
      child: Container(
        width: 100,
        height: 130,
        decoration: BoxDecoration(
          color: TraumColors.surface,
          borderRadius: BorderRadius.circular(14),
          image: (thumbPath != null && File(thumbPath).existsSync())
              ? DecorationImage(
                  image: FileImage(File(thumbPath)),
                  fit: BoxFit.cover,
                )
              : null,
        ),
        child: Stack(
          children: [
            if (thumbPath == null || !File(thumbPath).existsSync())
              Center(
                child: Icon(Icons.photo_outlined,
                    color: TraumColors.onBackgroundSubtle, size: 28),
              ),
            if (entry.mediaType == 'video')
              const Center(
                child: Icon(Icons.play_circle_outline,
                    color: Colors.white, size: 28),
              ),
            Positioned(
              bottom: 6,
              left: 6,
              child: Text(
                _shortDate(entry.date),
                style: const TextStyle(
                  fontFamily: 'DMSans',
                  fontSize: 11,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(String dateStr) {
    final d = DateTime.tryParse(dateStr);
    if (d == null) return dateStr;
    const months = ['Jan','Feb','Mär','Apr','Mai','Jun',
        'Jul','Aug','Sep','Okt','Nov','Dez'];
    return '${d.day}. ${months[d.month - 1]}';
  }
}
