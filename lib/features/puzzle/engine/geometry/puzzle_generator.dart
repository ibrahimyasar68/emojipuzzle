import 'dart:math' show Random;

import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';
import 'edge_resolver.dart';

/// Builds the immutable piece list for a grid (§5).
///
/// Randomness is injected so tests can pin it with `Random(seed)`.
class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Returns one piece per cell, ordered by id (row-major, §8.6).
  ///
  /// The returned list is unmodifiable.
  List<PuzzlePiece> generate(PuzzleGrid grid) {
    final edges = EdgeResolver.resolve(grid, _random);

    return List.unmodifiable([
      for (var row = 0; row < grid.rows; row++)
        for (var column = 0; column < grid.columns; column++)
          _pieceAt(grid, row, column, edges[grid.idOf(row, column)]),
    ]);
  }

  PuzzlePiece _pieceAt(
    PuzzleGrid grid,
    int row,
    int column,
    PieceEdges edges,
  ) {
    return PuzzlePiece(
      id: grid.idOf(row, column),
      row: row,
      column: column,
      top: edges.top,
      right: edges.right,
      bottom: edges.bottom,
      left: edges.left,
      normalizedPosition: CoordinateMapper.normalizedCellOrigin(
        grid,
        row,
        column,
      ),
    );
  }
}
