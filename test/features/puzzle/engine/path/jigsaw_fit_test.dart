import 'dart:math' show Random;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Do the generated pieces actually tile the board?
///
/// Every sampled point inside the board must be covered by exactly one
/// piece: zero would be a hole (a visible seam), two would be an overlap.
/// This is the geometric proof that tabs and blanks are complementary —
/// §11 only guarantees it at the level of edge *types*.

const _board = Size(300, 300);

/// Deliberately not a divisor of the board: samples must not land exactly
/// on a cell boundary, where `Path.contains` is ambiguous.
const _sampleStep = 5.1;
const _sampleStart = 1.3;

void main() {
  const grids = [
    PuzzleGrid(rows: 2, columns: 2),
    PuzzleGrid(rows: 2, columns: 3),
    PuzzleGrid(rows: 3, columns: 3),
  ];

  for (final grid in grids) {
    for (final seed in [0, 1]) {
      test('$grid seed $seed: pieces tile the board exactly once', () {
        final pieces = PuzzleGenerator(random: Random(seed)).generate(grid);
        final paths = PiecePaths.build(
          pieces: pieces,
          grid: grid,
          boardSize: _board,
        );

        // Move every path from piece-local into board space.
        final boardPaths = [
          for (final piece in pieces)
            paths.of(piece.id).shift(
                  CoordinateMapper.pieceOriginOf(
                    normalizedPosition: piece.normalizedPosition,
                    grid: grid,
                    boardSize: _board,
                  ),
                ),
        ];

        final holes = <Offset>[];
        final overlaps = <Offset>[];

        for (var x = _sampleStart; x < _board.width; x += _sampleStep) {
          for (var y = _sampleStart; y < _board.height; y += _sampleStep) {
            final point = Offset(x, y);
            final covers = boardPaths.where((p) => p.contains(point)).length;
            if (covers == 0) holes.add(point);
            if (covers > 1) overlaps.add(point);
          }
        }

        expect(holes, isEmpty, reason: 'uncovered points');
        expect(overlaps, isEmpty, reason: 'points covered by 2+ pieces');
      });
    }
  }
}
