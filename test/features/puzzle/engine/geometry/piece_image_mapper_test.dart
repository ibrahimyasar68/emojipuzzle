import 'dart:math' show Random;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/piece_image_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

const _tolerance = 1e-9;

/// (board, source image) pairs: both square, different scales (§6.1, §34).
const _boardAndImage = [
  (Size(500, 500), Size(1024, 1024)),
  (Size(344, 344), Size(512, 512)),
];

void main() {
  group('src/dst contract', () {
    for (final grid in supportedGrids) {
      for (final (board, image) in _boardAndImage) {
        test('$grid, board $board, image $image', () {
          final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
          final cell = CoordinateMapper.cellSizeOf(grid, board);
          final pieceSize = CoordinateMapper.pieceSizeOf(cell);
          final scale = image.width / board.width;

          for (final piece in pieces) {
            final rects = PieceImageMapper.rectsOf(
              piece: piece,
              grid: grid,
              boardSize: board,
              imageSize: image,
            );
            final reason = 'piece ${piece.id}';

            // src never leaves the source image (§14).
            expect(rects.src.left, greaterThanOrEqualTo(-_tolerance),
                reason: reason);
            expect(rects.src.top, greaterThanOrEqualTo(-_tolerance),
                reason: reason);
            expect(rects.src.right, lessThanOrEqualTo(image.width + _tolerance),
                reason: reason);
            expect(
                rects.src.bottom, lessThanOrEqualTo(image.height + _tolerance),
                reason: reason);

            // dst stays inside the piece bounding box.
            expect(rects.dst.left, greaterThanOrEqualTo(-_tolerance),
                reason: reason);
            expect(rects.dst.top, greaterThanOrEqualTo(-_tolerance),
                reason: reason);
            expect(rects.dst.right,
                lessThanOrEqualTo(pieceSize.width + _tolerance),
                reason: reason);
            expect(rects.dst.bottom,
                lessThanOrEqualTo(pieceSize.height + _tolerance),
                reason: reason);

            // No stretching: one scale for both axes, on both rects.
            expect(rects.src.width / rects.dst.width, closeTo(scale, 1e-6),
                reason: reason);
            expect(rects.src.height / rects.dst.height, closeTo(scale, 1e-6),
                reason: reason);
          }
        });
      }
    }
  });

  test('interior piece needs no clamping: dst is the whole piece box', () {
    const grid = PuzzleGrid(rows: 3, columns: 3);
    const board = Size(500, 500);
    const image = Size(1024, 1024);
    final centre = PuzzleGenerator(random: Random(0)).generate(grid)[4];
    final cell = CoordinateMapper.cellSizeOf(grid, board);
    final pieceSize = CoordinateMapper.pieceSizeOf(cell);

    final rects = PieceImageMapper.rectsOf(
      piece: centre,
      grid: grid,
      boardSize: board,
      imageSize: image,
    );

    expect(rects.dst.left, closeTo(0, _tolerance));
    expect(rects.dst.top, closeTo(0, _tolerance));
    expect(rects.dst.width, closeTo(pieceSize.width, _tolerance));
    expect(rects.dst.height, closeTo(pieceSize.height, _tolerance));
  });

  test('corner piece is clamped by exactly the tab overflow', () {
    const grid = PuzzleGrid(rows: 3, columns: 3);
    const board = Size(500, 500);
    const image = Size(1024, 1024);
    final corner = PuzzleGenerator(random: Random(0)).generate(grid).first;
    final cell = CoordinateMapper.cellSizeOf(grid, board);
    final tab = CoordinateMapper.tabSizeOf(cell);

    final rects = PieceImageMapper.rectsOf(
      piece: corner,
      grid: grid,
      boardSize: board,
      imageSize: image,
    );

    // The top-left overflow has no image behind it…
    expect(rects.src.left, closeTo(0, _tolerance));
    expect(rects.src.top, closeTo(0, _tolerance));
    // …so dst starts one tab in, instead of stretching the picture.
    expect(rects.dst.left, closeTo(tab, _tolerance));
    expect(rects.dst.top, closeTo(tab, _tolerance));
  });

  test('the cell origin lands on the right pixel of the source image', () {
    const grid = PuzzleGrid(rows: 2, columns: 3);
    const board = Size(500, 500);
    const image = Size(1024, 1024);
    final cell = CoordinateMapper.cellSizeOf(grid, board);
    final tab = CoordinateMapper.tabSizeOf(cell);

    for (final piece in PuzzleGenerator(random: Random(2)).generate(grid)) {
      final rects = PieceImageMapper.rectsOf(
        piece: piece,
        grid: grid,
        boardSize: board,
        imageSize: image,
      );
      final scaleX = rects.src.width / rects.dst.width;
      final scaleY = rects.src.height / rects.dst.height;

      // Map the piece-local cell origin (tab, tab) through dst → src.
      final sourceX = rects.src.left + (tab - rects.dst.left) * scaleX;
      final sourceY = rects.src.top + (tab - rects.dst.top) * scaleY;

      expect(
        sourceX,
        closeTo(piece.normalizedPosition.dx * image.width, 1e-6),
        reason: 'piece ${piece.id} x',
      );
      expect(
        sourceY,
        closeTo(piece.normalizedPosition.dy * image.height, 1e-6),
        reason: 'piece ${piece.id} y',
      );
    }
  });

  test('mismatched aspect ratios are rejected', () {
    const grid = PuzzleGrid(rows: 2, columns: 2);
    final piece = PuzzleGenerator(random: Random(0)).generate(grid).first;
    expect(
      () => PieceImageMapper.rectsOf(
        piece: piece,
        grid: grid,
        boardSize: const Size(500, 500),
        imageSize: const Size(1024, 512),
      ),
      throwsA(isA<AssertionError>()),
    );
  });
}
