import 'dart:ui' show Offset;

import 'edge_type.dart';

/// Tek bir yapboz parçasının değişmez alan tanımı (§12).
///
/// Çalışma anına ait bilgiler (sürükleme konumu, tepsi yuvası, deneme
/// sayısı) başka yerde tutulur ve Faz 4'te eklenir.
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

  /// Parçanın *hücresinin* sol üst köşesi, normalize board uzayında (§8.5).
  ///
  /// Tırnak taşmasını içermez, bu yüzden her zaman `[0.0, 1.0)` aralığındadır.
  /// Parça path'inin kendi sol üstü, bundan `(tabSize, tabSize)` çıkarılmış
  /// halidir.
  final Offset normalizedPosition;

  /// Düz kenar sayısı; ipucu hedefinin seçiminde kullanılır (§21.1).
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
