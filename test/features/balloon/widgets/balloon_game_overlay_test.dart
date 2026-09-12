import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/balloon/providers/balloon_game_controller.dart';
import 'package:emoji_puzzle_kids/features/balloon/widgets/balloon_game_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/recording_sound_player.dart';

const _referencePhone = Size(360, 640);

/// Long enough for the first balloons to have drifted into view, and short
/// enough that the fourth one has not arrived yet (§24).
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

void main() {
  testWidgets('it opens with three balloons in the air (§24)', (tester) async {
    await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    expect(_balloon(0), findsOneWidget);
    expect(_balloon(1), findsOneWidget);
    expect(_balloon(2), findsOneWidget);
    expect(_balloon(3), findsNothing);

    await tester.pump(const Duration(seconds: 15));
  });

  testWidgets('every balloon is at least 72 px across (§2)', (tester) async {
    await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    for (var id = 0; id < 3; id++) {
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

  testWidgets('a tap pops it: sound, then gone (§24, §27)', (tester) async {
    final harness = await _pumpGame(tester);
    await tester.pump(_afterTheRise);

    await tester.tap(_balloon(0));
    await tester.pump();

    expect(harness.player.played, [Sfx.balloonPop]);
    expect(harness.game.poppedCount, 1);
    expect(_balloon(0), findsNothing, reason: 'it is not tappable twice');

    // The burst plays itself out and leaves nothing behind.
    await tester.pump(PuzzleConfig.balloonPopDuration);
    await tester.pump(const Duration(milliseconds: 50));
    expect(tester.takeException(), isNull);

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

    // Pop whatever is in the air, as fast as a child possibly could.
    for (var i = 0; i < 60 && harness.game.poppedCount < 12; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      for (final balloon in [...harness.game.balloons]) {
        final finder = _balloon(balloon.id);
        if (finder.evaluate().isEmpty) continue;
        await tester.tap(finder, warnIfMissed: false);
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
              const Positioned.fill(
                child: ColoredBox(color: Color(0xFFFDF7EF)),
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

    await tester.tap(_balloon(1), warnIfMissed: false);
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

  testWidgets('it hands back exactly once', (tester) async {
    final harness = await _pumpGame(tester);

    await tester.pump(const Duration(seconds: 16));
    expect(harness.finished(), 1);

    await tester.pump(const Duration(seconds: 5));
    expect(harness.finished(), 1);
  });
}
