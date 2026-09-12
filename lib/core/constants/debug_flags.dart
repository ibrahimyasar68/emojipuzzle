/// Developer switches (K-4). Everything here is guarded by `kDebugMode` at
/// the call site, so a release build tree-shakes it away.
library;

/// Draws cell bounds, the snap radius and the live grab-offset vector over
/// the board. Flip it to true while working on drag or snap.
bool debugShowPuzzleOverlay = false;
