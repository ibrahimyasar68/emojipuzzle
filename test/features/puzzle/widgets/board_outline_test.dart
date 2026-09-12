import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/board_ghost_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _boardSize = Size(300, 300);

/// Paints the ghost layer alone and counts the pixels the dashes darken.
Future<int> _outlinePixels(
  ui.Image image,
  Set<int> filledCells,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BoardGhostPainter(
    image: image,
    grid: const PuzzleGrid(rows: 2, columns: 2),
    filledCells: filledCells,
  ).paint(canvas, _boardSize);

  final painted = await recorder.endRecording().toImage(
        _boardSize.width.round(),
        _boardSize.height.round(),
      );
  final data = await painted.toByteData();
  var marked = 0;
  for (var i = 3; i < data!.lengthInBytes; i += 4) {
    if (data.getUint8(i) > 0) marked++;
  }
  return marked;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a filled slot stops asking to be filled (§15)', (tester) async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('cat_01')),
    );

    await tester.runAsync(() async {
      final empty = await _outlinePixels(game.image!, const {});
      final half = await _outlinePixels(game.image!, const {0, 1});
      final full = await _outlinePixels(game.image!, const {0, 1, 2, 3});

      // Every cell outlined, then two, then none. The ghost picture behind
      // them is the same in all three, so what changes is the dashes.
      expect(half, lessThan(empty), reason: 'two slots went quiet');
      expect(full, lessThan(half), reason: 'the rest went quiet too');
    });
  });
}
