import 'dart:math' show Random;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/jigsaw_path_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

/// `Path.getBounds()` returns the control-point hull in 32-bit floats, so
/// comparisons need a looser tolerance than the pure-double geometry tests.
const _pathTolerance = 1e-3;

const _boardSizes = [Size(500, 500), Size(344, 344)];
const _seeds = [0, 1, 2];

void main() {
  group('piece path bounds', () {
    for (final grid in supportedGrids) {
      for (final board in _boardSizes) {
        test('$grid on $board: every side ends where its edge type says', () {
          final cell = CoordinateMapper.cellSizeOf(grid, board);
          final tab = CoordinateMapper.tabSizeOf(cell);
          final pieceSize = CoordinateMapper.pieceSizeOf(cell);

          for (final seed in _seeds) {
            final pieces = PuzzleGenerator(random: Random(seed)).generate(grid);
            for (final piece in pieces) {
              final bounds =
                  JigsawPathGenerator.build(piece: piece, cellSize: cell)
                      .getBounds();
              final reason = 'seed $seed piece ${piece.id}';

              // A tab reaches the bounding box; flat and blank stop at the
              // cell boundary. Nothing ever exceeds the box (§7).
              expect(
                bounds.left,
                closeTo(piece.left == EdgeType.tab ? 0.0 : tab, _pathTolerance),
                reason: '$reason left',
              );
              expect(
                bounds.top,
                closeTo(piece.top == EdgeType.tab ? 0.0 : tab, _pathTolerance),
                reason: '$reason top',
              );
              expect(
                bounds.right,
                closeTo(
                  piece.right == EdgeType.tab
                      ? pieceSize.width
                      : tab + cell.width,
                  _pathTolerance,
                ),
                reason: '$reason right',
              );
              expect(
                bounds.bottom,
                closeTo(
                  piece.bottom == EdgeType.tab
                      ? pieceSize.height
                      : tab + cell.height,
                  _pathTolerance,
                ),
                reason: '$reason bottom',
              );
            }
          }
        });
      }
    }

    test('1×1: an all-flat piece is exactly the inset cell rectangle', () {
      const grid = PuzzleGrid(rows: 1, columns: 1);
      const board = Size(500, 500);
      final cell = CoordinateMapper.cellSizeOf(grid, board);
      final tab = CoordinateMapper.tabSizeOf(cell);
      final piece = PuzzleGenerator(random: Random(0)).generate(grid).single;

      expect(piece.flatEdgeCount, 4);
      final bounds =
          JigsawPathGenerator.build(piece: piece, cellSize: cell).getBounds();
      expect(bounds.left, closeTo(tab, _pathTolerance));
      expect(bounds.top, closeTo(tab, _pathTolerance));
      expect(bounds.width, closeTo(cell.width, _pathTolerance));
      expect(bounds.height, closeTo(cell.height, _pathTolerance));
    });
  });

  group('piece path shape', () {
    test('contains the cell centre and excludes the box corners', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      const board = Size(500, 500);
      final cell = CoordinateMapper.cellSizeOf(grid, board);
      final tab = CoordinateMapper.tabSizeOf(cell);
      final pieceSize = CoordinateMapper.pieceSizeOf(cell);

      for (final piece in PuzzleGenerator(random: Random(5)).generate(grid)) {
        final path = JigsawPathGenerator.build(piece: piece, cellSize: cell);
        expect(
          path.contains(
            Offset(tab + cell.width / 2, tab + cell.height / 2),
          ),
          isTrue,
          reason: 'piece ${piece.id} centre',
        );
        // The box corners are always outside: knobs sit mid-edge.
        expect(path.contains(const Offset(0.5, 0.5)), isFalse);
        expect(
          path.contains(
            Offset(pieceSize.width - 0.5, pieceSize.height - 0.5),
          ),
          isFalse,
        );
      }
    });

    test('a tab protrudes and a blank bites in, at the edge midpoint', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      const board = Size(500, 500);
      final cell = CoordinateMapper.cellSizeOf(grid, board);
      final tab = CoordinateMapper.tabSizeOf(cell);

      for (final piece in PuzzleGenerator(random: Random(11)).generate(grid)) {
        final path = JigsawPathGenerator.build(piece: piece, cellSize: cell);
        // Just outside the right cell boundary, at mid height.
        final probe = Offset(tab + cell.width + tab / 2, tab + cell.height / 2);
        expect(
          path.contains(probe),
          piece.right == EdgeType.tab,
          reason: 'piece ${piece.id} right ${piece.right.name}',
        );
      }
    });
  });
}
