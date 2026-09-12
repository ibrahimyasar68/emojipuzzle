/// How loudly the game is offering help (§21).
///
/// The ladder only ever climbs while the child does nothing, and any touch
/// sends it back to [none]. Nothing here costs the child anything: a hint
/// is an offer, never a correction (§20).
enum HintStage {
  /// The child is playing. Say nothing.
  none,

  /// 8 s — the piece that would be easiest pulses twice.
  pulsePiece,

  /// 16 s — the piece and the slot it belongs to pulse together.
  pulseBoth,

  /// 24 s — a ghost of the piece drifts from the tray to the slot.
  ghostMove,

  /// 32 s — the game places it, and starts over from silence.
  autoPlace,
}
