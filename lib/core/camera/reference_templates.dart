import 'dart:io';
import 'package:flutter/material.dart';

/// Welche Ausrichtungs-Referenz aktuell über der Live-Kamera liegt.
enum ReferenceOverlayMode { off, lastPhoto, bodyFull, faceSingle, facesTwo, food }

/// Icon für den Auswahl-Streifen (nicht die Vorlage selbst — die wird als
/// Vektor-Linienzeichnung über [ReferenceOverlayLayer] gerendert).
IconData referenceOverlayModeIcon(ReferenceOverlayMode m) => switch (m) {
      ReferenceOverlayMode.off => Icons.block,
      ReferenceOverlayMode.lastPhoto => Icons.image_outlined,
      ReferenceOverlayMode.bodyFull => Icons.accessibility_new,
      ReferenceOverlayMode.faceSingle => Icons.face_outlined,
      ReferenceOverlayMode.facesTwo => Icons.people_outline,
      ReferenceOverlayMode.food => Icons.restaurant_outlined,
    };

/// Rendert die aktuell gewählte Referenz über der Kamera-Vorschau:
/// entweder das Geist-Foto (halbtransparent) oder eine der festen
/// Umriss-Vorlagen (dünne weiße Linienzeichnung, per [CustomPainter]
/// gezeichnet statt als Rasterbild/Emoji — bleibt in jeder Auflösung
/// scharf).
class ReferenceOverlayLayer extends StatelessWidget {
  final ReferenceOverlayMode mode;
  final String? ghostImagePath;

  const ReferenceOverlayLayer(
      {super.key, required this.mode, required this.ghostImagePath});

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
          opacity: 0.35,
          child: Image.file(File(path), fit: BoxFit.cover),
        ),
      );
    }

    final painter = switch (mode) {
      ReferenceOverlayMode.bodyFull => _BodyOutlinePainter(),
      ReferenceOverlayMode.faceSingle => _FaceOutlinePainter(),
      ReferenceOverlayMode.facesTwo => _TwoFacesOutlinePainter(),
      ReferenceOverlayMode.food => _FoodOutlinePainter(),
      _ => null,
    };
    if (painter == null) return const SizedBox.shrink();
    return Positioned.fill(
      child: IgnorePointer(
        child: Opacity(opacity: 0.55, child: CustomPaint(painter: painter)),
      ),
    );
  }
}

Paint _guidePaint() => Paint()
  ..color = Colors.white
  ..style = PaintingStyle.stroke
  ..strokeWidth = 1.8
  ..strokeCap = StrokeCap.round
  ..strokeJoin = StrokeJoin.round;

/// Baut aus Bruchteils-Koordinaten (0..1 relativ zu [size]) einen
/// geschlossenen Umriss-Pfad für eine stehende Person, gespiegelt an der
/// vertikalen Mittelachse `cx`. `right` beschreibt nur die rechte Kontur
/// von Hals bis Schritt — die linke Seite wird automatisch gespiegelt.
Path _mirroredBodyPath(
    Size size, double cx, List<Offset> right, Offset crotch) {
  Offset toCanvas(Offset f) => Offset(cx + f.dx * size.width, f.dy * size.height);

  final points = <Offset>[
    ...right,
    crotch,
    ...right.reversed.map((p) => Offset(-p.dx, p.dy)),
  ];
  final path = Path()..moveTo(toCanvas(points.first).dx, toCanvas(points.first).dy);
  for (final p in points.skip(1)) {
    final c = toCanvas(p);
    path.lineTo(c.dx, c.dy);
  }
  path.close();
  return path;
}

/// Ganzkörper-Silhouette (eine Person, frontal) — Referenz für
/// Ganzkörper-Fortschrittsfotos.
class _BodyOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final paint = _guidePaint();

    canvas.drawCircle(Offset(cx, size.height * 0.085), size.height * 0.05, paint);

    final right = <Offset>[
      const Offset(0.045, 0.145),
      const Offset(0.17, 0.175),
      const Offset(0.185, 0.30),
      const Offset(0.10, 0.42),
      const Offset(0.145, 0.47),
      const Offset(0.13, 0.65),
      const Offset(0.10, 0.90),
      const Offset(0.13, 0.955),
      const Offset(0.03, 0.965),
      const Offset(0.035, 0.90),
      const Offset(0.035, 0.65),
    ];
    final path = _mirroredBodyPath(size, cx, right, const Offset(0.0, 0.47));
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Zeichnet einen Kopf-/Gesichts-Umriss (Haaransatz + Ohren) mittig in
/// [rect], skaliert relativ zur Rect-Höhe.
void _paintFaceOutline(Canvas canvas, Paint paint, Rect rect) {
  final cx = rect.center.dx;
  final h = rect.height;
  Offset p(double dx, double dy) => Offset(cx + dx * h, rect.top + dy * h);

  final path = Path()
    ..moveTo(p(0, 0.72).dx, p(0, 0.72).dy) // Kinn
    ..lineTo(p(0.20, 0.66).dx, p(0.20, 0.66).dy)
    ..lineTo(p(0.26, 0.50).dx, p(0.26, 0.50).dy) // Ohr rechts außen
    ..lineTo(p(0.23, 0.42).dx, p(0.23, 0.42).dy)
    ..lineTo(p(0.27, 0.20).dx, p(0.27, 0.20).dy) // Schläfe rechts
    ..lineTo(p(0.14, 0.06).dx, p(0.14, 0.06).dy) // Haaransatz rechts
    ..lineTo(p(-0.14, 0.06).dx, p(-0.14, 0.06).dy) // Haaransatz links
    ..lineTo(p(-0.27, 0.20).dx, p(-0.27, 0.20).dy)
    ..lineTo(p(-0.23, 0.42).dx, p(-0.23, 0.42).dy)
    ..lineTo(p(-0.26, 0.50).dx, p(-0.26, 0.50).dy) // Ohr links außen
    ..lineTo(p(-0.20, 0.66).dx, p(-0.20, 0.66).dy)
    ..close();
  canvas.drawPath(path, paint);
}

/// Ein einzelnes Gesicht (frontal), zentriert.
class _FaceOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final h = size.height * 0.62;
    final rect = Rect.fromCenter(
        center: Offset(size.width / 2, size.height * 0.42), width: h, height: h);
    _paintFaceOutline(canvas, _guidePaint(), rect);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Zwei Gesichter nebeneinander — eins mit offenem Haaransatz, eins mit
/// Dutt, damit sich zwei Personen im Bild unterscheiden lassen.
class _TwoFacesOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint();
    final h = size.height * 0.42;
    final cy = size.height * 0.42;
    final leftCx = size.width * 0.30;
    final rightCx = size.width * 0.70;

    _paintFaceOutline(
        canvas, paint, Rect.fromCenter(center: Offset(leftCx, cy), width: h, height: h));
    _paintFaceOutline(canvas, paint,
        Rect.fromCenter(center: Offset(rightCx, cy), width: h, height: h));

    // Dutt auf dem zweiten Kopf, damit die beiden Vorlagen unterscheidbar
    // bleiben (nicht einfach zwei identische Kopien).
    final bunCenter = Offset(rightCx, cy - h * 0.42);
    canvas.drawCircle(bunCenter, h * 0.09, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Teller mit Gabel und Messer — Referenz für Essens-/Mahlzeitfotos.
class _FoodOutlinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = _guidePaint();
    final cx = size.width / 2;
    final cy = size.height * 0.42;
    final plateR = size.width * 0.26;

    canvas.drawCircle(Offset(cx, cy), plateR, paint);
    canvas.drawCircle(Offset(cx, cy), plateR * 0.72, paint);

    // Gabel links: 4 Zinken + Griff.
    final forkX = cx - plateR * 1.55;
    final tineTop = cy - plateR * 0.95;
    final tineBottom = cy - plateR * 0.55;
    for (var i = -1; i <= 2; i++) {
      final x = forkX + i * plateR * 0.09;
      canvas.drawLine(Offset(x, tineTop), Offset(x, tineBottom), paint);
    }
    canvas.drawLine(
        Offset(forkX - plateR * 0.135, tineBottom),
        Offset(forkX + plateR * 0.135, tineBottom),
        paint);
    canvas.drawLine(Offset(forkX, tineBottom), Offset(forkX, cy + plateR * 1.0), paint);

    // Messer rechts: Klinge (Pfad) + Griff.
    final knifeX = cx + plateR * 1.55;
    final bladeTop = cy - plateR * 0.98;
    final bladeMid = cy - plateR * 0.35;
    final knifePath = Path()
      ..moveTo(knifeX - plateR * 0.05, bladeTop)
      ..quadraticBezierTo(
          knifeX + plateR * 0.16, cy - plateR * 0.7, knifeX + plateR * 0.06, bladeMid)
      ..lineTo(knifeX - plateR * 0.05, bladeMid)
      ..lineTo(knifeX - plateR * 0.05, bladeTop);
    canvas.drawPath(knifePath, paint);
    canvas.drawLine(
        Offset(knifeX - plateR * 0.02, bladeMid),
        Offset(knifeX - plateR * 0.02, cy + plateR * 1.0),
        paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
