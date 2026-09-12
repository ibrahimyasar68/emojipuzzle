/// Top-level readiness of the game (§38).
enum AppState {
  /// Building the puzzle and getting its picture ready.
  loading,

  /// Playable.
  ready,

  /// Nothing could be loaded. The child is never shown an error (§14);
  /// this exists so the app can fall back quietly.
  error,
}
