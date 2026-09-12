import 'dart:math' show Random;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

const _pathTolerance = 1e-3;
const _board = Size(500, 500);

void main() {
  group('render bleed (§14)', () {
    for (final grid in supportedGrids) {
      test('$grid: the render path grows by the bleed on every side', () {
        const bleed = PuzzleConfig.renderBleedPixels;
        final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
        final paths = PiecePaths.build(
          pieces: pieces,
          grid: grid,
          boardSize: _board,
        );

        for (final piece in pieces) {
          final exact = paths.of(piece.id).getBounds();
          final painted = paths.renderOf(piece.id).getBounds();
          final reason = 'piece ${piece.id}';

          // Grown outward on all four sides…
          expect(painted.left, lessThan(exact.left), reason: reason);
          expect(painted.top, lessThan(exact.top), reason: reason);
          expect(painted.right, greaterThan(exact.right), reason: reason);
          expect(painted.bottom, greaterThan(exact.bottom), reason: reason);

          // …by at least the bleed, and never by an unreasonable amount.
          // Tabs grow slightly more, because the scale is taken from the
          // cell; overlapping a neighbour more is harmless.
          expect(
            exact.left - painted.left,
            inInclusiveRange(bleed - _pathTolerance, 3 * bleed),
            reason: '$reason left growth',
          );
          expect(
            painted.right - exact.right,
            inInclusiveRange(bleed - _pathTolerance, 3 * bleed),
            reason: '$reason right growth',
          );
        }
      });
    }

    test('the exact path is untouched by the bleed', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final pieces = PuzzleGenerator(random: Random(1)).generate(grid);
      final cell = CoordinateMapper.cellSizeOf(grid, _board);
      final tab = CoordinateMapper.tabSizeOf(cell);

      final withBleed = PiecePaths.build(
        pieces: pieces,
        grid: grid,
        boardSize: _board,
      );
      final without = PiecePaths.build(
        pieces: pieces,
        grid: grid,
        boardSize: _board,
        bleed: 0,
      );

      for (final piece in pieces) {
        expect(
          withBleed.of(piece.id).getBounds().width,
          closeTo(without.of(piece.id).getBounds().width, _pathTolerance),
          reason: 'piece ${piece.id}',
        );
      }

      // bleed: 0 means painting and geometry are the same shape.
      expect(
        without.renderOf(0).getBounds().left,
        closeTo(without.of(0).getBounds().left, _pathTolerance),
      );
      // Sanity: the cell inset is still where §7 says.
      expect(without.of(0).getBounds().left, closeTo(tab, _pathTolerance));
    });

    test('unknown id throws for the render path too', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final paths = PiecePaths.build(
        pieces: PuzzleGenerator(random: Random(0)).generate(grid),
        grid: grid,
        boardSize: _board,
      );
      expect(() => paths.renderOf(99), throwsArgumentError);
      expect(identical(paths.renderOf(0), paths.renderOf(0)), isTrue);
    });
  });
}
