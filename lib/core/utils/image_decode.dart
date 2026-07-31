import 'package:flutter/widgets.dart';

/// Zielbreite/-höhe (in echten Gerätepixeln) für die Dekodierung eines Bildes,
/// das mit [logicalSize] logischen Pixeln angezeigt wird.
///
/// Warum das nötig ist: `Image.file` dekodiert eine Datei ohne `cacheWidth`/
/// `cacheHeight` **immer in voller Originalauflösung**. Ein 12-MP-Handyfoto
/// (4032×3024) belegt dekodiert rund 48 MB im Bild-Cache — auch wenn es als
/// 64-Pixel-Thumbnail dargestellt wird. Flutters Bild-Cache ist standardmäßig
/// auf 100 MB begrenzt, ein Foto-Raster verdrängt sich damit permanent selbst
/// und dekodiert dieselben Bilder beim Scrollen immer wieder neu.
///
/// Für Vollbild-Ansichten bewusst NICHT verwenden — dort ist die volle
/// Auflösung erwünscht.
int decodePxFor(BuildContext context, double logicalSize) =>
    (logicalSize * MediaQuery.devicePixelRatioOf(context)).round();
