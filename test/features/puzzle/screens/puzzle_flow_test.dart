import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _captureKey = GlobalKey();

const _referencePhone = Size(360, 640);

Future<GameProvider> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  addTearDown(game.dispose);
  await tester.runAsync(() => game.startNextPuzzle());

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: const MaterialApp(home: PuzzleScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return game;
}

Offset _slotCentre(WidgetTester tester, GameProvider game, int pieceId) {
  final boardRect = tester.getRect(find.byKey(const ValueKey('puzzle-board')));
  final piece = game.pieces.firstWhere((p) => p.id == pieceId);
  final cell = CoordinateMapper.cellSizeOf(game.grid, boardRect.size);
  return boardRect.topLeft +
      CoordinateMapper.pixelOf(piece.normalizedPosition, boardRect.size) +
      Offset(cell.width / 2, cell.height / 2);
}

/// Solves the whole puzzle with explicit pumps.
///
/// No `pumpAndSettle` anywhere: the last piece starts the celebration, and
/// settling through confetti would carry the test past the very moment it
/// is about to check (§23).
Future<void> _solveWithFingers(WidgetTester tester, GameProvider game) async {
  for (final piece in [...game.pieces]) {
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-piece-${piece.id}'))),
    );
    await gesture.moveBy(const Offset(0, -30)); // break the touch slop
    await tester.pump();
    await gesture.moveTo(_slotCentre(tester, game, piece.id));
    await tester.pump();
    await gesture.up();
    await tester.pump(); // the settle flight's first tick
    await tester.pump(PuzzleConfig.snapSettleDuration);
    await tester.pump(const Duration(milliseconds: 20));
  }
}

/// Watches the celebration through to the end (§23).
Future<void> _watchCelebration(WidgetTester tester) async {
  await tester.pump(PuzzleConfig.celebrationDuration);
  await tester.pump();
}

/// The balloons come between the celebration and the next puzzle (§23,
/// §24). A child pops them; a test can just let the fifteen seconds pass,
/// which is the other way the game ends.
Future<void> _watchBalloons(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('balloon-game')), findsOneWidget);
  await tester.pump(PuzzleConfig.balloonGameDuration);
  await tester.pump();
}

/// The last step of the sequence: the sticker just earned (§23, §25).
Future<void> _watchSticker(WidgetTester tester) async {
  expect(find.byKey(const ValueKey('sticker-reward')), findsOneWidget);
  await tester.pump(PuzzleConfig.stickerRewardDuration);
  await tester.pump();
}

/// Lets the real work behind `startPuzzle` (painting the picture) finish.
Future<void> _settleAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('finishing a puzzle leads into the next one', (tester) async {
    final game = await _pumpGame(tester);
    expect(game.puzzle.id, 'apple_01');

    await _solveWithFingers(tester, game);
    expect(game.isComplete, isTrue);

    // The finished picture is celebrated first (§23).
    await tester.pump(const Duration(milliseconds: 100));
    expect(game.puzzle.id, 'apple_01', reason: 'no rush');
    expect(find.byKey(const ValueKey('celebration-overlay')), findsOneWidget);

    await _watchCelebration(tester);
    await _watchBalloons(tester);
    await _watchSticker(tester);
    await _settleAsync(tester);

    expect(game.puzzle.id, 'cat_01');
    expect(game.placedCount, 0);
    expect(game.isPuzzleCompleted('apple_01'), isTrue);
    for (final piece in game.pieces) {
      expect(find.byKey(ValueKey('tray-piece-${piece.id}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('board-piece-0')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('the balloons come between the two puzzles (§23, §24)', (
    tester,
  ) async {
    final game = await _pumpGame(tester);
    await _solveWithFingers(tester, game);

    // Celebration first, and no balloons underneath it.
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('celebration-overlay')), findsOneWidget);
    expect(find.byKey(const ValueKey('balloon-game')), findsNothing);

    await _watchCelebration(tester);

    // Then the balloons, and the puzzle has still not moved on.
    expect(find.byKey(const ValueKey('celebration-overlay')), findsNothing);
    expect(find.byKey(const ValueKey('balloon-game')), findsOneWidget);
    expect(game.puzzle.id, 'apple_01', reason: 'the reward is not skipped');

    // Fourteen seconds in they are still playing.
    await tester.pump(const Duration(milliseconds: 14000));
    expect(game.puzzle.id, 'apple_01');

    await tester.pump(const Duration(seconds: 2));
    expect(find.byKey(const ValueKey('balloon-game')), findsNothing);

    // And then the sticker, which is what the balloons were leading to.
    await _watchSticker(tester);
    await _settleAsync(tester);

    expect(game.puzzle.id, 'cat_01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('popping every balloon moves on sooner (§24)', (tester) async {
    final game = await _pumpGame(tester);
    await _solveWithFingers(tester, game);
    await _watchCelebration(tester);

    expect(find.byKey(const ValueKey('balloon-game')), findsOneWidget);

    // Pop everything that appears, the way a child racing through would.
    for (var i = 0; i < 60; i++) {
      await tester.pump(const Duration(milliseconds: 200));
      if (find.byKey(const ValueKey('balloon-game')).evaluate().isEmpty) break;
      for (var id = 0; id < PuzzleConfig.balloonTotal; id++) {
        final balloon = find.byKey(ValueKey('balloon-$id'));
        if (balloon.evaluate().isEmpty) continue;
        await tester.tap(balloon, warnIfMissed: false);
        await tester.pump();
      }
    }

    await _watchSticker(tester);
    await _settleAsync(tester);
    expect(game.puzzle.id, 'cat_01');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a picture played again earns no second sticker (§4, §25)', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    // Finish it once: the sticker is earned.
    await _solveWithFingers(tester, game);
    await _watchCelebration(tester);
    await _watchBalloons(tester);
    expect(find.byKey(const ValueKey('sticker-reward')), findsOneWidget);
    await _watchSticker(tester);
    await _settleAsync(tester);

    // Now play that same picture again, the way Free Mode does.
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
    );
    await tester.pumpAndSettle();

    await _solveWithFingers(tester, game);
    await _watchCelebration(tester);
    await _watchBalloons(tester);

    expect(
      find.byKey(const ValueKey('sticker-reward')),
      findsNothing,
      reason: 'it was already in the album; giving it again rewards nothing',
    );
    await _settleAsync(tester);
    expect(game.progress.completedPuzzleIds, contains('apple_01'));
    expect(tester.takeException(), isNull);
  });

  testWidgets('a 2×3 puzzle lays out six pieces on the same screen', (
    tester,
  ) async {
    tester.view.physicalSize = _referencePhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('banana_01')),
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

    expect(game.pieces, hasLength(6));
    for (final piece in game.pieces) {
      final size = tester.getSize(
        find.byKey(ValueKey('tray-piece-${piece.id}')),
      );
      expect(size.width, greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize));
      expect(
        size.height,
        greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
      );
    }
    expect(tester.takeException(), isNull);

    // Leave a picture of a level 2 puzzle: six pieces, its own palette.
    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/level2_banana.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });
  });

  testWidgets('the next puzzle gets its own paths, not the old ones', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    await _solveWithFingers(tester, game);
    await _watchCelebration(tester);
    await _watchBalloons(tester);
    await _watchSticker(tester);
    await _settleAsync(tester);

    // A stale path cache would show the previous puzzle's pieces here; a
    // wrong-sized one would throw the board's assert.
    expect(game.puzzle.id, 'cat_01');
    expect(find.byKey(const ValueKey('puzzle-board')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
