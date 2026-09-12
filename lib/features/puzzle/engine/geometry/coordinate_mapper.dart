import 'dart:math' show min;
import 'dart:ui' show Offset, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';

/// Single owner of every coordinate-space conversion (§8, §9).
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
/// Widgets must call these instead of doing coordinate math inline.
abstract final class CoordinateMapper {
  // ── Global ↔ board ────────────────────────────────────────────────────

  static Offset globalToBoard(Offset global, Offset boardOriginGlobal) =>
      global - boardOriginGlobal;

  static Offset boardToGlobal(Offset boardLocal, Offset boardOriginGlobal) =>
      boardLocal + boardOriginGlobal;

  // ── Board pixel ↔ normalized (§8.4) ───────────────────────────────────

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

  // ── Cell / piece geometry (§6, §7) ────────────────────────────────────

  /// Top-left of a cell in normalized board space (§8.5).
  ///
  /// Always in `[0.0, 1.0)` because `column < columns` and `row < rows`.
  static Offset normalizedCellOrigin(PuzzleGrid grid, int row, int column) {
    assert(row >= 0 && row < grid.rows, 'row $row out of range');
    assert(column >= 0 && column < grid.columns, 'column $column out of range');
    return Offset(column / grid.columns, row / grid.rows);
  }

  /// Cells need not be square: a 2×3 grid on a 500 board is 166.67 × 250.
  static Size cellSizeOf(PuzzleGrid grid, Size boardSize) {
    assert(!boardSize.isEmpty, 'boardSize must be non-empty');
    return Size(boardSize.width / grid.columns, boardSize.height / grid.rows);
  }

  /// §7 — based on the shorter cell edge.
  static double tabSizeOf(Size cellSize) =>
      min(cellSize.width, cellSize.height) * PuzzleConfig.tabSizeRatio;

  /// §7 — cell plus a tab-sized margin on every side.
  static Size pieceSizeOf(Size cellSize) {
    final tabSize = tabSizeOf(cellSize);
    return Size(
      cellSize.width + 2 * tabSize,
      cellSize.height + 2 * tabSize,
    );
  }

  /// Top-left of the piece's bounding box in board pixels (§8.5).
  ///
  /// Equals the cell origin minus `(tabSize, tabSize)`; for border pieces
  /// this is negative, which is expected (§7: overflow is not an error).
  static Offset pieceOriginOf({
    required Offset normalizedPosition,
    required PuzzleGrid grid,
    required Size boardSize,
  }) {
    final tabSize = tabSizeOf(cellSizeOf(grid, boardSize));
    return pixelOf(normalizedPosition, boardSize) - Offset(tabSize, tabSize);
  }

  // ── Drag contract (§9) ────────────────────────────────────────────────

  /// Where inside the piece the finger landed. Fixed for the whole drag.
  static Offset grabOffsetOf({
    required Offset pointerBoardLocal,
    required Offset pieceOriginBoardLocal,
  }) =>
      pointerBoardLocal - pieceOriginBoardLocal;

  /// Piece origin that keeps the grab point under the finger.
  static Offset pieceOriginFromPointer({
    required Offset pointerBoardLocal,
    required Offset grabOffset,
  }) =>
      pointerBoardLocal - grabOffset;
}
