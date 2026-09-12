import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/edge_resolver.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

/// §41 — statistical determinism check parameters.
const _statisticalSeedCount = 50;
const _minUniqueLayouts = 40;

String _layoutSignature(List<PuzzlePiece> pieces) => pieces
    .map(
        (p) => '${p.top.index}${p.right.index}${p.bottom.index}${p.left.index}')
    .join('|');

void main() {
  group('piece count', () {
    const expected = [
      (PuzzleGrid(rows: 1, columns: 3), 3),
      (PuzzleGrid(rows: 2, columns: 2), 4),
      (PuzzleGrid(rows: 2, columns: 3), 6),
      (PuzzleGrid(rows: 3, columns: 3), 9),
      (PuzzleGrid(rows: 3, columns: 4), 12),
    ];

    for (final (grid, count) in expected) {
      test('$grid → $count pieces', () {
        expect(PuzzleGenerator(random: Random(0)).generate(grid),
            hasLength(count));
      });
    }
  });

  for (final grid in supportedGrids) {
    group('PuzzleGenerator $grid', () {
      final pieces = PuzzleGenerator(random: Random(7)).generate(grid);

      test('id == row * columns + column', () {
        for (final p in pieces) {
          expect(p.id, p.row * grid.columns + p.column);
        }
      });

      test('ids are 0..n-1, gap-free, unique, in list order', () {
        expect(
          pieces.map((p) => p.id).toList(),
          List.generate(grid.pieceCount, (i) => i),
        );
      });

      test('every cell appears exactly once', () {
        final cells = pieces.map((p) => (p.row, p.column)).toSet();
        expect(cells, hasLength(grid.pieceCount));
        for (final (row, column) in cells) {
          expect(row, inInclusiveRange(0, grid.rows - 1));
          expect(column, inInclusiveRange(0, grid.columns - 1));
        }
      });

      test('normalizedPosition ∈ [0, 1) and is the cell top-left', () {
        for (final p in pieces) {
          final pos = p.normalizedPosition;
          expect(pos.dx, greaterThanOrEqualTo(0.0));
          expect(pos.dx, lessThan(1.0));
          expect(pos.dy, greaterThanOrEqualTo(0.0));
          expect(pos.dy, lessThan(1.0));
          expectOffsetClose(
            pos,
            Offset(p.column / grid.columns, p.row / grid.rows),
          );
        }
      });

      test('edges match EdgeResolver for the same seed', () {
        final edges = EdgeResolver.resolve(grid, Random(7));
        for (final p in pieces) {
          expect(
            (top: p.top, right: p.right, bottom: p.bottom, left: p.left),
            edges[p.id],
          );
        }
      });

      test('returned list is unmodifiable', () {
        expect(() => pieces.removeLast(), throwsUnsupportedError);
      });
    });
  }

  group('determinism', () {
    test('same seed → identical piece list', () {
      for (final grid in supportedGrids) {
        final a = PuzzleGenerator(random: Random(42)).generate(grid);
        final b = PuzzleGenerator(random: Random(42)).generate(grid);
        expect(a, equals(b), reason: '$grid');
      }
    });

    test(
      '3×3: $_statisticalSeedCount seeds → ≥ $_minUniqueLayouts unique layouts',
      () {
        const grid = PuzzleGrid(rows: 3, columns: 3);
        final layouts = {
          for (var seed = 0; seed < _statisticalSeedCount; seed++)
            _layoutSignature(
                PuzzleGenerator(random: Random(seed)).generate(grid)),
        };
        expect(layouts.length, greaterThanOrEqualTo(_minUniqueLayouts));
      },
    );

    test('works without an injected Random', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      expect(PuzzleGenerator().generate(grid), hasLength(grid.pieceCount));
    });
  });
}
