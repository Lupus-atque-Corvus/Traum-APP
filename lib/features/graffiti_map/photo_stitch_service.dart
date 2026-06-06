/// Panorama-Stitching.
///
/// Experimentell. In diesem Build ist das native OpenCV-Backend
/// (`opencv_dart`) bewusst nicht eingebunden, um die APK schlank und den
/// Release-Build stabil zu halten. Die UI bleibt vorhanden; das eigentliche
/// Zusammenfügen meldet, dass es derzeit nicht verfügbar ist.
class PhotoStitchService {
  /// Ob echtes Stitching in diesem Build verfügbar ist.
  static const bool isAvailable = false;

  /// Versucht, mehrere überlappende Fotos zu einem Panorama zu fügen.
  /// Gibt den Pfad zum Ergebnis zurück oder `null`, wenn nicht möglich /
  /// nicht verfügbar.
  static Future<String?> stitchPhotos(List<String> paths) async {
    // Kein OpenCV in diesem Build → graceful degrade.
    return null;
  }
}
