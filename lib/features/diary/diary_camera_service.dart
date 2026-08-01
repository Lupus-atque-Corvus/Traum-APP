import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

class DiaryCameraService {
  static final _picker = ImagePicker();

  /// Erzeugt ein Vorschaubild für ein Video und gibt dessen Pfad zurück
  /// (`null`, wenn es nicht klappt — dann zeigt die Liste den Platzhalter,
  /// der Eintrag selbst bleibt aber speicherbar).
  ///
  /// Die Breite ist bewusst klein gehalten: Das Bild wird nur als
  /// Listen-/Rastervorschau angezeigt, nie in voller Größe.
  static Future<String?> generateVideoThumbnail(String videoPath) async {
    try {
      final dir = await getApplicationSupportDirectory();
      final thumbDir = Directory('${dir.path}/diary/thumbs');
      await thumbDir.create(recursive: true);
      return await VideoThumbnail.thumbnailFile(
        video: videoPath,
        thumbnailPath: thumbDir.path,
        imageFormat: ImageFormat.JPEG,
        maxWidth: 720,
        quality: 75,
      );
    } catch (e, st) {
      debugPrint('Video-Vorschaubild fehlgeschlagen: $e\n$st');
      return null;
    }
  }

  static Future<String?> capturePhoto({
    required String dateStr,
    ImageSource source = ImageSource.camera,
  }) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _saveToAppStorage(picked.path, dateStr, 'jpg');
  }

  static Future<String?> captureVideo({
    required String dateStr,
    ImageSource source = ImageSource.camera,
  }) async {
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return null;
    return _saveToAppStorage(picked.path, dateStr, 'mp4');
  }

  static Future<String> _saveToAppStorage(
    String sourcePath,
    String dateStr,
    String extension,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final diaryDir = Directory('${dir.path}/diary');
    await diaryDir.create(recursive: true);
    final destPath =
        '${diaryDir.path}/diary_${dateStr}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
