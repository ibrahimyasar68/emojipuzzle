import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';

/// Decides whether a dropped piece belongs where it was dropped (§18).
///
/// Only the piece's **own** slot is ever considered. Being near the wrong
/// cell means nothing; a piece can never snap into a neighbour's place
/// (§18.2), which is what makes a wrong drop harmless.
abstract final class SnapCalculator {
  /// How close is close enough, in board pixels (§18, §19).
  static double thresholdFor({
    required Size cellSize,
    int failedAttempts = 0,
  }) {
    assert(failedAttempts >= 0, 'failedAttempts must be non-negative');
    final base = math.max(
      PuzzleConfig.minSnapThreshold,
      math.min(cellSize.width, cellSize.height) *
          PuzzleConfig.snapThresholdRatio,
    );
    return failedAttempts >= PuzzleConfig.assistFailedAttempts
        ? base * PuzzleConfig.assistThresholdMultiplier
        : base;
  }

  /// Distance between the centre of the piece and the centre of its slot
  /// (§18.1).
  ///
  /// Centres, not corners: the tab margin is symmetric, so a piece sitting
  /// exactly right has its centre exactly on the cell's centre, whatever
  /// its edges look like.
  static double distanceToSlot({
    required Offset pieceOriginBoardLocal,
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
  }) {
    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);

    final pieceCentre = pieceOriginBoardLocal +
        Offset(pieceSize.width / 2, pieceSize.height / 2);
    final slotCentre =
        CoordinateMapper.pixelOf(piece.normalizedPosition, boardSize) +
            Offset(cellSize.width / 2, cellSize.height / 2);

    return (pieceCentre - slotCentre).distance;
  }

  /// Whether this drop counts as "in place".
  static bool snaps({
    required Offset pieceOriginBoardLocal,
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
    int failedAttempts = 0,
  }) {
    final distance = distanceToSlot(
      pieceOriginBoardLocal: pieceOriginBoardLocal,
      piece: piece,
      grid: grid,
      boardSize: boardSize,
    );
    return distance <=
        thresholdFor(
          cellSize: CoordinateMapper.cellSizeOf(grid, boardSize),
          failedAttempts: failedAttempts,
        );
  }

  /// Where a snapped piece comes to rest, in board coordinates (§8.5).
  static Offset restingOrigin({
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
  }) =>
      CoordinateMapper.pieceOriginOf(
        normalizedPosition: piece.normalizedPosition,
        grid: grid,
        boardSize: boardSize,
      );
}
