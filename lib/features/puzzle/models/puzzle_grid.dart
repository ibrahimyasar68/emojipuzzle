/// Grid dimensions of a puzzle (§13).
///
/// Any `rows × columns` combination is supported by the engine; which grids
/// actually ship is a content decision (§4).
class PuzzleGrid {
  const PuzzleGrid({required this.rows, required this.columns})
      : assert(rows > 0, 'rows must be positive'),
        assert(columns > 0, 'columns must be positive');

  final int rows;
  final int columns;

  int get pieceCount => rows * columns;

  /// Piece id contract (§8.6): row-major, `0 .. pieceCount - 1`, gap-free.
  int idOf(int row, int column) {
    assert(row >= 0 && row < rows, 'row $row out of range 0..${rows - 1}');
    assert(
      column >= 0 && column < columns,
      'column $column out of range 0..${columns - 1}',
    );
    return row * columns + column;
  }

  @override
  bool operator ==(Object other) =>
      other is PuzzleGrid && other.rows == rows && other.columns == columns;

  @override
  int get hashCode => Object.hash(rows, columns);

  @override
  String toString() => 'PuzzleGrid(${rows}x$columns)';
}
