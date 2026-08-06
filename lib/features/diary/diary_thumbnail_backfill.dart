import 'package:shared_preferences/shared_preferences.dart';
import '../../data/database/traum_database.dart';
import 'diary_camera_service.dart';

/// Einmaliger Nachtrag von Vorschaubildern für Video-Einträge, die vor
/// v0.8.9 angelegt wurden — damals wurde `thumbnailPath` beim Speichern hart
/// auf `null` gesetzt, diese Einträge zeigen seither dauerhaft den
/// Platzhalter statt eines echten Vorschaubilds.
class DiaryThumbnailBackfill {
  static Future<void> runIfNeeded(
    TraumDatabase db,
    SharedPreferences prefs,
  ) async {
    if (prefs.getBool('diary_thumbnail_backfill_v1') == true) return;

    final missing = await db.diaryDao.getVideoEntriesMissingThumbnail();
    for (final entry in missing) {
      final thumbnail =
          await DiaryCameraService.generateVideoThumbnail(entry.mediaPath);
      if (thumbnail != null) {
        await db.diaryDao.updateThumbnail(entry.id, thumbnail);
      }
    }

    await prefs.setBool('diary_thumbnail_backfill_v1', true);
  }
}
