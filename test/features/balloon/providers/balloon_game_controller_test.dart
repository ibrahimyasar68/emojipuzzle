import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/balloon/models/balloon.dart';
import 'package:emoji_puzzle_kids/features/balloon/providers/balloon_game_controller.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_layout.dart';
import 'package:flutter/widgets.dart' show Size;
import 'package:flutter_test/flutter_test.dart';

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

/// Two balloons in the air that share a colour.
(Balloon, Balloon) _aPair(BalloonGameController game) {
  final balloons = game.balloons;
  for (final first in balloons) {
    for (final second in balloons) {
      if (first.id != second.id && first.colourIndex == second.colourIndex) {
        return (first, second);
      }
    }
  }
  throw StateError('no pair in the air');
}

/// Two balloons in the air that do not share a colour.
(Balloon, Balloon) _aMismatch(BalloonGameController game) {
  final balloons = game.balloons;
  for (final first in balloons) {
    for (final second in balloons) {
      if (first.colourIndex != second.colourIndex) return (first, second);
    }
  }
  throw StateError('only one colour in the air');
}

/// Pops one same-colour pair; returns what popped.
List<Balloon> _popAPair(BalloonGameController game) {
  final (first, second) = _aPair(game);
  game.tap(first.id);
  return game.tap(second.id);
}

/// Pops everything in the air right now, pair by pair.
void _popAll(BalloonGameController game) {
  while (game.balloons.isNotEmpty) {
    _popAPair(game);
  }
}

void main() {
  group('spawning (§24)', () {
    test('two pairs, four balloons, are already up when the game opens', () {
      final game = _game();
      addTearDown(game.dispose);

      expect(game.balloons, isEmpty, reason: 'nothing before it starts');
      game.start();

      expect(game.balloons, hasLength(PuzzleConfig.balloonInitialSpawn));
      expect(game.spawnedCount, 4);
      expect(game.isFinished, isFalse);
    });

    test('one more pair arrives roughly every 2.4 seconds', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 2300));
      expect(game.balloons, hasLength(4), reason: 'not yet');

      _runFor(game, const Duration(milliseconds: 200));
      expect(game.balloons, hasLength(6));

      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.balloons, hasLength(8));
    });

    test('balloons still arrive as fast as they did one at a time', () {
      expect(
        PuzzleConfig.balloonSpawnInterval.inMilliseconds / 2,
        1200,
        reason: 'two balloons per 2.4 s is one per 1.2 s (§24)',
      );
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

    test('popping a pair makes room for the next pair', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 5500));
      expect(game.balloons, hasLength(PuzzleConfig.balloonMaxActive));
      final spawnedWhenFull = game.spawnedCount;

      // Full: waiting changes nothing.
      _runFor(game, const Duration(seconds: 3));
      expect(game.spawnedCount, spawnedWhenFull, reason: 'no room');

      _popAPair(game);
      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.spawnedCount, spawnedWhenFull + 2);
    });

    test('a full screen does not bank up a burst of balloons', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      _runFor(game, const Duration(milliseconds: 5500));
      expect(game.balloons, hasLength(PuzzleConfig.balloonMaxActive));

      // Three seconds with the screen full, then two pairs' room at once.
      _runFor(game, const Duration(seconds: 3));
      final spawnedWhenFull = game.spawnedCount;
      _popAPair(game);
      _popAPair(game);

      game.advance(_tick);
      expect(
        game.spawnedCount,
        spawnedWhenFull,
        reason: 'the room does not refill on the next tick',
      );

      // They come back at the same unhurried pace as always: one pair per
      // interval, never two at once.
      _runFor(game, PuzzleConfig.balloonSpawnInterval);
      expect(game.spawnedCount, spawnedWhenFull + 2);
    });
  });

  group('matching colours (§24, K-5)', () {
    test('the first tap only chooses a balloon', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final balloon = game.balloons.first;

      final popped = game.tap(balloon.id);

      expect(popped, isEmpty);
      expect(game.selectedId, balloon.id);
      expect(game.poppedCount, 0);
      expect(game.balloons, contains(balloon));
    });

    test('a second tap on the same colour pops both together', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, second) = _aPair(game);

      game.tap(first.id);
      final popped = game.tap(second.id);

      expect(popped.map((b) => b.id), unorderedEquals([first.id, second.id]));
      expect(game.poppedCount, 2);
      expect(game.selectedId, isNull, reason: 'nothing is left chosen');
      expect(game.balloons.map((b) => b.id), isNot(contains(first.id)));
      expect(game.balloons.map((b) => b.id), isNot(contains(second.id)));
    });

    test('a different colour just moves the choice, silently (§20)', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, other) = _aMismatch(game);
      final before = game.balloons.length;

      game.tap(first.id);
      final popped = game.tap(other.id);

      expect(popped, isEmpty);
      expect(game.selectedId, other.id, reason: 'the newest tap is chosen');
      expect(game.poppedCount, 0);
      expect(game.balloons, hasLength(before), reason: 'nothing is lost');
    });

    test('tapping the chosen balloon again does nothing (§2)', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final balloon = game.balloons.first;

      game.tap(balloon.id);
      final popped = game.tap(balloon.id);

      expect(popped, isEmpty);
      expect(game.selectedId, balloon.id);
      expect(game.poppedCount, 0);
    });

    test('every colour on screen always has a partner', () {
      // Watch whole games with a child tapping at random, mismatches and
      // all: an odd count of any colour would be a balloon nobody can pop.
      for (var seed = 0; seed < 20; seed++) {
        final game = _game(seed: seed);
        final child = Random(seed + 100);
        game.start();

        for (var i = 0; i < 160 && !game.isFinished; i++) {
          game.advance(_tick);
          final balloons = game.balloons;
          if (balloons.isNotEmpty && child.nextBool()) {
            game.tap(balloons[child.nextInt(balloons.length)].id);
          }

          final counts = <int, int>{};
          for (final balloon in game.balloons) {
            counts.update(balloon.colourIndex, (n) => n + 1, ifAbsent: () => 1);
          }
          for (final entry in counts.entries) {
            expect(
              entry.value.isEven,
              isTrue,
              reason: 'seed $seed, ${game.elapsed.inMilliseconds} ms: '
                  'colour ${entry.key} has ${entry.value}',
            );
          }
        }
        game.dispose();
      }
    });

    test('a pair is born together, in one colour', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      _runFor(game, const Duration(milliseconds: 5000));

      final balloons = game.balloons;
      for (var i = 0; i + 1 < balloons.length; i += 2) {
        expect(balloons[i].colourIndex, balloons[i + 1].colourIndex);
        expect(balloons[i].bornAt, balloons[i + 1].bornAt);
      }
    });

    test('consecutive pairs walk the palette instead of repeating', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();

      expect(
        game.balloons.map((b) => b.colourIndex).toSet(),
        hasLength(2),
        reason: 'the two opening pairs are two different colours',
      );
    });
  });

  group('showing the way (§24, K-5)', () {
    test('a balloon chosen for three seconds gets its partner pulsing', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, _) = _aPair(game);

      game.tap(first.id);
      expect(game.partnerHintId, isNull, reason: 'not straight away');

      _runFor(game, const Duration(milliseconds: 2900));
      expect(game.partnerHintId, isNull);

      _runFor(game, const Duration(milliseconds: 200));
      final hinted =
          game.balloons.firstWhere((b) => b.id == game.partnerHintId);
      expect(hinted.id, isNot(first.id));
      expect(hinted.colourIndex, first.colourIndex, reason: 'a real partner');
    });

    test('choosing another balloon starts the wait again', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, other) = _aMismatch(game);

      game.tap(first.id);
      _runFor(game, const Duration(milliseconds: 2500));
      game.tap(other.id);
      _runFor(game, const Duration(milliseconds: 1000));

      expect(game.partnerHintId, isNull, reason: 'one second, not three');
    });

    test('popping the pair ends the hint', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, second) = _aPair(game);

      game.tap(first.id);
      _runFor(game, const Duration(seconds: 4));
      expect(game.partnerHintId, isNotNull);

      game.tap(second.id);
      expect(game.partnerHintId, isNull);
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

    test('tapping after the end is ignored', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, second) = _aPair(game);

      _runFor(game, const Duration(seconds: 16));
      game.tap(first.id);
      final popped = game.tap(second.id);

      expect(popped, isEmpty);
      expect(game.poppedCount, 0);
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

      _popAPair(game);
      _runFor(game, const Duration(seconds: 16));

      // The only numbers the game keeps are how many it made and how many
      // were popped. There is nothing a child can fail here.
      expect(game.poppedCount, 2);
      expect(game.spawnedCount, greaterThan(2));
      expect(game.isFinished, isTrue);
    });

    test('tapping a balloon that is gone, or never was, is not an error', () {
      final game = _game();
      addTearDown(game.dispose);
      game.start();
      final (first, second) = _aPair(game);

      game.tap(first.id);
      game.tap(second.id);
      game.tap(first.id);
      game.tap(9999);

      expect(game.poppedCount, 2);
      expect(game.selectedId, isNull);
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
        if (i % 17 == 0 && balloons.isNotEmpty) _popAPair(game);
      }
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
