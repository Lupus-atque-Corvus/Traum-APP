import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import '../../core/camera/overlay_camera_screen.dart';

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

  /// Nimmt ein Foto auf. Bei `source: ImageSource.camera` (Default) öffnet
  /// sich der eigene [OverlayCameraScreen] statt der nativen Kamera-App —
  /// nur so lässt sich das Geist-Overlay des letzten Fotos einblenden.
  static Future<String?> capturePhoto({
    required BuildContext context,
    required int diaryId,
    required String dateStr,
    String? ghostImagePath,
    ImageSource source = ImageSource.camera,
  }) async {
    if (source == ImageSource.camera) {
      return _openOverlayCamera(
        context,
        diaryId: diaryId,
        dateStr: dateStr,
        ghostImagePath: ghostImagePath,
        initialVideoMode: false,
      );
    }
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1920,
      maxHeight: 1920,
      imageQuality: 85,
    );
    if (picked == null) return null;
    return _saveToAppStorage(picked.path, diaryId, dateStr, 'jpg');
  }

  static Future<String?> captureVideo({
    required BuildContext context,
    required int diaryId,
    required String dateStr,
    String? ghostImagePath,
    ImageSource source = ImageSource.camera,
  }) async {
    if (source == ImageSource.camera) {
      return _openOverlayCamera(
        context,
        diaryId: diaryId,
        dateStr: dateStr,
        ghostImagePath: ghostImagePath,
        initialVideoMode: true,
      );
    }
    final picked = await _picker.pickVideo(
      source: source,
      maxDuration: const Duration(seconds: 60),
    );
    if (picked == null) return null;
    return _saveToAppStorage(picked.path, diaryId, dateStr, 'mp4');
  }

  static Future<String?> _openOverlayCamera(
    BuildContext context, {
    required int diaryId,
    required String dateStr,
    required String? ghostImagePath,
    required bool initialVideoMode,
  }) async {
    final result = await Navigator.of(context).push<CameraCaptureResult>(
      MaterialPageRoute(
        builder: (_) => OverlayCameraScreen(
          ghostImagePath: ghostImagePath,
          initialVideoMode: initialVideoMode,
        ),
      ),
    );
    if (result == null) return null;
    return _saveToAppStorage(
      result.path,
      diaryId,
      dateStr,
      result.isVideo ? 'mp4' : 'jpg',
    );
  }

  static Future<String> _saveToAppStorage(
    String sourcePath,
    int diaryId,
    String dateStr,
    String extension,
  ) async {
    final dir = await getApplicationSupportDirectory();
    final diaryDir = Directory('${dir.path}/diary');
    await diaryDir.create(recursive: true);
    final destPath =
        '${diaryDir.path}/diary_${diaryId}_${dateStr}_${DateTime.now().millisecondsSinceEpoch}.$extension';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  static String formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}'
      '-${date.month.toString().padLeft(2, '0')}'
      '-${date.day.toString().padLeft(2, '0')}';
}
