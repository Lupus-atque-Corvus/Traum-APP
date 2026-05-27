import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

class ReceiptScanResult {
  final String imagePath;
  final double? detectedAmount;
  final DateTime? detectedDate;
  final String? detectedMerchant;
  final String rawText;

  const ReceiptScanResult({
    required this.imagePath,
    this.detectedAmount,
    this.detectedDate,
    this.detectedMerchant,
    required this.rawText,
  });
}

class ReceiptScanner {
  static final _recognizer = TextRecognizer(script: TextRecognitionScript.latin);

  static Future<ReceiptScanResult?> scanFromCamera() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return _processImage(picked.path);
  }

  static Future<ReceiptScanResult?> scanFromGallery() async {
    final picked = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return null;
    return _processImage(picked.path);
  }

  static Future<ReceiptScanResult> _processImage(String imagePath) async {
    final inputImage = InputImage.fromFilePath(imagePath);
    final recognized = await _recognizer.processImage(inputImage);
    final text = recognized.text;

    return ReceiptScanResult(
      imagePath: imagePath,
      detectedAmount: _extractAmount(text),
      detectedDate: _extractDate(text),
      detectedMerchant: _extractMerchant(text),
      rawText: text,
    );
  }

  static double? _extractAmount(String text) {
    final patterns = [
      RegExp(
        r'(?:gesamt|summe|total|betrag|zu zahlen)[:\s]*(\d+[,\.]\d{2})',
        caseSensitive: false,
      ),
      RegExp(r'(\d+[,\.]\d{2})\s*(?:eur|€)', caseSensitive: false),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        final amountStr = match.group(1)!.replaceAll(',', '.');
        return double.tryParse(amountStr);
      }
    }
    return null;
  }

  static DateTime? _extractDate(String text) {
    final patterns = [
      RegExp(r'(\d{2})[\.\/](\d{2})[\.\/](\d{4})'),
      RegExp(r'(\d{4})-(\d{2})-(\d{2})'),
    ];
    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        try {
          final first = int.parse(match.group(1)!);
          final second = int.parse(match.group(2)!);
          final third = int.parse(match.group(3)!);
          if (third > 2000) {
            return DateTime(third, second, first);
          } else {
            return DateTime(first, second, third);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  static String? _extractMerchant(String text) {
    final lines = text
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty && l.length > 2)
        .toList();
    return lines.isNotEmpty ? lines.first : null;
  }
}
