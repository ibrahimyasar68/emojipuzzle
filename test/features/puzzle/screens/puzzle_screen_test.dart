import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_definition.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/board_ghost_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Wraps the screen so a test can rasterise what the child would see.
final _screenKey = GlobalKey();

/// §2, §16.1 — the small phone is where the touch target is decided.
const _referencePhone = Size(360, 640);

Future<GameProvider> _started(
  WidgetTester tester,
  PuzzleDefinition puzzle, {
  PuzzleGrid? grid,
}) async {
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  await tester.runAsync(() => game.startPuzzle(puzzle, grid: grid));
  return game;
}

Future<void> _pumpScreen(WidgetTester tester, GameProvider game) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: _screenKey, child: const PuzzleScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('on a 360×640 phone', () {
    // Every stage of a game, from 4 pieces to 16 (K-15).
    for (final grid in GameRules.stageGrids) {
      testWidgets('${grid.rows}x${grid.columns}: every tray piece clears 64 px',
          (tester) async {
        tester.view.physicalSize = _referencePhone;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final game = await _started(
          tester,
          PuzzleCatalog.v1.byId('apple_01'),
          grid: grid,
        );
        addTearDown(game.dispose);
        await _pumpScreen(tester, game);

        for (final piece in game.pieces) {
          final size = tester.getSize(
            find.byKey(ValueKey('tray-piece-${piece.id}')),
          );
          expect(
            size.width,
            greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
            reason: 'piece ${piece.id} width',
          );
          expect(
            size.height,
            greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
            reason: 'piece ${piece.id} height',
          );
        }
      });
    }

    testWidgets('board and tray share the screen without overflow', (
      tester,
    ) async {
      tester.view.physicalSize = _referencePhone;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = await _started(tester, PuzzleCatalog.v1.byId('car_01'));
      addTearDown(game.dispose);
      await _pumpScreen(tester, game);

      expect(tester.takeException(), isNull);
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is CustomPaint && widget.painter is BoardGhostPainter,
        ),
        findsOneWidget,
        reason: 'the empty board shows the ghost and its slot outlines (§15)',
      );

      // Leave a picture of the screen behind, the way Faz 3 does for the
      // assembled board.
      game.markPlaced(game.pieces.first.id);
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        final boundary = _screenKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final png = await image.toByteData(format: ui.ImageByteFormat.png);
        Directory('build').createSync(recursive: true);
        File(
          'build/screen_3x3.png',
        ).writeAsBytesSync(png!.buffer.asUint8List());
      });
    });
  });

  testWidgets('a placed piece moves from the tray to the board', (
    tester,
  ) async {
    tester.view.physicalSize = _referencePhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = await _started(tester, PuzzleCatalog.v1.byId('apple_01'));
    addTearDown(game.dispose);
    await _pumpScreen(tester, game);

    expect(find.byKey(const ValueKey('tray-piece-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('board-piece-0')), findsNothing);

    game.markPlaced(0);
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('tray-piece-0')), findsNothing);
    expect(find.byKey(const ValueKey('board-piece-0')), findsOneWidget);
    // The other three stay exactly where they were (§16.2).
    for (final id in [1, 2, 3]) {
      expect(find.byKey(ValueKey('tray-piece-$id')), findsOneWidget);
    }
  });

  testWidgets('an empty slot is not reused by another piece', (tester) async {
    tester.view.physicalSize = _referencePhone;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = await _started(tester, PuzzleCatalog.v1.byId('apple_01'));
    addTearDown(game.dispose);
    await _pumpScreen(tester, game);

    final before = {
      for (final piece in game.pieces)
        piece.id: tester.getTopLeft(
          find.byKey(ValueKey('tray-piece-${piece.id}')),
        ),
    };

    game.markPlaced(0);
    await tester.pumpAndSettle();

    for (final id in [1, 2, 3]) {
      expect(
        tester.getTopLeft(find.byKey(ValueKey('tray-piece-$id'))),
        before[id],
        reason: 'piece $id must not reflow when another piece leaves',
      );
    }
  });
}
