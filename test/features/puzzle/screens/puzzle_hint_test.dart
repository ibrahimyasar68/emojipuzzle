import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/recording_sound_player.dart';

final _captureKey = GlobalKey();

const _referencePhone = Size(360, 640);

/// The hint always points at piece 0 of a 2×2: every piece is a corner, so
/// the tie-break on the lowest id decides (§21.1).
const _targetPieceId = 0;

late RecordingSoundPlayer player;

Future<GameProvider> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  player = RecordingSoundPlayer();
  final audio = AudioService(player: player);
  addTearDown(audio.dispose);

  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
    audio: audio,
  );
  addTearDown(game.dispose);
  await tester.runAsync(
    () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: _captureKey, child: const PuzzleScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return game;
}

/// True while the target tray piece is breathing (§21).
bool _pieceIsPulsing(WidgetTester tester) {
  final transforms = tester.widgetList<Transform>(
    find.ancestor(
      of: find.byKey(const ValueKey('tray-piece-$_targetPieceId')),
      matching: find.byType(Transform),
    ),
  );
  return transforms.any((t) => t.transform.getMaxScaleOnAxis() > 1.001);
}

Finder get _slotPulse => find.byKey(const ValueKey('hint-slot-pulse'));

Finder get _ghost => find.byKey(const ValueKey('hint-ghost'));

/// Idles for [seconds], letting the pulse animations run.
Future<void> _waitStill(WidgetTester tester, int seconds) async {
  for (var i = 0; i < seconds * 4; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
}

void main() {
  testWidgets('a busy child is never interrupted (§21)', (tester) async {
    await _pumpGame(tester);

    await _waitStill(tester, 7);

    expect(_pieceIsPulsing(tester), isFalse);
    expect(_slotPulse, findsNothing);
    expect(player.played, isEmpty);
  });

  testWidgets('8 s: the easiest piece pulses, once, with a chime (§21)', (
    tester,
  ) async {
    await _pumpGame(tester);

    await _waitStill(tester, 9);

    expect(_pieceIsPulsing(tester), isTrue);
    expect(_slotPulse, findsNothing, reason: 'the slot waits its turn');
    expect(player.played, [Sfx.hint]);
  });

  testWidgets('16 s: the slot joins in (§21)', (tester) async {
    await _pumpGame(tester);

    await _waitStill(tester, 17);

    expect(_pieceIsPulsing(tester), isTrue);
    expect(_slotPulse, findsOneWidget);
    expect(_ghost, findsNothing);
    expect(player.played, [Sfx.hint], reason: 'the chime does not nag');
  });

  testWidgets('24 s: a ghost shows the way (§21)', (tester) async {
    await _pumpGame(tester);

    await _waitStill(tester, 25);

    expect(_ghost, findsOneWidget);
    expect(_slotPulse, findsOneWidget, reason: 'the slot is still breathing');

    // Leave a picture of the loudest hint the game ever gives.
    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/hint_ghost.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
  });

  testWidgets('32 s: the game places it, then goes quiet again (§21)', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    await _waitStill(tester, 33);
    await tester.pumpAndSettle(); // the piece flies home

    expect(game.placedCount, 1);
    expect(game.stateOf(_targetPieceId).failedAttempts, 0);
    expect(
      find.byKey(const ValueKey('board-piece-$_targetPieceId')),
      findsOneWidget,
    );
    expect(_ghost, findsNothing);
    expect(_slotPulse, findsNothing, reason: 'the ladder starts over');
    expect(
      player.played,
      contains(Sfx.pieceSnap),
      reason: 'it lands like any other piece (§22)',
    );
  });

  testWidgets('a touch anywhere stops the hint (§21.2)', (tester) async {
    await _pumpGame(tester);

    await _waitStill(tester, 17);
    expect(_slotPulse, findsOneWidget);

    // Not on a piece — just a tap on the board area.
    await tester.tapAt(const Offset(180, 60));
    await tester.pump();

    expect(_slotPulse, findsNothing);
    expect(_pieceIsPulsing(tester), isFalse);

    // And the wait starts from the beginning.
    await _waitStill(tester, 7);
    expect(_pieceIsPulsing(tester), isFalse);
    await _waitStill(tester, 2);
    expect(_pieceIsPulsing(tester), isTrue);
  });

  testWidgets('playing keeps the hints away', (tester) async {
    final game = await _pumpGame(tester);

    for (var i = 0; i < 5; i++) {
      await _waitStill(tester, 6);
      await tester.tapAt(const Offset(180, 60));
      await tester.pump();
    }

    expect(game.placedCount, 0, reason: 'nothing was placed for the child');
    expect(player.played, isEmpty);
    expect(PuzzleConfig.hintFirstDelay, const Duration(seconds: 8));
  });
}
