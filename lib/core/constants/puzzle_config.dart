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

  /// §14 — Outward bleed, in logical pixels, applied when *painting* a piece.
  ///
  /// Two mathematically complementary paths still leave a hairline between
  /// them: each side covers roughly half of the boundary pixel, and two
  /// half-covered anti-aliased edges do not add up to an opaque one.
  /// Painting each piece a hair larger makes neighbours overlap instead.
  /// Snap and hit-testing keep using the exact geometry.
  static const double renderBleedPixels = 0.5;

  /// §6.1, §40 — The board never grows past this, tablet included.
  static const double maxBoardSize = 500;

  /// §40 — Share of the available height the board may take; the rest is
  /// where the tray has to fit (§16.1).
  static const double boardHeightFactor = 0.6;

  /// Breathing room around the board. Not dictated by the spec; it is what
  /// turns a 360 dp screen into the §16.1 reference board of 344.
  static const double boardMargin = 8;

  /// §2 — Nothing a child must touch is ever smaller than this. A layout
  /// that cannot honour it is the thing that changes, not this number.
  static const double minTouchTargetSize = 64;

  /// §16.1 — Tray pieces aim for this fraction of their board size. It is a
  /// target, not a floor: [minTouchTargetSize] wins when they conflict.
  static const double trayPreferredPieceScale = 0.70;

  /// §16.1 — Minimum gap between tray pieces.
  static const double trayItemSpacing = 12;

  /// §15 — Opacity of the picture showing through the empty board.
  static const double ghostOpacity = 0.25;

  /// §15 — The dashed outline drawn around every empty slot.
  static const double slotOutlineStrokeWidth = 1.5;
  static const double slotOutlineDashLength = 7;
  static const double slotOutlineDashGap = 5;

  /// §17 — Picking a piece up: it grows from tray size to board size while
  /// swelling to [dragEmphasisScale] on the way, and lifts off the surface.
  static const Duration dragLiftDuration = Duration(milliseconds: 120);
  static const double dragEmphasisScale = 1.1;
  static const double dragElevation = 6;

  /// §18 — Snap threshold: never tighter than [minSnapThreshold], and
  /// otherwise a share of the shorter cell edge.
  static const double minSnapThreshold = 24;
  static const double snapThresholdRatio = 0.35;

  /// §19 — Assist mode. After this many failed drops *of the same piece*,
  /// its snap threshold widens by [assistThresholdMultiplier]. The piece
  /// may then fly in from further away; that is a deliberate trade, because
  /// a stuck child is the worse outcome.
  static const int assistFailedAttempts = 3;
  static const double assistThresholdMultiplier = 1.8;

  /// §20 — The only answer to a wrong drop: a soft wobble on the way home.
  /// No red, no sound, no vibration, no "try again".
  static const Duration rubberBandDuration = Duration(milliseconds: 250);
  static const double rubberBandOvershoot = 1.08;
  static const double rubberBandUndershoot = 0.96;

  /// §22 — A correct drop settles into its slot well inside the 400 ms the
  /// whole success feedback is allowed.
  static const Duration snapSettleDuration = Duration(milliseconds: 160);

  /// §22 — the whole "well done" for one piece: pop, sparkles, tap. It is a
  /// ceiling, not a target, and it must never hold up the next piece.
  static const Duration placementFeedbackDuration = Duration(milliseconds: 400);

  /// §22 — six to eight sparkles.
  static const int sparkleCount = 7;

  /// §22 — the squash a piece makes as it drops into its slot.
  static const double settlePopScale = 1.06;

  /// §21 — how long a child may look at the board before the game offers
  /// help, and the gap between each louder offer: 8, 16, 24, 32 seconds.
  static const Duration hintFirstDelay = Duration(seconds: 8);
  static const Duration hintStageInterval = Duration(seconds: 8);
  static const Duration hintTickInterval = Duration(milliseconds: 500);

  /// §21 — one beat of a hint pulse, and how far it swells.
  static const Duration hintPulseDuration = Duration(milliseconds: 600);
  static const double hintPulseScale = 1.12;

  /// §21 — how long the ghost takes to drift from the tray to the slot.
  static const Duration hintGhostDuration = Duration(milliseconds: 1200);
  static const double hintGhostOpacity = 0.45;

  /// §23 — the finished picture gets its moment before anything else
  /// happens.
  static const Duration completionAnimationDuration =
      Duration(milliseconds: 600);

  /// §23 — the whole celebration, if the child just watches it. A tap ends
  /// it immediately: nobody is ever made to sit through this.
  static const Duration celebrationDuration = Duration(milliseconds: 2200);

  /// §42 — the particle budget for the whole screen.
  static const int confettiParticles = 15;
}
