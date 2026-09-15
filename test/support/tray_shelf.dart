import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/tray_layout_calculator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';

/// Whether, at any board size `BoardFitter` may choose on [area], the pieces
/// of [grid] can sit in a shelf-shaped tray (columns ≥ rows) and still be
/// big enough to touch.
///
/// Not always: a 4×3 puzzle's pieces are 1.24 times wider than tall, and on
/// a 320 dp phone four of them side by side are too short to reach 64 px —
/// at every board size (measured). The touch target wins, and the tray is
/// laid out down instead (§2, §16.1).
bool shelfPossible(Size area, PuzzleGrid grid) {
  final preferred = math.min(
    math.min(
      area.width - 2 * PuzzleConfig.boardMargin,
      area.height * PuzzleConfig.boardHeightFactor,
    ),
    PuzzleConfig.maxBoardSize,
  );
  final smallest =
      math.max(grid.rows, grid.columns) * PuzzleConfig.minTouchTargetSize;

  for (var edge = preferred;
      edge == preferred || edge >= smallest;
      edge -= PuzzleConfig.boardFitStep) {
    final shelf = TrayLayoutCalculator.tryCalculate(
      traySize: Size(area.width, area.height - edge),
      pieceCount: grid.pieceCount,
      boardPieceSize: CoordinateMapper.pieceSizeOf(
        CoordinateMapper.cellSizeOf(grid, Size(edge, edge)),
      ),
      requireShelf: true,
    );
    if (shelf != null) return true;
    if (edge < smallest) break;
  }
  return false;
}
