import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/balloon/providers/balloon_game_controller.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_layout.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

import 'dart:math' show Random;

const _phone = Size(360, 640);

const _tick = Duration(milliseconds: 100);

BalloonGameController _game({int? seed}) => BalloonGameController(
      random: Random(seed ?? 7),
    );

/// Runs the game clock forward without waiting for real time.
void _runFor(BalloonGameController game, Duration total) {
  var left = total;
  while (left > Duration.zero) {
    final step = left < _tick ? left : _tick;
    game.advance(step);
    left -= step;
  }
}

/// Pops everything in the air right now.
void _popAll(BalloonGameController game) {
  for (final balloon in game.balloons) {
    game.pop(balloon.id);
  }
}

void main() {
  group('spawning (§24)', () {
    test('three balloons are already up when the game opens', () {
      final game = _game();
      addTearDown(game.dispose);

      expect(game.balloons, isEmpty, reason: 'nothing before it starts');
      game.start();

      expect(game.balloons, hasLength(PuzzleConfig.balloonInitialSpawn));
      expect(game.spawnedCount, 3);
      expect(game.isFinished, isFalse);
    });

    test('one more arrives roughly every 1.2 seconds', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 1100));
      expect(game.balloons, hasLength(3), reason: 'not yet');

      _runFor(game, const Duration(milliseconds: 200));
      expect(game.balloons, hasLength(4));

      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.balloons, hasLength(5));
    });

    test('never more than eight in the air at once', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      var highest = game.balloons.length;
      for (var i = 0; i < 140; i++) {
        game.advance(_tick);
        highest =
            highest > game.balloons.length ? highest : game.balloons.length;
      }

      expect(highest, PuzzleConfig.balloonMaxActive);
      expect(highest, lessThanOrEqualTo(8));
    });

    test('never more than twelve balloons in the whole game', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      // Pop everything on sight for the full fifteen seconds, so the cap on
      // active balloons is never what is holding spawning back.
      for (var i = 0; i < 150; i++) {
        game.advance(_tick);
        _popAll(game);
      }

      expect(game.spawnedCount, PuzzleConfig.balloonTotal);
      expect(game.spawnedCount, 12);
    });

    test('popping one makes room for the next', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 6500));
      expect(game.balloons, hasLength(PuzzleConfig.balloonMaxActive));
      final spawnedWhenFull = game.spawnedCount;

      // Full: waiting changes nothing.
      _runFor(game, const Duration(seconds: 3));
      expect(game.spawnedCount, spawnedWhenFull, reason: 'no room');

      game.pop(game.balloons.first.id);
      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.spawnedCount, spawnedWhenFull + 1);
    });

    test('a full screen does not bank up a burst of balloons', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 6500));
      expect(game.balloons, hasLength(PuzzleConfig.balloonMaxActive));

      // Five seconds with the screen full, then three slots free at once.
      _runFor(game, const Duration(seconds: 5));
      final spawnedWhenFull = game.spawnedCount;
      for (final id in game.balloons.take(3).map((b) => b.id).toList()) {
        game.pop(id);
      }

      game.advance(_tick);
      expect(
        game.spawnedCount,
        spawnedWhenFull,
        reason: 'three slots do not refill on the next tick',
      );

      // They come back at the same unhurried pace as always: one per
      // interval, never three at once.
      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.spawnedCount, spawnedWhenFull + 1);
      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.spawnedCount, spawnedWhenFull + 2);
    });
  });

  group('ending (§24)', () {
    test('fifteen seconds is the end, balloons up or not', () {
      final game = _game();
      addTearDown(game.dispose);
      var finished = 0;
      game.onFinished = () => finished++;
      game.start();

      _runFor(game, const Duration(milliseconds: 14900));
      expect(game.isFinished, isFalse);
      expect(finished, 0);

      _runFor(game, const Duration(milliseconds: 200));
      expect(game.isFinished, isTrue);
      expect(finished, 1);
      expect(game.balloons, isNotEmpty, reason: 'left in the air, not judged');
    });

    test('all twelve popped ends it 500 ms later', () {
      final game = _game();
      addTearDown(game.dispose);
      var finished = 0;
      game.onFinished = () => finished++;
      game.start();

      for (var i = 0;
          i < 150 && game.poppedCount < PuzzleConfig.balloonTotal;
          i++) {
        game.advance(_tick);
        _popAll(game);
      }

      expect(game.poppedCount, PuzzleConfig.balloonTotal);
      expect(game.isFinished, isFalse, reason: 'the last pop is worth seeing');

      _runFor(game, const Duration(milliseconds: 400));
      expect(game.isFinished, isFalse);

      _runFor(game, const Duration(milliseconds: 200));
      expect(game.isFinished, isTrue);
      expect(finished, 1);
    });

    test('it finishes once, and the clock stops with it', () {
      final game = _game();
      addTearDown(game.dispose);
      var finished = 0;
      game.onFinished = () => finished++;
      game.start();

      _runFor(game, const Duration(seconds: 20));
      final spawned = game.spawnedCount;

      _runFor(game, const Duration(seconds: 20));
      expect(finished, 1);
      expect(game.spawnedCount, spawned, reason: 'nothing after the end');
    });

    test('popping after the end is ignored', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final id = game.balloons.first.id;

      _runFor(game, const Duration(seconds: 16));
      final popped = game.poppedCount;
      game.pop(id);

      expect(game.poppedCount, popped);
    });
  });

  group('interruption (§28)', () {
    test('the clock stops while the app is away', () {
      final game = _game();
      addTearDown(game.dispose);
      var finished = 0;
      game.onFinished = () => finished++;
      game.start();

      _runFor(game, const Duration(seconds: 5));
      final spawnedBefore = game.spawnedCount;

      game.pause();
      expect(game.isPaused, isTrue);

      // Far longer than the whole game, spent in somebody's pocket.
      _runFor(game, const Duration(seconds: 60));
      expect(game.isFinished, isFalse, reason: 'no time passed for the child');
      expect(finished, 0);
      expect(game.spawnedCount, spawnedBefore);

      game.resume();
      expect(game.isPaused, isFalse);

      // And what was left is still left: ten of the fifteen seconds.
      _runFor(game, const Duration(seconds: 9));
      expect(game.isFinished, isFalse);
      _runFor(game, const Duration(seconds: 2));
      expect(game.isFinished, isTrue);
    });

    test('pausing a finished game changes nothing', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      _runFor(game, const Duration(seconds: 16));
      expect(game.isFinished, isTrue);

      game.pause();
      expect(game.isPaused, isFalse, reason: 'there is nothing left to pause');
      game.resume();
      expect(game.isFinished, isTrue);
    });
  });

  group('no penalty (§20)', () {
    test('balloons left in the air are not counted against the child', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      game.pop(game.balloons.first.id);
      _runFor(game, const Duration(seconds: 16));

      // The only numbers the game keeps are how many it made and how many
      // were popped. There is nothing a child can fail here.
      expect(game.poppedCount, 1);
      expect(game.spawnedCount, greaterThan(1));
      expect(game.isFinished, isTrue);
    });

    test('tapping the same balloon twice is not an error', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final id = game.balloons.first.id;

      game.pop(id);
      game.pop(id);
      game.pop(9999);

      expect(game.poppedCount, 1);
    });
  });

  group('the balloons themselves', () {
    test('the same seed makes the same game', () {
      final first = BalloonGameController(random: Random(3))..start();
      final second = BalloonGameController(random: Random(3))..start();
      addTearDown(first.dispose);
      addTearDown(second.dispose);

      _runFor(first, const Duration(seconds: 5));
      _runFor(second, const Duration(seconds: 5));

      expect(
        first.balloons.map((b) => '${b.id}:${b.x}:${b.restY}:${b.colourIndex}'),
        second.balloons
            .map((b) => '${b.id}:${b.x}:${b.restY}:${b.colourIndex}'),
      );
    });

    test('no two balloons ever overlap (§2)', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      // Checked against the real geometry, at every tick of a whole game,
      // popping as we go so cells are reused as well as handed out.
      for (var i = 0; i < 150; i++) {
        game.advance(_tick);
        final balloons = game.balloons;
        for (var a = 0; a < balloons.length; a++) {
          for (var b = a + 1; b < balloons.length; b++) {
            final first =
                BalloonLayout.rectOf(balloons[a], _phone, game.elapsed);
            final second =
                BalloonLayout.rectOf(balloons[b], _phone, game.elapsed);
            expect(
              first.overlaps(second.deflate(1)),
              isFalse,
              reason: 'balloons ${balloons[a].id} and ${balloons[b].id} '
                  'at ${game.elapsed.inMilliseconds} ms',
            );
          }
        }
        if (i % 17 == 0 && balloons.isNotEmpty) game.pop(balloons.first.id);
      }
    });

    test('the colours walk the palette instead of repeating', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      expect(
        game.balloons.map((b) => b.colourIndex).toSet(),
        hasLength(game.balloons.length),
        reason: 'the three it opens with are three different colours',
      );
    });

    test('each one is placed inside the play area and knows when it was born',
        () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      _runFor(game, const Duration(seconds: 4));

      for (final balloon in game.balloons) {
        expect(balloon.x, inInclusiveRange(0.0, 1.0));
        expect(balloon.restY, inInclusiveRange(0.0, 1.0));
        expect(balloon.colourIndex, inInclusiveRange(0, 4));
        expect(balloon.bornAt, lessThanOrEqualTo(game.elapsed));
      }

      // Ids are handed out in spawn order, with no gaps.
      expect(
        game.balloons.map((b) => b.id).toList(),
        equals(List<int>.generate(game.balloons.length, (i) => i)),
      );
    });
  });
}
