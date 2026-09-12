import 'dart:ui' show Color, Rect;

import '../models/puzzle_category.dart';

/// The surface a puzzle's pieces are painted on, in piece-local coordinates.
class PieceBackground {
  const PieceBackground({
    required this.from,
    required this.to,
    required this.boardRect,
  });

  final Color from;
  final Color to;

  /// Where the whole board sits in this piece's own coordinates, so the
  /// gradient is laid out once across the board rather than restarting in
  /// every piece.
  final Rect boardRect;

  @override
  bool operator ==(Object other) =>
      other is PieceBackground &&
      other.from == from &&
      other.to == to &&
      other.boardRect == boardRect;

  @override
  int get hashCode => Object.hash(from, to, boardRect);
}

/// Colours the pieces sit on.
///
/// The artwork is transparent by design (§34), and a transparent jigsaw
/// piece is one a child can neither see in the tray nor aim at. The picture
/// is therefore composed at runtime: this surface first, the emoji on top.
/// The asset files stay untouched, which also keeps the licence simple
/// (§33).
///
/// The surface is a gradient across the board, not a flat fill, and that is
/// the point: an emoji leaves whole pieces empty — the corners of a 3×3 car
/// hold no car at all — and nine identical blank tiles are nine tiles a
/// child cannot tell apart. A gradient gives every piece its own shade, and
/// still assembles into one clean picture.
abstract final class PuzzlePalette {
  static const _fallback = (Color(0xFFFDF7EF), Color(0xFFF3E4D0));

  static const _byCategory = <PuzzleCategory, (Color, Color)>{
    PuzzleCategory.fruits: (Color(0xFFFFF6E3), Color(0xFFFFD9A8)),
    PuzzleCategory.animals: (Color(0xFFEFF8EF), Color(0xFFBFE3C4)),
    PuzzleCategory.vehicles: (Color(0xFFEAF4FD), Color(0xFFB6D8F2)),
    PuzzleCategory.nature: (Color(0xFFFFFDEB), Color(0xFFDCEBA6)),
    PuzzleCategory.shapes: (Color(0xFFF8EEFA), Color(0xFFD8BFE4)),
  };

  /// The two ends of the gradient for a category.
  static (Color, Color) gradientOf(PuzzleCategory category) =>
      _byCategory[category] ?? _fallback;

  static PieceBackground backgroundFor(
    PuzzleCategory category, {
    required Rect boardRect,
  }) {
    final (from, to) = gradientOf(category);
    return PieceBackground(from: from, to: to, boardRect: boardRect);
  }
}
