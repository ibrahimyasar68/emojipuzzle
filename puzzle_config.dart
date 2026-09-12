/// Tunable puzzle constants.
///
/// Every constant cites the spec section it comes from (§46). Constants are
/// added in the phase that first uses them, so nothing here is speculative.
abstract final class PuzzleConfig {
  /// §7 — Tab protrusion as a fraction of the cell's shorter edge.
  ///
  /// Using the shorter edge keeps tabs from ballooning on narrow cells
  /// (e.g. 2×3 on a square board gives 166.67 × 250 cells).
  static const double tabSizeRatio = 0.20;
}
