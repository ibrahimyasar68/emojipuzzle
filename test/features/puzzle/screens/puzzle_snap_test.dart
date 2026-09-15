import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/feedback_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

final _captureKey = GlobalKey();

const _referencePhone = Size(360, 640);
final _puzzle = PuzzleCatalog.v1.byId('apple_01');

/// A picture at the first stage of a game: 2×2 (K-15).
final _grid = GameRules.stageGrids.first;

Future<GameProvider> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  addTearDown(game.dispose);
  await tester.runAsync(() => game.startPuzzle(_puzzle));

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

/// Global position of the centre of a piece's own slot on the board.
Offset _slotCentre(WidgetTester tester, GameProvider game, int pieceId) {
  final boardRect = tester.getRect(find.byKey(const ValueKey('puzzle-board')));
  final piece = game.pieces.firstWhere((p) => p.id == pieceId);
  final cell = CoordinateMapper.cellSizeOf(_grid, boardRect.size);
  final cellOrigin = CoordinateMapper.pixelOf(
    piece.normalizedPosition,
    boardRect.size,
  );
  return boardRect.topLeft +
      cellOrigin +
      Offset(cell.width / 2, cell.height / 2);
}

/// Drags a piece by its centre, so the grab point is the piece's centre and
/// the finger position is also the piece's centre (§9) — which makes the
/// arithmetic in these tests trivial.
Future<void> _dragPieceTo(
  WidgetTester tester,
  int pieceId,
  Offset target,
) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(ValueKey('tray-piece-$pieceId'))),
  );
  await gesture.moveBy(const Offset(0, -30)); // break the touch slop
  await tester.pump();
  await gesture.moveTo(target);
  await tester.pump();
  await gesture.up();
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('a piece dropped on its slot stays there', (tester) async {
    final game = await _pumpGame(tester);

    await _dragPieceTo(tester, 0, _slotCentre(tester, game, 0));

    expect(game.placedCount, 1);
    expect(find.byKey(const ValueKey('board-piece-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('tray-piece-0')), findsNothing);
    expect(find.byKey(const ValueKey('flight-piece-0')), findsNothing);
    expect(game.stateOf(0).failedAttempts, 0);
  });

  testWidgets('a near miss still snaps (§18)', (tester) async {
    final game = await _pumpGame(tester);

    // Cell is 172 wide here, so the threshold is ~60 px.
    await _dragPieceTo(
      tester,
      0,
      _slotCentre(tester, game, 0) + const Offset(40, 20),
    );

    expect(game.placedCount, 1);
  });

  testWidgets('a wrong drop goes home without any punishment (§20)', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    final before = tester.getTopLeft(
      find.byKey(const ValueKey('tray-piece-0')),
    );
    final slot = game.stateOf(0).traySlotIndex;

    // Drop it on a completely different cell.
    await _dragPieceTo(
      tester,
      0,
      _slotCentre(tester, game, 3),
    );

    expect(game.placedCount, 0, reason: 'nothing was placed');
    expect(find.byKey(const ValueKey('board-piece-0')), findsNothing);
    expect(find.byKey(const ValueKey('tray-piece-0')), findsOneWidget);
    expect(
      tester.getTopLeft(find.byKey(const ValueKey('tray-piece-0'))),
      before,
      reason: 'it goes back to its own slot (§16.2)',
    );
    expect(game.stateOf(0).traySlotIndex, slot);
    expect(game.stateOf(0).failedAttempts, 1, reason: 'only the counter moves');
    expect(tester.takeException(), isNull);
  });

  testWidgets('a piece dropped on the wrong slot never steals it (§18.2)', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    await _dragPieceTo(tester, 1, _slotCentre(tester, game, 2));

    expect(game.placedCount, 0);
    expect(find.byKey(const ValueKey('board-piece-1')), findsNothing);
    expect(find.byKey(const ValueKey('board-piece-2')), findsNothing);
  });

  testWidgets('a landing piece squashes on its way in (§22)', (tester) async {
    final game = await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(_slotCentre(tester, game, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(); // the settle flight's first tick
    await tester.pump(PuzzleConfig.snapSettleDuration ~/ 2);

    final transform = tester.widget<Transform>(
      find
          .ancestor(
            of: find.byKey(const ValueKey('flight-piece-0')),
            matching: find.byType(Transform),
          )
          .first,
    );

    expect(
      transform.transform.getMaxScaleOnAxis(),
      greaterThan(1.0),
      reason: 'mid-landing the piece is a little larger than its slot',
    );

    await tester.pumpAndSettle();
    expect(game.placedCount, 1, reason: 'and it still lands exactly right');
  });

  testWidgets('the piece is visible in flight, then handed over', (
    tester,
  ) async {
    final game = await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(_slotCentre(tester, game, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump(); // first frame of the settle flight

    expect(find.byKey(const ValueKey('flight-piece-0')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('board-piece-0')),
      findsNothing,
      reason: 'a piece is never drawn twice, in flight and at rest',
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('flight-piece-0')), findsNothing);
    expect(find.byKey(const ValueKey('board-piece-0')), findsOneWidget);
  });

  testWidgets('a piece landing sparkles over its slot (§22)', (tester) async {
    final game = await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(_slotCentre(tester, game, 0));
    await tester.pump();
    await gesture.up();
    // An animation's first tick happens *in* the frame that starts it, so
    // each stage needs its own pump: one to start the settle flight, one to
    // run it out (which is what sets the sparkles off), then one to land
    // mid-flourish.
    await tester.pump();
    await tester.pump(PuzzleConfig.snapSettleDuration);
    await tester.pump(const Duration(milliseconds: 120));

    expect(game.placedCount, 1);
    final sparkles = find.descendant(
      of: find.byType(FeedbackLayer),
      matching: find.byType(CustomPaint),
    );
    expect(sparkles, findsOneWidget);
    expect(
      find.byKey(const ValueKey('board-piece-0')),
      findsOneWidget,
      reason: 'the sparkles are over a piece that really did land',
    );

    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File(
        'build/placement_feedback.png',
      ).writeAsBytesSync(png!.buffer.asUint8List());
    });

    await tester.pumpAndSettle();
    expect(sparkles, findsNothing, reason: 'it clears itself (§22)');
  });

  testWidgets('solving every piece completes the puzzle', (tester) async {
    final game = await _pumpGame(tester);
    final pieces = [...game.pieces];

    for (final piece in pieces.take(pieces.length - 1)) {
      await _dragPieceTo(tester, piece.id, _slotCentre(tester, game, piece.id));
    }

    // The last piece is dropped with explicit pumps: settling it starts the
    // celebration, and pumping until everything is still would run straight
    // past the finished picture into the next puzzle (§23).
    final last = pieces.last;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-piece-${last.id}'))),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(_slotCentre(tester, game, last.id));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(PuzzleConfig.snapSettleDuration);
    await tester.pump(const Duration(milliseconds: 100));

    expect(game.isComplete, isTrue);
    expect(game.placedCount, 4);
    for (final piece in pieces) {
      expect(find.byKey(ValueKey('board-piece-${piece.id}')), findsOneWidget);
    }
    expect(find.byKey(const ValueKey('tray-piece-0')), findsNothing);
    expect(
      find.byKey(const ValueKey('celebration-overlay')),
      findsOneWidget,
      reason: 'the finished picture is celebrated (§23)',
    );

    // Leave a picture of a puzzle solved the way a child would solve it,
    // far enough into the celebration for the confetti to be in the air.
    // Frame by frame, because confetti emits per frame — one long pump
    // would jump the clock and emit almost nothing.
    for (var frame = 0; frame < 70; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/solved_2x2.png').writeAsBytesSync(png!.buffer.asUint8List());
    });

    // Let the celebration run out so nothing is left ticking.
    await tester.pump(PuzzleConfig.celebrationDuration);
    await tester.pump();
  });
}
