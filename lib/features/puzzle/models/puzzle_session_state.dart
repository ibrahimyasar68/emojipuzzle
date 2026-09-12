/// What the current puzzle session is doing (§38).
enum PuzzleSessionState {
  /// Waiting for the child to pick a piece up.
  idle,

  /// A piece is being dragged (Faz 5).
  dragging,

  /// A piece is animating into place (Faz 6).
  snapping,

  /// Every piece is placed (§23).
  completed,
}
