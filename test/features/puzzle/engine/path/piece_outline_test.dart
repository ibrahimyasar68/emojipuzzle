import 'dart:math' show Random;
import 'dart:ui' show Offset, Path, Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

const _pathTolerance = 1e-3;
const _board = Size(500, 500);

/// The topmost y at which [path] is filled on the vertical line `x`, found
/// by bisection. Returns [double.nan] when the column is empty.
double _topBoundaryAt(Path path, double x, double height) {
  var outside = -height;
  var inside = double.nan;
  for (var y = -height; y <= height * 2; y += 0.5) {
    if (path.contains(Offset(x, y))) {
      inside = y;
      break;
    }
    outside = y;
  }
  if (inside.isNaN) return double.nan;

  for (var i = 0; i < 40; i++) {
    final middle = (outside + inside) / 2;
    if (path.contains(Offset(x, middle))) {
      inside = middle;
    } else {
      outside = middle;
    }
  }
  return inside;
}

void main() {
  group('the outline a piece is painted with (§14)', () {
    for (final grid in supportedGrids) {
      test('$grid: painting and geometry use the same path', () {
        final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
        final paths = PiecePaths.build(
          pieces: pieces,
          grid: grid,
          boardSize: _board,
        );

        // There used to be a second, grown copy of every outline here, so
        // that neighbours overlapped and no hairline showed between them.
        // Growing these curves with boolean path operations did not work:
        // the result was a different shape whose bounding box looked right.
        // The bleed lives in the painter now, as a stroke.
        for (final piece in pieces) {
          expect(
            identical(paths.of(piece.id), paths.of(piece.id)),
            isTrue,
            reason: '$grid piece ${piece.id}: cached, not rebuilt',
          );
        }
      });
    }

    test('the outline is not reshaped anywhere along a flat edge', () {
      // The bug this pins cut a long diagonal across the top-left corner of
      // every piece whose top edge carried a tab. The bounding box was
      // right throughout, so bounds alone said nothing.
      const cell = Size(200, 200);
      final tab = CoordinateMapper.tabSizeOf(cell);

      for (final top in EdgeType.values) {
        for (final left in EdgeType.values) {
          final piece = PuzzlePiece(
            id: 0,
            row: 1,
            column: 1,
            top: top,
            right: EdgeType.flat,
            bottom: EdgeType.flat,
            left: left,
            normalizedPosition: const Offset(0.5, 0.5),
          );
          final paths = PiecePaths.build(
            pieces: [piece],
            grid: const PuzzleGrid(rows: 2, columns: 2),
            boardSize: Size(cell.width * 2, cell.height * 2),
          );
          final outline = paths.of(piece.id);

          // Walk the flat run of the top edge, left of where any knob can
          // reach (the knob lives between u = 0.27 and u = 0.73).
          for (final u in [0.04, 0.08, 0.12, 0.16, 0.20]) {
            final x = tab + u * cell.width;
            final edge = _topBoundaryAt(outline, x, cell.height);
            expect(
              edge,
              closeTo(tab, 0.1),
              reason: 'top=$top left=$left, u=$u: the top edge should sit on '
                  'the cell edge, not at $edge',
            );
          }
        }
      }
    });

    test('the cell still starts a tab in from the corner (§7)', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final pieces = PuzzleGenerator(random: Random(1)).generate(grid);
      final cell = CoordinateMapper.cellSizeOf(grid, _board);
      final tab = CoordinateMapper.tabSizeOf(cell);
      final paths = PiecePaths.build(
        pieces: pieces,
        grid: grid,
        boardSize: _board,
      );

      expect(paths.of(0).getBounds().left, closeTo(tab, _pathTolerance));
    });

    test('unknown id throws', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final paths = PiecePaths.build(
        pieces: PuzzleGenerator(random: Random(0)).generate(grid),
        grid: grid,
        boardSize: _board,
      );
      expect(() => paths.of(99), throwsArgumentError);
    });
  });
}
