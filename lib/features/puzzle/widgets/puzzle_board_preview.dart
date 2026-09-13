import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/piece_image_mapper.dart';
import '../engine/path/piece_paths.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import 'puzzle_piece_painter.dart';

/// Her parça çözülmüş konumunda çizilir — birleştirilmiş resim.
///
/// Faz 3 geometriyi ekranda denetlemek için bunu kullanır. Sonraki fazlar
/// bunu tamamlanmış board için korur; çözülmemiş parçalar tepsiye taşınır.
class PuzzleBoardPreview extends StatelessWidget {
  const PuzzleBoardPreview({
    super.key,
    required this.image,
    required this.pieces,
    required this.grid,
    required this.paths,
    required this.boardSize,
  });

  final ui.Image image;
  final List<PuzzlePiece> pieces;
  final PuzzleGrid grid;
  final PiecePaths paths;
  final Size boardSize;

  @override
  Widget build(BuildContext context) {
    assert(
      paths.matches(boardSize),
      'path cache was built for ${paths.boardSize}, not $boardSize',
    );

    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());

    return SizedBox(
      width: boardSize.width,
      height: boardSize.height,
      // Tırnaklar board'un dışına tabSize kadar taşar (§7); asıl hata
      // taşma değil, onları kırpmak olurdu.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          for (final piece in pieces) _positioned(piece, pieceSize, imageSize),
        ],
      ),
    );
  }

  Widget _positioned(PuzzlePiece piece, Size pieceSize, Size imageSize) {
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );

    return Positioned(
      left: origin.dx,
      top: origin.dy,
      width: pieceSize.width,
      height: pieceSize.height,
      child: CustomPaint(
        size: pieceSize,
        painter: PuzzlePiecePainter(
          image: image,
          renderPath: paths.of(piece.id),
          rects: PieceImageMapper.rectsOf(
            piece: piece,
            grid: grid,
            boardSize: boardSize,
            imageSize: imageSize,
          ),
        ),
      ),
    );
  }
}
