import 'dart:math' as math;
import 'dart:ui' as ui;

/// An opaque 1:1 picture painted in code, for tests that need to see the
/// pixels.
///
/// The real artwork is transparent (§34), which is exactly wrong for the
/// seam check: a transparent pixel in the finished board has to mean "the
/// pieces left a gap", not "the emoji has nothing there". The diagonal
/// stripes make a misplaced piece or a wrong src/dst mapping obvious, in a
/// bitmap comparison and to the eye.
abstract final class TestArtwork {
  static const _background = ui.Color(0xFFFFF1D6);
  static const _stripe = ui.Color(0xFFFFD8A8);
  static const _outerCircle = ui.Color(0xFFFF8A5B);
  static const _innerCircle = ui.Color(0xFFFFC43D);
  static const _dot = ui.Color(0xFF4DB6AC);

  static Future<ui.Image> create({int size = 512}) async {
    final edge = size.toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder, ui.Rect.fromLTWH(0, 0, edge, edge));

    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, edge, edge),
      ui.Paint()..color = _background,
    );

    canvas.save();
    canvas.translate(edge / 2, edge / 2);
    canvas.rotate(math.pi / 6);
    final stripePaint = ui.Paint()..color = _stripe;
    final stripeWidth = edge / 14;
    for (var x = -edge; x < edge; x += stripeWidth * 2) {
      canvas.drawRect(
        ui.Rect.fromLTWH(x, -edge, stripeWidth, edge * 2),
        stripePaint,
      );
    }
    canvas.restore();

    final centre = ui.Offset(edge / 2, edge / 2);
    canvas
      ..drawCircle(centre, edge * 0.32, ui.Paint()..color = _outerCircle)
      ..drawCircle(centre, edge * 0.18, ui.Paint()..color = _innerCircle);

    final dotPaint = ui.Paint()..color = _dot;
    const dotCentres = [
      ui.Offset(0.18, 0.18),
      ui.Offset(0.82, 0.18),
      ui.Offset(0.18, 0.82),
      ui.Offset(0.82, 0.82),
    ];
    for (final dot in dotCentres) {
      canvas.drawCircle(
        ui.Offset(dot.dx * edge, dot.dy * edge),
        edge * 0.06,
        dotPaint,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(size, size);
    picture.dispose();
    return image;
  }
}
