import 'dart:math' as math;

import 'package:flutter/foundation.dart' show ValueListenable;
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/placement_burst.dart';

/// The sparkles that say "yes, that one" (§22).
///
/// It sits above everything and takes no touches: the feedback must never
/// stand between a child and the next piece. It is also purely additive —
/// the game is exactly as playable with this layer removed, which is what
/// keeps it honest as *feedback* rather than information.
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
                // Nothing before it starts, and nothing once it is over — a
                // finished flourish must leave no widget behind. Judged by
                // whether it is running, not by its value: the very first
                // frame of a burst sits at 0 and still has to be drawn.
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

  // Written channel by channel so the painter does not depend on the
  // Color.r/g/b accessors, which only exist from Flutter 3.27 (§0 allows
  // 3.24).
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
