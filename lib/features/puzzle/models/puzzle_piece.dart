import 'dart:ui' show Offset;

import 'edge_type.dart';

/// Immutable domain description of a single jigsaw piece (§12).
///
/// Runtime concerns (drag position, tray slot, attempts) live elsewhere
/// and are introduced in Faz 4.
class PuzzlePiece {
  const PuzzlePiece({
    required this.id,
    required this.row,
    required this.column,
    required this.top,
    required this.right,
    required this.bottom,
    required this.left,
    required this.normalizedPosition,
  })  : assert(id >= 0, 'id must be non-negative'),
        assert(row >= 0, 'row must be non-negative'),
        assert(column >= 0, 'column must be non-negative');

  /// `row * columns + column` (§8.6).
  final int id;
  final int row;
  final int column;

  final EdgeType top;
  final EdgeType right;
  final EdgeType bottom;
  final EdgeType left;

  /// Top-left corner of the piece's *cell* in normalized board space (§8.5).
  ///
  /// Does not include tab overflow, so it is always in `[0.0, 1.0)`.
  /// The piece path's own top-left is this minus `(tabSize, tabSize)`.
  final Offset normalizedPosition;

  /// Number of flat sides; drives hint target selection (§21.1).
  int get flatEdgeCount =>
      [top, right, bottom, left].where((e) => e == EdgeType.flat).length;

  @override
  bool operator ==(Object other) =>
      other is PuzzlePiece &&
      other.id == id &&
      other.row == row &&
      other.column == column &&
      other.top == top &&
      other.right == right &&
      other.bottom == bottom &&
      other.left == left &&
      other.normalizedPosition == normalizedPosition;

  @override
  int get hashCode => Object.hash(
        id,
        row,
        column,
        top,
        right,
        bottom,
        left,
        normalizedPosition,
      );

  @override
  String toString() => 'PuzzlePiece(#$id r$row c$column '
      't:${top.name} r:${right.name} b:${bottom.name} l:${left.name})';
}
