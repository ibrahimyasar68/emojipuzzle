import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/balloon/models/balloon.dart';
import 'package:emoji_puzzle_kids/features/balloon/providers/balloon_game_controller.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_layout.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

const _referencePhone = Size(360, 640);
const _tablet = Size(800, 1200);

Balloon _balloon({
  double x = 0.5,
  double restY = 0.4,
  double sizeFactor = 1,
  Duration bornAt = Duration.zero,
}) =>
    Balloon(
      id: 0,
      x: x,
      restY: restY,
      colourIndex: 0,
      sizeFactor: sizeFactor,
      bobPhase: 0,
      bornAt: bornAt,
    );

void main() {
  group('a balloon is big enough to hit (§2)', () {
    test('72 px on the reference phone, even at the smallest variation', () {
      // 360 × 0.18 is only 64.8, so the floor is what decides here.
      expect(BalloonLayout.diameterFor(_referencePhone), 72);
    });

    test('it grows with the screen rather than staying tiny on a tablet', () {
      expect(
        BalloonLayout.diameterFor(_tablet),
        greaterThan(BalloonLayout.diameterFor(_referencePhone)),
      );
      expect(BalloonLayout.diameterFor(_tablet), 800 * 0.18);
    });

    test('the smallest balloon still clears the 72 px target', () {
      // The phone is the case that bites: 360 × 0.18 × 0.9 is 58.3 px, so
      // the floor has to survive the size variation, not precede it.
      for (final playArea in [_referencePhone, _tablet]) {
        final rect = BalloonLayout.rectOf(
          _balloon(sizeFactor: 0.9),
          playArea,
          const Duration(seconds: 3),
        );
        expect(
          rect.width,
          greaterThanOrEqualTo(PuzzleConfig.balloonTouchTargetSize),
          reason: '$playArea',
        );
        expect(
          rect.height,
          greaterThanOrEqualTo(PuzzleConfig.balloonTouchTargetSize),
        );
      }
    });
  });

  group('drifting up (§24)', () {
    test('it fades in just below its place and drifts up into it', () {
      final balloon = _balloon();
      final atBirth =
          BalloonLayout.rectOf(balloon, _referencePhone, Duration.zero);
      final settled = BalloonLayout.rectOf(
        balloon,
        _referencePhone,
        PuzzleConfig.balloonRiseDuration,
      );

      // It arrives from below, but only from just below: a balloon that
      // flew up the whole screen would pass over the ones already there.
      expect(atBirth.top, greaterThan(settled.top));
      expect(
        atBirth.top - settled.top,
        lessThan(_referencePhone.height / BalloonGameController.rows),
      );

      // Two points during the drift, before the bob starts and can muddle
      // the comparison: it only ever moves upward.
      final early = BalloonLayout.rectOf(
        balloon,
        _referencePhone,
        const Duration(milliseconds: 200),
      );
      final late_ = BalloonLayout.rectOf(
        balloon,
        _referencePhone,
        const Duration(milliseconds: 800),
      );
      expect(early.top, lessThan(atBirth.top));
      expect(late_.top, lessThan(early.top));
      expect(
        late_.top,
        greaterThanOrEqualTo(settled.top - PuzzleConfig.balloonBobAmplitude),
      );

      // Invisible at birth, solid by the time it stops.
      expect(BalloonLayout.opacityOf(balloon, Duration.zero), 0);
      expect(
        BalloonLayout.opacityOf(balloon, PuzzleConfig.balloonRiseDuration),
        1,
      );
    });

    test('a balloon born later is behind one born earlier', () {
      const now = Duration(milliseconds: 600);
      final early = BalloonLayout.rectOf(_balloon(), _referencePhone, now);
      final later = BalloonLayout.rectOf(
        _balloon(bornAt: const Duration(milliseconds: 400)),
        _referencePhone,
        now,
      );
      expect(later.top, greaterThan(early.top));
    });

    test('it bobs on the spot once it arrives, and never escapes upward', () {
      final balloon = _balloon();
      var lowest = double.negativeInfinity;
      var highest = double.infinity;

      for (var ms = 1400; ms <= 15000; ms += 100) {
        final rect = BalloonLayout.rectOf(
          balloon,
          _referencePhone,
          Duration(milliseconds: ms),
        );
        lowest = rect.top > lowest ? rect.top : lowest;
        highest = rect.top < highest ? rect.top : highest;
        expect(rect.top, greaterThan(-rect.height));
        expect(rect.bottom, lessThan(_referencePhone.height + rect.height));
      }

      expect(
        lowest - highest,
        closeTo(2 * PuzzleConfig.balloonBobAmplitude, 1),
        reason: 'it sways, it does not float away',
      );
    });
  });

  group('staying on screen', () {
    test('every horizontal position keeps the whole balloon in view', () {
      for (final x in [0.0, 0.1, 0.5, 0.9, 1.0]) {
        final rect = BalloonLayout.rectOf(
          _balloon(x: x, sizeFactor: 1.15),
          _referencePhone,
          const Duration(seconds: 3),
        );
        expect(rect.left, greaterThanOrEqualTo(0), reason: 'x = $x');
        expect(
          rect.right,
          lessThanOrEqualTo(_referencePhone.width),
          reason: 'x = $x',
        );
      }
    });

    test('the centre is the middle of the square', () {
      const at = Duration(seconds: 3);
      final rect = BalloonLayout.rectOf(_balloon(), _referencePhone, at);
      expect(
        BalloonLayout.centreOf(_balloon(), _referencePhone, at),
        rect.center,
      );
    });
  });
}
