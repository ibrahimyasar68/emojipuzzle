import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:emoji_puzzle_kids/features/balloon/models/balloon.dart';
import 'package:emoji_puzzle_kids/features/balloon/providers/balloon_game_controller.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_game_overlay.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/recording_sound_player.dart';

const _referencePhone = Size(360, 640);

/// Long enough for the opening pairs to have drifted into view, and short
/// enough that the third pair has not arrived yet (§24).
const _afterTheRise = Duration(milliseconds: 1100);

class _Harness {
  _Harness(this.game, this.player, this.finished);

  final BalloonGameController game;
  final RecordingSoundPlayer player;
  final int Function() finished;
}

Future<_Harness> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final player = RecordingSoundPlayer();
  final audio = AudioService(player: player);
  addTearDown(audio.dispose);

  final game = BalloonGameController(random: Random(1));
  addTearDown(game.dispose);

  var finished = 0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          BalloonGameOverlay(
            controller: game,
            audio: audio,
            haptics: null,
            onFinished: () => finished++,
          ),
        ],
      ),
    ),
  );
  return _Harness(game, player, () => finished);
}

Finder _balloon(int id) => find.byKey(ValueKey('balloon-$id'));

/// How big the balloon is drawn right now: chosen and hinted balloons swell.
double _drawnScale(WidgetTester tester, int id) {
  final paint = tester.widget<CustomPaint>(
    find.descendant(of: _balloon(id), matching: find.byType(CustomPaint)),
  );
  return (paint.painter! as BalloonPainter).scale;
}

/// Two balloons in the air that share a colour, and one that does not.
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

Balloon _anotherColour(BalloonGameController game, Balloon than) =>
    game.balloons.firstWhere((b) => b.colourIndex != than.colourIndex);

void main() {
  testWidgets('it opens with two pairs in the air (§24)', (tester) async {
    await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    for (var id = 0; id < 4; id++) {
      expect(_balloon(id), findsOneWidget, reason: 'balloon $id');
    }
    expect(_balloon(4), findsNothing);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('every balloon is at least 72 px across (§2)', (tester) async {
    await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    for (var id = 0; id < 4; id++) {
      final size = tester.getSize(_balloon(id));
      expect(
        size.width,
        greaterThanOrEqualTo(PuzzleConfig.balloonTouchTargetSize),
        reason: 'balloon $id',
      );
      expect(
        size.height,
        greaterThanOrEqualTo(PuzzleConfig.balloonTouchTargetSize),
      );
    }

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('one tap chooses a balloon: it grows, nothing pops (K-5)', (
    tester,
  ) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);
    final (first, _) = _aPair(harness.game);

    expect(_drawnScale(tester, first.id), 1);
    await tester.tap(_balloon(first.id));
    await tester.pump(PuzzleConfig.balloonSelectDuration);

    expect(harness.game.selectedId, first.id);
    expect(harness.player.played, isEmpty, reason: 'a pop is what sounds');
    expect(harness.game.poppedCount, 0);
    expect(_balloon(first.id), findsOneWidget);
    expect(
      _drawnScale(tester, first.id),
      closeTo(PuzzleConfig.balloonSelectedScale, 0.001),
      reason: 'the choice shows in its size, not only its colour',
    );

    // And it still takes up only its own place to touch (§2).
    expect(
      tester.getSize(_balloon(first.id)).width,
      lessThan(PuzzleConfig.balloonTouchTargetSize * 2),
    );

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('a same-colour pair pops together: one sound, both gone', (
    tester,
  ) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);
    final (first, second) = _aPair(harness.game);

    await tester.tap(_balloon(first.id));
    await tester.pump();
    await tester.tap(_balloon(second.id));
    await tester.pump();

    expect(harness.player.played, [Sfx.balloonPop]);
    expect(harness.game.poppedCount, 2);
    expect(_balloon(first.id), findsNothing);
    expect(_balloon(second.id), findsNothing);

    // The bursts play themselves out and leave nothing behind.
    await tester.pump(PuzzleConfig.balloonPopDuration);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('a different colour moves the choice, and says nothing (§20)', (
    tester,
  ) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);
    final (first, _) = _aPair(harness.game);
    final other = _anotherColour(harness.game, first);

    await tester.tap(_balloon(first.id));
    await tester.pump();
    await tester.tap(_balloon(other.id));
    await tester.pump(PuzzleConfig.balloonSelectDuration);

    expect(harness.game.selectedId, other.id);
    expect(harness.player.played, isEmpty, reason: 'no buzzer, no anything');
    expect(harness.game.poppedCount, 0);
    expect(_balloon(first.id), findsOneWidget, reason: 'nothing is lost');
    expect(_drawnScale(tester, first.id), 1, reason: 'it lets go');
    expect(_drawnScale(tester, other.id), greaterThan(1));

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('a balloon chosen for three seconds sets its partner pulsing', (
    tester,
  ) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);
    final (first, _) = _aPair(harness.game);

    await tester.tap(_balloon(first.id));
    await tester.pump(const Duration(milliseconds: 2500));
    final others = [
      for (final b in harness.game.balloons)
        if (b.id != first.id) b.id,
    ];
    for (final id in others) {
      expect(_drawnScale(tester, id), 1, reason: 'no hint before 3 s');
    }

    await tester.pump(const Duration(milliseconds: 600));
    final hinted = harness.game.partnerHintId;
    expect(hinted, isNotNull);

    // A pulse, sampled over one period: it swells and comes back.
    var largest = 1.0;
    var smallest = 2.0;
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 80));
      final scale = _drawnScale(tester, hinted!);
      largest = scale > largest ? scale : largest;
      smallest = scale < smallest ? scale : smallest;
    }
    expect(largest, greaterThan(1.05));
    expect(smallest, lessThan(1.03));

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('a tap that misses does nothing at all (§20)', (tester) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    // The very top-left corner: the balloons are placed between 0.1 and 0.9.
    await tester.tapAt(const Offset(2, 2));
    await tester.pump();

    expect(harness.player.played, isEmpty, reason: 'no buzzer, no anything');
    expect(harness.game.poppedCount, 0);
    expect(harness.finished(), 0);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('it hands back after fifteen seconds (§24)', (tester) async {
    final harness = await _pumpGame(tester);

    await tester.pump(const Duration(milliseconds: 14900));
    expect(harness.finished(), 0);

    await tester.pump(const Duration(milliseconds: 200));
    expect(harness.finished(), 1);
    expect(
      harness.game.balloons,
      isNotEmpty,
      reason: 'balloons left over are not a failure',
    );
  });

  testWidgets('popping all twelve ends it early (§24)', (tester) async {
    final harness = await _pumpGame(tester);

    // Pop every pair in the air, as fast as a child possibly could.
    for (var i = 0; i < 60 && harness.game.poppedCount < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      while (harness.game.balloons.isNotEmpty) {
        final (first, second) = _aPair(harness.game);
        await tester.tap(_balloon(first.id), warnIfMissed: false);
        await tester.pump();
        await tester.tap(_balloon(second.id), warnIfMissed: false);
        await tester.pump();
      }
    }

    expect(harness.game.poppedCount, 12);
    expect(harness.finished(), 0, reason: 'the last pop gets its moment');

    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.finished(), 0);

    await tester.pump(const Duration(milliseconds: 300));
    expect(harness.finished(), 1);
    expect(
      harness.game.elapsed,
      lessThan(PuzzleConfig.balloonGameDuration),
      reason: 'finishing early is the reward',
    );
  });

  testWidgets('it leaves a picture of the game, mid-pop', (tester) async {
    tester.view.physicalSize = _referencePhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = BalloonGameController(random: Random(4));
    addTearDown(game.dispose);
    final captureKey = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: RepaintBoundary(
          key: captureKey,
          child: Stack(
            children: [
              Positioned.fill(
                child: ColoredBox(color: AppPalette.dark.background),
              ),
              BalloonGameOverlay(
                controller: game,
                haptics: null,
                onFinished: () {},
              ),
            ],
          ),
        ),
      ),
    );

    // Let the first balloons rise and a couple more arrive, a frame at a
    // time: the bob and the burst are both per-frame effects.
    for (var i = 0; i < 220; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    // One pair mid-pop, and another balloon chosen and waiting.
    final (first, second) = _aPair(game);
    await tester.tap(_balloon(first.id), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(_balloon(second.id), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 16));
    await tester.tap(_balloon(game.balloons.first.id), warnIfMissed: false);
    for (var i = 0; i < 6; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    await tester.runAsync(() async {
      final boundary = captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/balloon_game.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });

    expect(File('build/balloon_game.png').existsSync(), isTrue);
    expect(tester.takeException(), isNull);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('the game waits while the app is away (§28, §30)', (
    tester,
  ) async {
    final harness = await _pumpGame(tester);

    await tester.pump(const Duration(seconds: 5));
    expect(harness.finished(), 0);

    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }

    // Twice the length of the whole game, spent in the background.
    await tester.pump(const Duration(seconds: 30));
    expect(
      harness.finished(),
      0,
      reason: 'a reward is not something you can be away for and lose',
    );
    expect(harness.game.balloons, isNotEmpty);

    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
      await tester.pump();
    }

    // Ten seconds were still owed, and they are still owed.
    await tester.pump(const Duration(seconds: 9));
    expect(harness.finished(), 0);
    await tester.pump(const Duration(seconds: 2));
    expect(harness.finished(), 1);
  });

  testWidgets('it hands back exactly once', (tester) async {
    final harness = await _pumpGame(tester);

    await tester.pump(const Duration(seconds: 16));
    expect(harness.finished(), 1);

    await tester.pump(const Duration(seconds: 5));
    expect(harness.finished(), 1);
  });
}
