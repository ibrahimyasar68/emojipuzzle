import 'dart:math' show min;
import 'dart:ui' show Offset, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';

/// Bütün koordinat uzayı dönüşümlerinin tek sahibi (§8, §9).
///
/// ```text
/// Global (screen / Stack)
///     ↓  − boardOriginGlobal
/// Board pixel
///     ↓  ÷ boardSize
/// Normalized board (0..1)
///     ↓  − (tabSize, tabSize)
/// Piece origin
/// ```
///
/// Widget'lar koordinat hesabını kendi içlerinde yapmaz, bunları çağırır.
abstract final class CoordinateMapper {
  // ── Global ↔ board ────────────────────────────────────────────────────

  static Offset globalToBoard(Offset global, Offset boardOriginGlobal) =>
      global - boardOriginGlobal;

  static Offset boardToGlobal(Offset boardLocal, Offset boardOriginGlobal) =>
      boardLocal + boardOriginGlobal;

  // ── Board pikseli ↔ normalize (§8.4) ──────────────────────────────────

  static Offset pixelOf(Offset normalized, Size boardSize) {
    assert(!boardSize.isEmpty, 'boardSize must be non-empty');
    return Offset(
      normalized.dx * boardSize.width,
      normalized.dy * boardSize.height,
    );
  }

  static Offset normalizedOf(Offset pixel, Size boardSize) {
    assert(!boardSize.isEmpty, 'boardSize must be non-empty');
    return Offset(
      pixel.dx / boardSize.width,
      pixel.dy / boardSize.height,
    );
  }

  // ── Hücre / parça geometrisi (§6, §7) ─────────────────────────────────

  /// Bir hücrenin sol üstü, normalize board uzayında (§8.5).
  ///
  /// Her zaman `[0.0, 1.0)` aralığındadır, çünkü `column < columns` ve
  /// `row < rows`.
  static Offset normalizedCellOrigin(PuzzleGrid grid, int row, int column) {
    assert(row >= 0 && row < grid.rows, 'row $row out of range');
    assert(column >= 0 && column < grid.columns, 'column $column out of range');
    return Offset(column / grid.columns, row / grid.rows);
  }

  /// Hücrelerin kare olması gerekmez: 500'lük board'da 2×3 grid
  /// 166,67 × 250 verir.
  static Size cellSizeOf(PuzzleGrid grid, Size boardSize) {
    assert(!boardSize.isEmpty, 'boardSize must be non-empty');
    return Size(boardSize.width / grid.columns, boardSize.height / grid.rows);
  }

  /// §7 — hücrenin kısa kenarına göre.
  static double tabSizeOf(Size cellSize) =>
      min(cellSize.width, cellSize.height) * PuzzleConfig.tabSizeRatio;

  /// §7 — hücre, artı her kenarda bir tırnak boyu pay.
  static Size pieceSizeOf(Size cellSize) {
    final tabSize = tabSizeOf(cellSize);
    return Size(
      cellSize.width + 2 * tabSize,
      cellSize.height + 2 * tabSize,
    );
  }

  /// Parçanın sınır kutusunun sol üstü, board pikselinde (§8.5).
  ///
  /// Hücre başlangıcından `(tabSize, tabSize)` çıkarılmış hali; kenar
  /// parçalarında negatiftir ve bu beklenen bir durumdur (§7: taşma hata
  /// değildir).
  static Offset pieceOriginOf({
    required Offset normalizedPosition,
    required PuzzleGrid grid,
    required Size boardSize,
  }) {
    final tabSize = tabSizeOf(cellSizeOf(grid, boardSize));
    return pixelOf(normalizedPosition, boardSize) - Offset(tabSize, tabSize);
  }

  // ── Sürükleme sözleşmesi (§9) ─────────────────────────────────────────

  /// Parmağın parçanın neresine bastığı. Sürükleme boyunca sabittir.
  static Offset grabOffsetOf({
    required Offset pointerBoardLocal,
    required Offset pieceOriginBoardLocal,
  }) =>
      pointerBoardLocal - pieceOriginBoardLocal;

  /// Tutma noktasını parmağın altında tutan parça başlangıcı.
  static Offset pieceOriginFromPointer({
    required Offset pointerBoardLocal,
    required Offset grabOffset,
  }) =>
      pointerBoardLocal - grabOffset;
}
