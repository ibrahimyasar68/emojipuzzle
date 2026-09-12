import 'dart:async';

import 'package:confetti/confetti.dart';
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';

/// The moment after the last piece: a ring opening out over the finished
/// picture, and confetti (§23).
///
/// It sits above the board so the picture the child just made stays in
/// view — the celebration is about that picture, not a screen that replaces
/// it.
///
/// A tap anywhere ends it at once. That is the whole point of §23: the
/// flourish is a gift, and a gift a child cannot decline is a delay.
class CelebrationOverlay extends StatefulWidget {
  const CelebrationOverlay({
    super.key,
    required this.onFinished,
    this.origin,
    this.duration = PuzzleConfig.celebrationDuration,
  });

  /// Called once, when the celebration is over or the child skips it.
  final VoidCallback onFinished;

  /// Middle of the finished board, where the ring opens from.
  final Offset? origin;

  final Duration duration;

  @override
  State<CelebrationOverlay> createState() => _CelebrationOverlayState();
}

class _CelebrationOverlayState extends State<CelebrationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring;
  late final ConfettiController _confetti;
  Timer? _end;
  bool _finished = false;

  @override
  void initState() {
    super.initState();
    _ring = AnimationController(
      vsync: this,
      duration: PuzzleConfig.completionAnimationDuration,
    )..forward();
    _confetti = ConfettiController(duration: widget.duration)..play();

    // The sequence ends on its own; a tap gets there sooner.
    _end = Timer(widget.duration, _finish);
  }

  void _finish() {
    if (_finished || !mounted) return;
    _finished = true;
    _end?.cancel();
    _end = null;
    _confetti.stop();
    widget.onFinished();
  }

  @override
  void dispose() {
    _end?.cancel();
    _ring.dispose();
    _confetti.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        key: const ValueKey('celebration-overlay'),
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Stack(
          alignment: Alignment.topCenter,
          children: [
            if (widget.origin != null)
              AnimatedBuilder(
                animation: _ring,
                builder: (context, _) => CustomPaint(
                  painter: _CompletionRingPainter(
                    centre: widget.origin!,
                    progress: _ring.value,
                  ),
                  size: Size.infinite,
                ),
              ),
            // Given the whole screen to fly in: a confetti widget squeezed
            // into a small box clips its own particles.
            Positioned.fill(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConfettiWidget(
                  confettiController: _confetti,
                  blastDirectionality: BlastDirectionality.explosive,
                  emissionFrequency: 0.12,
                  numberOfParticles: PuzzleConfig.confettiParticles,
                  maxBlastForce: 18,
                  minBlastForce: 8,
                  gravity: 0.3,
                  colors: const [
                    Color(0xFFFF8A5B),
                    Color(0xFFFFC43D),
                    Color(0xFF4DB6AC),
                    Color(0xFF9CCC65),
                    Color(0xFFAB47BC),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A ring opening out from the finished picture: "look what you made".
class _CompletionRingPainter extends CustomPainter {
  const _CompletionRingPainter({required this.centre, required this.progress});

  final Offset centre;
  final double progress;

  static const _red = 255;
  static const _green = 196;
  static const _blue = 61;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final eased = Curves.easeOut.transform(progress);

    canvas.drawCircle(
      centre,
      40 + eased * (size.longestSide * 0.5),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 10 * (1 - eased)
        ..color = Color.fromRGBO(_red, _green, _blue, 0.55 * (1 - eased))
        ..isAntiAlias = true,
    );
  }

  @override
  bool shouldRepaint(_CompletionRingPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.centre != centre;
}
