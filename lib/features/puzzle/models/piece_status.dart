/// Where a piece is right now (§12, §38).
enum PieceStatus {
  /// Waiting in its fixed tray slot (§16.2).
  inTray,

  /// Under the child's finger (Faz 5).
  dragging,

  /// Animating into its slot after a successful drop (Faz 6).
  snapping,

  /// Solved. A placed piece is locked: it cannot be picked up again (§10).
  placed,
}
