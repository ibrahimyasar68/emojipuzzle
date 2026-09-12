import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../data/puzzle_palette.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/piece_image_mapper.dart';
import '../engine/path/piece_paths.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import 'board_ghost_painter.dart';
import 'puzzle_piece_painter.dart';

/// The play area: ghost underneath, solved pieces on top (§15).
class PuzzleBoard extends StatelessWidget {
  const PuzzleBoard({
    super.key,
    required this.image,
    required this.grid,
    required this.paths,
    required this.placedPieces,
    required this.boardSize,
    this.backgroundCategory,
  });

  final ui.Image image;
  final PuzzleGrid grid;
  final PiecePaths paths;
  final List<PuzzlePiece> placedPieces;
  final Size boardSize;

  /// Picks the surface painted under the transparent artwork (§34).
  final PuzzleCategory? backgroundCategory;

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
      key: const ValueKey('puzzle-board'),
      width: boardSize.width,
      height: boardSize.height,
      child: Stack(
        // Tabs of the outer pieces stick out of the board (§7).
        clipBehavior: Clip.none,
        children: [
          CustomPaint(
            size: boardSize,
            painter: BoardGhostPainter(
              image: image,
              grid: grid,
              background: _backgroundAt(Offset.zero),
              filledCells: {
                for (final piece in placedPieces)
                  piece.row * grid.columns + piece.column,
              },
            ),
          ),
          for (final piece in placedPieces)
            _placed(piece, pieceSize, imageSize),
        ],
      ),
    );
  }

  /// The board's gradient, expressed in the coordinates of a piece drawn at
  /// [origin], so every piece continues the one next to it.
  PieceBackground? _backgroundAt(Offset origin) {
    final category = backgroundCategory;
    if (category == null) return null;
    return PuzzlePalette.backgroundFor(
      category,
      boardRect: Rect.fromLTWH(
        -origin.dx,
        -origin.dy,
        boardSize.width,
        boardSize.height,
      ),
    );
  }

  Widget _placed(PuzzlePiece piece, Size pieceSize, Size imageSize) {
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );

    return Positioned(
      key: ValueKey('board-piece-${piece.id}'),
      left: origin.dx,
      top: origin.dy,
      width: pieceSize.width,
      height: pieceSize.height,
      child: CustomPaint(
        size: pieceSize,
        painter: PuzzlePiecePainter(
          image: image,
          renderPath: paths.of(piece.id),
          background: _backgroundAt(origin),
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
