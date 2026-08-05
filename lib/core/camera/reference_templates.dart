import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Welche Ausrichtungs-Referenz aktuell über der Live-Kamera liegt.
enum ReferenceOverlayMode { off, lastPhoto, bodyFull, faceSingle, facesTwo, food }

/// Icon für den Auswahl-Streifen (nicht die Vorlage selbst — die wird als
/// SVG-Vektor über [ReferenceOverlayLayer] gerendert).
IconData referenceOverlayModeIcon(ReferenceOverlayMode m) => switch (m) {
      ReferenceOverlayMode.off => Icons.block,
      ReferenceOverlayMode.lastPhoto => Icons.image_outlined,
      ReferenceOverlayMode.bodyFull => Icons.accessibility_new,
      ReferenceOverlayMode.faceSingle => Icons.face_outlined,
      ReferenceOverlayMode.facesTwo => Icons.people_outline,
      ReferenceOverlayMode.food => Icons.restaurant_outlined,
    };

/// Asset-Pfad der festen Vorlage (`null` bei `off`/`lastPhoto`, die keine
/// eigene SVG-Datei haben).
String? _templateAsset(ReferenceOverlayMode m) => switch (m) {
      ReferenceOverlayMode.bodyFull => 'assets/reference_templates/body_full.svg',
      ReferenceOverlayMode.faceSingle => 'assets/reference_templates/face_single.svg',
      ReferenceOverlayMode.facesTwo => 'assets/reference_templates/faces_two.svg',
      ReferenceOverlayMode.food => 'assets/reference_templates/food.svg',
      _ => null,
    };

/// Rendert die aktuell gewählte Referenz über der Kamera-Vorschau: entweder
/// das Geist-Foto oder eine der festen Umriss-Vorlagen (SVG-Assets, weiß
/// eingefärbt über [ColorFilter] — die Quelldateien selbst sind unverändert
/// wie vom Nutzer geliefert). [opacity] ist einstellbar (Slider im
/// Kamera-Screen), nicht mehr fest verdrahtet.
class ReferenceOverlayLayer extends StatelessWidget {
  final ReferenceOverlayMode mode;
  final String? ghostImagePath;
  final double opacity;

  const ReferenceOverlayLayer({
    super.key,
    required this.mode,
    required this.ghostImagePath,
    required this.opacity,
  });

  @override
  Widget build(BuildContext context) {
    if (mode == ReferenceOverlayMode.off) return const SizedBox.shrink();

    if (mode == ReferenceOverlayMode.lastPhoto) {
      final path = ghostImagePath;
      if (path == null || !File(path).existsSync()) {
        return const SizedBox.shrink();
      }
      return Positioned.fill(
        child: Opacity(
          opacity: opacity,
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
      );
    }

    final asset = _templateAsset(mode);
    if (asset == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(
          opacity: opacity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: SvgPicture.asset(
              asset,
              fit: BoxFit.contain,
              colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
            ),
          ),
        ),
      ),
    );
  }
}
