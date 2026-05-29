import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

class DiaryCameraService {
  static final _picker = ImagePicker();

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
