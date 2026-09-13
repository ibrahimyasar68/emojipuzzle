import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/placement_burst.dart';

/// "Evet, o" diyen parıltılar (§22).
///
/// Her şeyin üstünde durur ve hiçbir dokunuşu almaz: geri bildirim asla
/// çocuk ile sonraki parça arasına girmemelidir. Ayrıca tamamen eklemedir
/// — bu katman kaldırıldığında oyun tıpatıp aynı oynanır ve onu bilgi
/// değil *geri bildirim* olarak dürüst tutan da budur.
class FeedbackLayer extends StatefulWidget {
  const FeedbackLayer({super.key, required this.burst});

  final ValueListenable<PlacementBurst?> burst;

  @override
  State<FeedbackLayer> createState() => _FeedbackLayerState();
}

class _FeedbackLayerState extends State<FeedbackLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  int? _playingBurstId;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PuzzleConfig.placementFeedbackDuration,
    );
    widget.burst.addListener(_onBurst);
  }

  @override
  void didUpdateWidget(FeedbackLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.burst, widget.burst)) {
      oldWidget.burst.removeListener(_onBurst);
      widget.burst.addListener(_onBurst);
    }
  }

  void _onBurst() {
    final burst = widget.burst.value;
    if (burst == null || burst.id == _playingBurstId) return;
    _playingBurstId = burst.id;
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    widget.burst.removeListener(_onBurst);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<PlacementBurst?>(
          valueListenable: widget.burst,
          builder: (context, burst, _) {
            if (burst == null) return const SizedBox.shrink();
            return AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                // Başlamadan önce hiçbir şey, bittikten sonra da hiçbir
                // şey — biten bir gösteri arkasında widget bırakmamalıdır.
                // Değerine değil, çalışıp çalışmadığına bakılır: bir
                // patlamanın ilk karesi 0'dadır ve yine de çizilmelidir.
                if (_controller.isCompleted ||
                    (_controller.isDismissed && !_controller.isAnimating)) {
                  return const SizedBox.shrink();
                }
                return CustomPaint(
                  painter: _SparklePainter(
                    centre: burst.centre,
                    progress: _controller.value,
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter({required this.centre, required this.progress});

  final Offset centre;
  final double progress;

  // Kanal kanal yazılır ki boyayıcı, yalnızca Flutter 3.27'den itibaren
  // var olan Color.r/g/b erişimcilerine bağlı olmasın (§0 3.24'e izin
  // veriyor).
  static const _red = 255;
  static const _green = 196;
  static const _blue = 61;
  static const _innerRadius = 10.0;
  static const _outerRadius = 48.0;
  static const _sparkleRadius = 5.0;

  @override
  void paint(Canvas canvas, Size size) {
    final eased = Curves.easeOut.transform(progress);
    final distance = _innerRadius + (_outerRadius - _innerRadius) * eased;
    final radius = _sparkleRadius * (1 - eased);
    if (radius <= 0) return;

    final paint = Paint()
      ..color = Color.fromRGBO(_red, _green, _blue, 1 - eased)
      ..isAntiAlias = true;

    for (var i = 0; i < PuzzleConfig.sparkleCount; i++) {
      final angle = 2 * math.pi * i / PuzzleConfig.sparkleCount;
      canvas.drawCircle(
        centre + Offset(math.cos(angle), math.sin(angle)) * distance,
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_SparklePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.centre != centre;
}
