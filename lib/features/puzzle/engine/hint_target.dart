import '../models/puzzle_piece.dart';

/// Picks the piece a hint should point at (§21.1).
abstract final class HintTarget {
  /// The easiest remaining piece: the one with the most flat sides, and on
  /// a tie the lowest id.
  ///
  /// Flat sides mean board edges, and an edge piece is the one a child can
  /// actually reason about — "it goes along the side". The tie-break is
  /// there so the answer is never ambiguous: on a 1×3 the middle piece and
  /// a corner both have two flat sides, and a rule that cannot choose is
  /// not a rule (§21.1).
  static PuzzlePiece? choose(Iterable<PuzzlePiece> candidates) {
    PuzzlePiece? best;
    for (final piece in candidates) {
      final champion = best;
      if (champion == null ||
          piece.flatEdgeCount > champion.flatEdgeCount ||
          (piece.flatEdgeCount == champion.flatEdgeCount &&
              piece.id < champion.id)) {
        best = piece;
      }
    }
    return best;
  }
}
