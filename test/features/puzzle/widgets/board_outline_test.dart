import 'dart:math' show Random;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
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
  PiecePaths paths,
  Set<int> filledPieceIds,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BoardGhostPainter(
    image: image,
    grid: const PuzzleGrid(rows: 2, columns: 2),
    outlineColour: AppPalette.light.slotOutline,
    slotOutlines: paths.dashedSlots,
    filledPieceIds: filledPieceIds,
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

Future<ByteData> _render(
  ui.Image image,
  Map<int, Path> slotOutlines,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  BoardGhostPainter(
    image: image,
    grid: const PuzzleGrid(rows: 2, columns: 2),
    outlineColour: AppPalette.light.slotOutline,
    slotOutlines: slotOutlines,
  ).paint(canvas, _boardSize);

  final painted = await recorder.endRecording().toImage(
        _boardSize.width.round(),
        _boardSize.height.round(),
      );
  return (await painted.toByteData())!;
}

/// The longest unbroken run of *outline* pixels down a vertical line.
///
/// The ghost picture covers the whole board at a quarter opacity, so a
/// pixel being painted proves nothing. The board is rendered twice, with
/// the outlines and without, and only the pixels that differ are dashes.
Future<int> _longestRunDown(ui.Image image, PiecePaths paths, double x) async {
  final withOutlines = await _render(image, paths.dashedSlots);
  final without = await _render(image, const {});

  final column = x.round();
  var longest = 0;
  var run = 0;
  for (var y = 0; y < _boardSize.height.round(); y++) {
    final offset = (y * _boardSize.width.round() + column) * 4;
    var differs = false;
    for (var channel = 0; channel < 4; channel++) {
      if ((withOutlines.getUint8(offset + channel) -
                  without.getUint8(offset + channel))
              .abs() >
          8) {
        differs = true;
        break;
      }
    }
    if (differs) {
      run++;
      if (run > longest) longest = run;
    } else {
      run = 0;
    }
  }
  return longest;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('a shared seam stays dashed, it does not go solid (§15)', (
    tester,
  ) async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('cat_01')),
    );
    final paths = PiecePaths.build(
      pieces: game.pieces,
      grid: game.grid,
      boardSize: _boardSize,
    );

    await tester.runAsync(() async {
      // The line down the middle belongs to both columns: the left pieces
      // draw it as their right edge, the right pieces as their left. If the
      // two sides walk it differently their dashes interleave and fill each
      // other's gaps, and the seam comes out as one solid line.
      final run = await _longestRunDown(
        game.image!,
        paths,
        _boardSize.width / 2,
      );

      expect(
        run,
        lessThan((PuzzleConfig.slotOutlineDashLength * 3).round()),
        reason: 'the middle seam ran solid for $run px',
      );
      expect(run, greaterThan(0), reason: 'there is a seam there at all');
    });
  });

  testWidgets('a filled slot stops asking to be filled (§15)', (tester) async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('cat_01')),
    );

    final paths = PiecePaths.build(
      pieces: game.pieces,
      grid: game.grid,
      boardSize: _boardSize,
    );

    await tester.runAsync(() async {
      final empty = await _outlinePixels(game.image!, paths, const {});
      final half = await _outlinePixels(game.image!, paths, const {0, 1});
      final full = await _outlinePixels(
        game.image!,
        paths,
        const {0, 1, 2, 3},
      );

      // Every cell outlined, then two, then none. The ghost picture behind
      // them is the same in all three, so what changes is the dashes.
      expect(half, lessThan(empty), reason: 'two slots went quiet');
      expect(full, lessThan(half), reason: 'the rest went quiet too');
    });
  });
}
