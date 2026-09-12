import 'dart:math' show Random;

import '../../models/edge_type.dart';
import '../../models/puzzle_grid.dart';

/// The four sides of one cell, as produced by [EdgeResolver].
typedef PieceEdges = ({
  EdgeType top,
  EdgeType right,
  EdgeType bottom,
  EdgeType left,
});

/// Assigns edge shapes to every cell of a grid (§11).
abstract final class EdgeResolver {
  /// Returns edges for every cell, indexed by piece id (§8.6).
  ///
  /// Cells are visited row by row, left to right. `top` and `left` are
  /// inherited from already-visited neighbours as their complement;
  /// `right` and `bottom` are drawn from [random]. Board borders are flat.
  ///
  /// The draw order (right, then bottom, per cell) is part of the
  /// determinism contract: the same seed always yields the same puzzle.
  static List<PieceEdges> resolve(PuzzleGrid grid, Random random) {
    final edges = <PieceEdges>[];

    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        final top = row == 0
            ? EdgeType.flat
            : edges[grid.idOf(row - 1, column)].bottom.complement;
        final left = column == 0
            ? EdgeType.flat
            : edges[grid.idOf(row, column - 1)].right.complement;
        final right =
            column == grid.columns - 1 ? EdgeType.flat : _randomInner(random);
        final bottom =
            row == grid.rows - 1 ? EdgeType.flat : _randomInner(random);

        edges.add((top: top, right: right, bottom: bottom, left: left));
      }
    }

    return List.unmodifiable(edges);
  }

  static EdgeType _randomInner(Random random) =>
      random.nextBool() ? EdgeType.tab : EdgeType.blank;
}
