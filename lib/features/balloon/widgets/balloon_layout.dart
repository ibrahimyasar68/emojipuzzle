import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import '../../../core/constants/puzzle_config.dart';
import '../models/balloon.dart';

/// Where a balloon is, in pixels, at a given moment (§24).
///
/// Pure functions, kept out of the widget so the 72 px rule and the drift
/// upward can be checked directly.
abstract final class BalloonLayout {
  /// A balloon is always at least [PuzzleConfig.balloonTouchTargetSize]
  /// across (§2), and grows with the screen so it stays easy to hit on a
  /// tablet.
  static double diameterFor(Size playArea) => math.max(
        PuzzleConfig.balloonTouchTargetSize,
        playArea.shortestSide * 0.18,
      );

  /// The square a balloon occupies, including its size variation.
  ///
  /// [elapsed] is time since the game opened; the balloon drifts up from
  /// below the bottom edge to its resting height, then bobs on the spot.
  /// How big this particular balloon is.
  ///
  /// The floor is applied after the size variation, not before it: a
  /// balloon 10% smaller than its neighbours is still a balloon a
  /// three-year-old has to be able to hit (§2).
  ///
  /// Widgets take their width and height from here rather than from
  /// [rectOf], because a rectangle's width is its right edge minus its
  /// left, and those two do not always subtract back to exactly 72.
  static double diameterOf(Balloon balloon, Size playArea) => math.max(
        PuzzleConfig.balloonTouchTargetSize,
        diameterFor(playArea) * balloon.sizeFactor,
      );

  static Rect rectOf(Balloon balloon, Size playArea, Duration elapsed) {
    final diameter = diameterOf(balloon, playArea);
    final age = elapsed - balloon.bornAt;

    final rise =
        (age.inMilliseconds / PuzzleConfig.balloonRiseDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    // Slow down as it arrives, the way something buoyant does.
    final eased = 1 - math.pow(1 - rise, 3).toDouble();

    final restTop = balloon.restY * math.max(0, playArea.height - diameter);
    final top =
        restTop + diameter * PuzzleConfig.balloonRiseDistance * (1 - eased);

    final bob = rise < 1
        ? 0.0
        : math.sin(
              (age.inMilliseconds /
                          PuzzleConfig.balloonBobPeriod.inMilliseconds +
                      balloon.bobPhase) *
                  2 *
                  math.pi,
            ) *
            PuzzleConfig.balloonBobAmplitude;

    final left = balloon.x * math.max(0, playArea.width - diameter);
    return Rect.fromLTWH(left, top + bob, diameter, diameter);
  }

  /// How solid a balloon is: it fades in over its drift up, so it arrives
  /// rather than appearing.
  static double opacityOf(Balloon balloon, Duration elapsed) {
    final age = elapsed - balloon.bornAt;
    return (age.inMilliseconds /
            (PuzzleConfig.balloonRiseDuration.inMilliseconds * 0.6))
        .clamp(0.0, 1.0);
  }

  /// Middle of a balloon: where its burst comes from.
  static Offset centreOf(Balloon balloon, Size playArea, Duration elapsed) =>
      rectOf(balloon, playArea, elapsed).center;
}
