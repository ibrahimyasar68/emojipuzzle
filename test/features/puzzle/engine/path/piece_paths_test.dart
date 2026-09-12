import 'dart:math' show Random;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

void main() {
  const board = Size(500, 500);

  for (final grid in supportedGrids) {
    test('$grid: one cached path per piece', () {
      final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
      final paths = PiecePaths.build(
        pieces: pieces,
        grid: grid,
        boardSize: board,
      );

      expect(paths.length, grid.pieceCount);
      for (final piece in pieces) {
        expect(paths.of(piece.id).getBounds().isEmpty, isFalse);
      }
    });
  }

  test('the same id always returns the identical cached Path object', () {
    const grid = PuzzleGrid(rows: 2, columns: 2);
    final paths = PiecePaths.build(
      pieces: PuzzleGenerator(random: Random(0)).generate(grid),
      grid: grid,
      boardSize: board,
    );
    expect(identical(paths.of(0), paths.of(0)), isTrue);
  });

  test('unknown id throws instead of returning null', () {
    const grid = PuzzleGrid(rows: 2, columns: 2);
    final paths = PiecePaths.build(
      pieces: PuzzleGenerator(random: Random(0)).generate(grid),
      grid: grid,
      boardSize: board,
    );
    expect(() => paths.of(99), throwsArgumentError);
  });

  test('cache validity is tied to the board size', () {
    const grid = PuzzleGrid(rows: 2, columns: 2);
    final paths = PiecePaths.build(
      pieces: PuzzleGenerator(random: Random(0)).generate(grid),
      grid: grid,
      boardSize: board,
    );

    expect(paths.boardSize, board);
    expect(paths.matches(board), isTrue);
    expect(paths.matches(const Size(344, 344)), isFalse);
  });

  test('a smaller board produces proportionally smaller paths', () {
    const grid = PuzzleGrid(rows: 2, columns: 2);
    final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
    final big = PiecePaths.build(pieces: pieces, grid: grid, boardSize: board);
    final small = PiecePaths.build(
      pieces: pieces,
      grid: grid,
      boardSize: const Size(250, 250),
    );

    expect(
      small.of(0).getBounds().width,
      closeTo(big.of(0).getBounds().width / 2, 1e-3),
    );
  });
}
