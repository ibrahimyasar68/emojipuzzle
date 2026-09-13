import 'dart:math' as math;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';

/// Balon paleti. Canlı, sıcak ve oyunun hiçbir şey için kullanmadığı
/// kırmızıdan uzak (§2, §20).
const List<Color> balloonColours = [
  Color(0xFFFF8A5B),
  Color(0xFFFFC43D),
  Color(0xFF4DB6AC),
  Color(0xFF9CCC65),
  Color(0xFFAB47BC),
];

/// Tek bir balon: bir gövde, bir parlama ve kısa bir ip.
class BalloonPainter extends CustomPainter {
  const BalloonPainter({
    required this.colour,
    required this.stringColour,
    this.scale = 1,
  });

  final Color colour;

  /// İpin rengi; temaya bağlıdır, çünkü ip zeminin üstünde durur (§24).
  final Color stringColour;

  /// Patlamadan hemen önceki şişme.
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

    // İp, önce çizilir ki balon onun üstüne otursun.
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
        ..color = stringColour,
    );

    canvas.drawOval(body, Paint()..color = colour);

    // Düğüm.
    canvas.drawCircle(
      Offset(centre.dx, body.bottom),
      size.width * 0.05,
      Paint()..color = colour,
    );

    // Yumuşak bir parlama; böylece düz bir daire değil, yuvarlak okunur.
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
      oldDelegate.colour != colour ||
      oldDelegate.stringColour != stringColour ||
      oldDelegate.scale != scale;
}

/// Patladıktan sonra saniyenin bir kesri boyunca balondan geriye kalan:
/// açılan bir halka ve dağılan bir avuç parça (§24, §42).
class BalloonBurstPainter extends CustomPainter {
  const BalloonBurstPainter({
    required this.centre,
    required this.colour,
    required this.radius,
    required this.progress,
  });

  final Offset centre;
  final Color colour;

  /// Patlayan balonun yarıçapı; parçalar onun kenarından başlar.
  final double radius;

  /// Patlama anında 0, geriye hiçbir şey kalmadığında 1.
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
