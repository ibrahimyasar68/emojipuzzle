import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';

/// The balloon palette. Bright, friendly, and far away from the red the
/// game never uses for anything (§2, §20).
const List<Color> balloonColours = [
  Color(0xFFFF8A5B),
  Color(0xFFFFC43D),
  Color(0xFF4DB6AC),
  Color(0xFF9CCC65),
  Color(0xFFAB47BC),
];

/// One balloon: a body, a highlight and a short string.
class BalloonPainter extends CustomPainter {
  const BalloonPainter({required this.colour, this.scale = 1});

  final Color colour;

  /// The swell just before it bursts.
  final double scale;

  @override
  void paint(Canvas canvas, Size size) {
    final centre = Offset(size.width / 2, size.height / 2);
    canvas.save();
    canvas.translate(centre.dx, centre.dy);
    canvas.scale(scale);
    canvas.translate(-centre.dx, -centre.dy);

    final body = Rect.fromCenter(
      center: Offset(centre.dx, size.height * 0.42),
      width: size.width * 0.78,
      height: size.height * 0.92,
    );

    // The string, drawn first so the balloon sits over it.
    final string = Path()
      ..moveTo(centre.dx, body.bottom - size.height * 0.02)
      ..quadraticBezierTo(
        centre.dx + size.width * 0.10,
        size.height * 0.90,
        centre.dx,
        size.height,
      );
    canvas.drawPath(
      string,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.2, size.width * 0.02)
        ..color = const Color(0x66000000),
    );

    canvas.drawOval(body, Paint()..color = colour);

    // The knot.
    canvas.drawCircle(
      Offset(centre.dx, body.bottom),
      size.width * 0.05,
      Paint()..color = colour,
    );

    // A soft highlight, so it reads as round rather than as a flat disc.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(
            body.left + body.width * 0.32, body.top + body.height * 0.28),
        width: body.width * 0.26,
        height: body.height * 0.20,
      ),
      Paint()..color = const Color(0x59FFFFFF),
    );

    canvas.restore();
  }

  @override
  bool shouldRepaint(BalloonPainter oldDelegate) =>
      oldDelegate.colour != colour || oldDelegate.scale != scale;
}

/// What is left of a balloon for a fraction of a second after it pops:
/// a ring opening out, and a handful of pieces flying apart (§24, §42).
class BalloonBurstPainter extends CustomPainter {
  const BalloonBurstPainter({
    required this.centre,
    required this.colour,
    required this.radius,
    required this.progress,
  });

  final Offset centre;
  final Color colour;

  /// Radius of the balloon that burst, so the pieces start at its edge.
  final double radius;

  /// 0 at the pop, 1 when nothing is left.
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final fade = 1 - progress;

    canvas.drawCircle(
      centre,
      radius * (0.6 + progress * 0.9),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = math.max(1.5, radius * 0.12 * fade)
        ..color = colour.withValues(alpha: 0.5 * fade),
    );

    final pieceRadius = math.max(1.5, radius * 0.13 * fade);
    for (var i = 0; i < PuzzleConfig.balloonPopParticles; i++) {
      final angle = i * 2 * math.pi / PuzzleConfig.balloonPopParticles;
      final distance = radius * (0.5 + progress * 1.1);
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * distance,
        pieceRadius,
        Paint()..color = colour.withValues(alpha: fade),
      );
    }
  }

  @override
  bool shouldRepaint(BalloonBurstPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.centre != centre;
}
