import 'dart:ui' as ui;
import 'dart:io';

String formatMegapixels(int? width, int? height) {
  if (width == null || height == null) return '— MP';
  final mp = (width * height) / 1000000;
  return '${mp.toStringAsFixed(1).replaceAll('.', ',')} MP';
}

Future<({int width, int height})?> readImageDimensions(String path) async {
  try {
    final bytes = await File(path).readAsBytes();
    final codec = await ui.instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final dims = (width: image.width, height: image.height);
    image.dispose();
    codec.dispose();
    return dims;
  } catch (e) {
    return null;
  }
}
