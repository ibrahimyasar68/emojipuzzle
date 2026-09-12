import 'dart:ui' show Offset, Rect, Size;

import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';

/// The two rectangles `canvas.drawImageRect` needs for one piece.
///
/// [src] is in **source image pixels**, [dst] in **piece-local** coordinates,
/// i.e. the same space as the piece path, so the painter can clip and draw
/// without any further conversion.
typedef PieceDrawRects = ({Rect src, Rect dst});

/// Maps a piece onto the region of the source image it shows (§14).
abstract final class PieceImageMapper {
  /// Both rectangles carry the same scale, so the image is never stretched.
  ///
  /// Border pieces stick out of the board by `tabSize` (§7). That overflow
  /// has no image behind it, so [src] is clamped to the image and [dst] is
  /// shrunk by exactly the same amount instead of silently stretching the
  /// picture. The assert guards the pathological case — a piece that lies
  /// outside the image altogether — not the expected tab overflow.
  static PieceDrawRects rectsOf({
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
    required Size imageSize,
  }) {
    assert(!boardSize.isEmpty, 'boardSize must be non-empty');
    assert(!imageSize.isEmpty, 'imageSize must be non-empty');
    assert(
      (imageSize.width / imageSize.height - boardSize.width / boardSize.height)
              .abs() <
          1e-6,
      'board and image must share an aspect ratio (§6.1: 1:1 assets, '
      'square board, BoxFit.contain)',
    );

    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);
    final pieceOrigin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );

    final scaleX = imageSize.width / boardSize.width;
    final scaleY = imageSize.height / boardSize.height;

    final rawSrc = Rect.fromLTWH(
      pieceOrigin.dx * scaleX,
      pieceOrigin.dy * scaleY,
      pieceSize.width * scaleX,
      pieceSize.height * scaleY,
    );
    final src = rawSrc.intersect(Offset.zero & imageSize);
    assert(
      src.width > 0 && src.height > 0,
      'piece ${piece.id} does not overlap the source image',
    );

    final dst = Rect.fromLTWH(
      src.left / scaleX - pieceOrigin.dx,
      src.top / scaleY - pieceOrigin.dy,
      src.width / scaleX,
      src.height / scaleY,
    );

    return (src: src, dst: dst);
  }
}
