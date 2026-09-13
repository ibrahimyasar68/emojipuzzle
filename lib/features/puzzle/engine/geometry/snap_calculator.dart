import 'dart:math' as math;
import 'dart:ui' show Offset, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import 'coordinate_mapper.dart';

/// Bırakılan bir parçanın bırakıldığı yere ait olup olmadığına karar verir
/// (§18).
///
/// Yalnızca parçanın **kendi** yuvası dikkate alınır. Yanlış bir hücrenin
/// yakınında olmak hiçbir şey ifade etmez; bir parça asla komşusunun yerine
/// oturmaz (§18.2) — yanlış bırakmayı zararsız kılan da budur.
abstract final class SnapCalculator {
  /// Ne kadar yakının yeterli olduğu, board pikselinde (§18, §19).
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

  /// Parçanın merkezi ile yuvasının merkezi arasındaki mesafe (§18.1).
  ///
  /// Köşeler değil merkezler: tırnak payı simetriktir, bu yüzden tam yerinde
  /// duran bir parçanın merkezi, kenarları nasıl olursa olsun, hücrenin
  /// merkeziyle tam olarak çakışır.
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

  /// Bu bırakmanın "yerine oturdu" sayılıp sayılmayacağı.
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

  /// Yerine oturan parçanın durduğu nokta, board koordinatlarında (§8.5).
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
