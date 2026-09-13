import 'dart:ui' show Offset, Rect, Size;

import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';

/// `canvas.drawImageRect`'in bir parça için ihtiyaç duyduğu iki dikdörtgen.
///
/// [src] **kaynak görsel pikseli**, [dst] ise **parça-yerel** koordinattadır;
/// yani parça path'iyle aynı uzayda. Böylece boyayıcı başka bir dönüşüm
/// yapmadan kırpıp çizebilir.
typedef PieceDrawRects = ({Rect src, Rect dst});

/// Bir parçayı, gösterdiği kaynak görsel bölgesiyle eşler (§14).
abstract final class PieceImageMapper {
  /// İki dikdörtgen de aynı ölçeği taşır, böylece görsel asla gerilmez.
  ///
  /// Kenar parçaları board'un dışına `tabSize` kadar taşar (§7). Bu taşmanın
  /// arkasında görsel yoktur; bu yüzden [src] görsele kırpılır ve [dst] de
  /// tam olarak aynı miktarda küçültülür — resim sessizce gerilmez. Assert,
  /// beklenen tırnak taşmasını değil, patolojik durumu korur: tamamen
  /// görselin dışında kalan bir parçayı.
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
