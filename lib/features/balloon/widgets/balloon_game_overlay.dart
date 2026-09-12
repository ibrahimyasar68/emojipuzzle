import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../models/balloon.dart';
import '../providers/balloon_game_controller.dart';
import 'balloon_layout.dart';
import 'balloon_painter.dart';

/// The balloon mini game (§24): a short, pressure-free reward between one
/// puzzle and the next.
///
/// The feature knows nothing about puzzles (§36). It is handed the two
/// services it needs and a way to say it is done; everything else — how
/// many balloons, how fast they come, when it ends — lives in
/// [BalloonGameController], and this widget only draws it.
///
/// Nothing here can be lost. Balloons still in the air when the clock runs
/// out are left alone: no message, no sound, no face (§20).
class BalloonGameOverlay extends StatefulWidget {
  const BalloonGameOverlay({
    super.key,
    required this.onFinished,
    this.audio,
    this.haptics = const HapticService(),
    this.controller,
  });

  /// Called once, when the game is over.
  final VoidCallback onFinished;

  /// The one place that makes a sound (§27). Silent when absent.
  final AudioService? audio;

  final HapticService? haptics;

  /// Injected by tests that want to pin the balloons; otherwise the widget
  /// makes its own.
  final BalloonGameController? controller;

  @override
  State<BalloonGameOverlay> createState() => _BalloonGameOverlayState();
}

class _BalloonGameOverlayState extends State<BalloonGameOverlay>
    with SingleTickerProviderStateMixin {
  late final BalloonGameController _game;
  late final bool _ownsGame;

  /// The drawing clock. The game keeps its own clock for the rules; this
  /// one runs at frame rate so the balloons drift and bob smoothly.
  late final AnimationController _clock;

  final List<_Burst> _bursts = [];
  bool _handedBack = false;

  Duration get _elapsed => _clock.duration! * _clock.value;

  @override
  void initState() {
    super.initState();
    _ownsGame = widget.controller == null;
    _game = widget.controller ?? BalloonGameController();
    _game
      ..onFinished = _handBack
      ..addListener(_onGameChanged);

    _clock = AnimationController(vsync: this, duration: _game.timeLimit)
      ..forward();

    _game.start();
  }

  void _onGameChanged() {
    if (mounted) setState(() {});
  }

  void _handBack() {
    if (_handedBack) return;
    _handedBack = true;
    widget.onFinished();
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.onFinished = null;
    if (_ownsGame) _game.dispose();
    _clock.dispose();
    super.dispose();
  }

  void _pop(Balloon balloon, Size playArea) {
    final rect = BalloonLayout.rectOf(balloon, playArea, _elapsed);
    setState(() {
      _bursts.add(
        _Burst(
          balloon: balloon,
          centre: rect.center,
          radius: rect.width / 2,
          startedAt: _elapsed,
        ),
      );
    });

    // Animation, then sound, then the particles — and the haptic last,
    // because it is the one voice the game can do without (§27).
    widget.audio?.playBalloonPop();
    widget.haptics?.light();
    _game.pop(balloon.id);
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final playArea = constraints.biggest;
          return AnimatedBuilder(
            animation: _clock,
            builder: (context, _) {
              final elapsed = _elapsed;
              _bursts.removeWhere(
                (burst) =>
                    elapsed - burst.startedAt >=
                    PuzzleConfig.balloonPopDuration,
              );

              return Stack(
                key: const ValueKey('balloon-game'),
                children: [
                  // A tap that misses a balloon does nothing at all, but it
                  // must not reach the puzzle underneath.
                  Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {},
                    ),
                  ),
                  for (final burst in _bursts)
                    ..._burstWidgets(burst, playArea, elapsed),
                  for (final balloon in _game.balloons)
                    _balloonWidget(balloon, playArea, elapsed),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _balloonWidget(Balloon balloon, Size playArea, Duration elapsed) {
    final rect = BalloonLayout.rectOf(balloon, playArea, elapsed);
    final diameter = BalloonLayout.diameterOf(balloon, playArea);
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: diameter,
      height: diameter,
      child: GestureDetector(
        key: ValueKey('balloon-${balloon.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () => _pop(balloon, playArea),
        child: Opacity(
          // Fading in, but tappable from the first frame: a balloon a
          // child can see is a balloon a child may reach for (§2).
          opacity: BalloonLayout.opacityOf(balloon, elapsed),
          child: CustomPaint(
            painter: BalloonPainter(
              colour:
                  balloonColours[balloon.colourIndex % balloonColours.length],
            ),
            size: Size.square(diameter),
          ),
        ),
      ),
    );
  }

  /// The balloon swells and fades while its pieces fly apart (§24).
  List<Widget> _burstWidgets(_Burst burst, Size playArea, Duration elapsed) {
    final progress = ((elapsed - burst.startedAt).inMilliseconds /
            PuzzleConfig.balloonPopDuration.inMilliseconds)
        .clamp(0.0, 1.0);
    final colour =
        balloonColours[burst.balloon.colourIndex % balloonColours.length];
    final swell = 1 +
        (PuzzleConfig.balloonPopScale - 1) * (progress * 2.5).clamp(0.0, 1.0);

    return [
      Positioned.fromRect(
        rect: Rect.fromCircle(center: burst.centre, radius: burst.radius),
        child: IgnorePointer(
          child: Opacity(
            opacity: (1 - progress).clamp(0.0, 1.0),
            child: CustomPaint(
              painter: BalloonPainter(colour: colour, scale: swell),
              size: Size.square(burst.radius * 2),
            ),
          ),
        ),
      ),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: BalloonBurstPainter(
              centre: burst.centre,
              colour: colour,
              radius: burst.radius,
              progress: progress,
            ),
            size: playArea,
          ),
        ),
      ),
    ];
  }
}

/// A balloon in the moment after it was touched.
class _Burst {
  const _Burst({
    required this.balloon,
    required this.centre,
    required this.radius,
    required this.startedAt,
  });

  final Balloon balloon;

  /// Frozen where it was popped: the pieces do not drift on with the bob.
  final Offset centre;
  final double radius;
  final Duration startedAt;
}
