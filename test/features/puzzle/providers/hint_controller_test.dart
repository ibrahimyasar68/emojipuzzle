import 'package:emoji_puzzle_kids/features/puzzle/models/hint_stage.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/hint_controller.dart';
import 'package:flutter_test/flutter_test.dart';

const _second = Duration(seconds: 1);

HintController _controller() => HintController();

void main() {
  group('the ladder (§21)', () {
    test('8, 16, 24 and 32 seconds, and nothing in between', () {
      final hint = _controller();
      addTearDown(hint.dispose);

      const expected = {
        0: HintStage.none,
        7: HintStage.none,
        8: HintStage.pulsePiece,
        15: HintStage.pulsePiece,
        16: HintStage.pulseBoth,
        23: HintStage.pulseBoth,
        24: HintStage.ghostMove,
        31: HintStage.ghostMove,
        32: HintStage.autoPlace,
        40: HintStage.autoPlace,
      };

      expected.forEach((seconds, stage) {
        expect(
          hint.stageFor(Duration(seconds: seconds)),
          stage,
          reason: '$seconds s',
        );
      });
    });

    test('climbs one rung at a time while nothing happens', () {
      final hint = _controller();
      addTearDown(hint.dispose);
      final seen = <HintStage>[];
      hint.addListener(() => seen.add(hint.stage));

      for (var i = 0; i < 24; i++) {
        hint.advance(_second);
      }

      expect(hint.stage, HintStage.ghostMove);
      expect(seen, [
        HintStage.pulsePiece,
        HintStage.pulseBoth,
        HintStage.ghostMove,
      ]);
    });
  });

  group('the child doing anything (§21.2)', () {
    test('sends the ladder back to the bottom', () {
      final hint = _controller();
      addTearDown(hint.dispose);

      for (var i = 0; i < 20; i++) {
        hint.advance(_second);
      }
      expect(hint.stage, HintStage.pulseBoth);

      hint.registerInteraction();

      expect(hint.stage, HintStage.none);
      expect(hint.idleFor, Duration.zero);
    });

    test('costs nothing when the child is already busy', () {
      final hint = _controller();
      addTearDown(hint.dispose);
      var notifications = 0;
      hint.addListener(() => notifications++);

      hint
        ..registerInteraction()
        ..registerInteraction();

      expect(notifications, 0, reason: 'no rebuild for touch after touch');
    });
  });

  group('placing it for the child (§21)', () {
    test('asks once, then starts the wait over', () {
      final hint = _controller();
      addTearDown(hint.dispose);
      var placements = 0;
      hint.onAutoPlace = () => placements++;

      for (var i = 0; i < 32; i++) {
        hint.advance(_second);
      }

      expect(placements, 1);
      expect(hint.stage, HintStage.none, reason: 'the next piece gets 8 s');
      expect(hint.idleFor, Duration.zero);

      for (var i = 0; i < 8; i++) {
        hint.advance(_second);
      }
      expect(hint.stage, HintStage.pulsePiece);
      expect(placements, 1);
    });

    test('a controller with no handler still resets and carries on', () {
      final hint = _controller();
      addTearDown(hint.dispose);

      for (var i = 0; i < 32; i++) {
        hint.advance(_second);
      }
      expect(hint.stage, HintStage.none, reason: 'reset even with no handler');

      for (var i = 0; i < 8; i++) {
        hint.advance(_second);
      }
      expect(
        hint.stage,
        HintStage.pulsePiece,
        reason: 'and the ladder starts again from the bottom',
      );
    });
  });

  group('leaving and coming back (§28, §21.2)', () {
    test('a paused clock does not move', () {
      final hint = _controller();
      addTearDown(hint.dispose);

      for (var i = 0; i < 10; i++) {
        hint.advance(_second);
      }
      hint.pause();
      for (var i = 0; i < 30; i++) {
        hint.advance(_second);
      }

      expect(hint.isPaused, isTrue);
      expect(hint.stage, HintStage.pulsePiece, reason: 'frozen where it was');
    });

    test('coming back is a fresh eight seconds, not a continuation', () {
      final hint = _controller();
      addTearDown(hint.dispose);

      for (var i = 0; i < 20; i++) {
        hint.advance(_second);
      }
      hint
        ..pause()
        ..resume();

      expect(hint.stage, HintStage.none);
      expect(hint.idleFor, Duration.zero);
      expect(hint.isRunning, isTrue);
      hint.stop();
    });
  });

  test('a real clock drives it', () async {
    final hint = HintController(
      firstDelay: const Duration(milliseconds: 40),
      stageInterval: const Duration(milliseconds: 40),
      tickInterval: const Duration(milliseconds: 10),
    )..start();
    addTearDown(hint.dispose);

    expect(hint.isRunning, isTrue);
    await Future<void>.delayed(const Duration(milliseconds: 120));

    expect(hint.stage.index, greaterThanOrEqualTo(HintStage.pulsePiece.index));
    hint.stop();
    expect(hint.isRunning, isFalse);
    expect(hint.stage, HintStage.none);
  });
}
