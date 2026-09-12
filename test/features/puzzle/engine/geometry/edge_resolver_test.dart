import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/edge_resolver.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

const _seedsPerGrid = 20;

void main() {
  for (final grid in supportedGrids) {
    group('EdgeResolver $grid', () {
      for (var seed = 0; seed < _seedsPerGrid; seed++) {
        final edges = EdgeResolver.resolve(grid, Random(seed));
        PieceEdges at(int row, int column) => edges[grid.idOf(row, column)];

        test('seed $seed: one entry per cell', () {
          expect(edges, hasLength(grid.pieceCount));
        });

        test('seed $seed: outer border is flat', () {
          for (var c = 0; c < grid.columns; c++) {
            expect(at(0, c).top, EdgeType.flat);
            expect(at(grid.rows - 1, c).bottom, EdgeType.flat);
          }
          for (var r = 0; r < grid.rows; r++) {
            expect(at(r, 0).left, EdgeType.flat);
            expect(at(r, grid.columns - 1).right, EdgeType.flat);
          }
        });

        test('seed $seed: horizontal neighbours are complementary', () {
          for (var r = 0; r < grid.rows; r++) {
            for (var c = 0; c < grid.columns - 1; c++) {
              final right = at(r, c).right;
              expect(right, isNot(EdgeType.flat), reason: 'inner edge');
              expect(at(r, c + 1).left, right.complement);
            }
          }
        });

        test('seed $seed: vertical neighbours are complementary', () {
          for (var r = 0; r < grid.rows - 1; r++) {
            for (var c = 0; c < grid.columns; c++) {
              final bottom = at(r, c).bottom;
              expect(bottom, isNot(EdgeType.flat), reason: 'inner edge');
              expect(at(r + 1, c).top, bottom.complement);
            }
          }
        });
      }
    });
  }

  test('1×3: every top and bottom is flat', () {
    const grid = PuzzleGrid(rows: 1, columns: 3);
    for (var seed = 0; seed < _seedsPerGrid; seed++) {
      for (final e in EdgeResolver.resolve(grid, Random(seed))) {
        expect(e.top, EdgeType.flat);
        expect(e.bottom, EdgeType.flat);
      }
    }
  });

  test('result is unmodifiable', () {
    final edges = EdgeResolver.resolve(
      const PuzzleGrid(rows: 2, columns: 2),
      Random(0),
    );
    expect(() => edges.removeLast(), throwsUnsupportedError);
  });
}
