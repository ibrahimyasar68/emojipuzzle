import 'dart:math' show Random;

import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';
import 'edge_resolver.dart';

/// Bir grid için değişmez parça listesini kurar (§5).
///
/// Rastgelelik dışarıdan verilir; böylece testler `Random(seed)` ile
/// sonucu sabitleyebilir.
class PuzzleGenerator {
  PuzzleGenerator({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Hücre başına bir parça döndürür, kimliğe göre sıralı (satır öncelikli,
  /// §8.6).
  ///
  /// Dönen liste değiştirilemez.
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
