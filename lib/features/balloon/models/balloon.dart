/// One balloon in the mini game (§24).
///
/// It carries no pixels. Everything here is a ratio or a phase, so the
/// same balloon looks right on a phone and on a tablet, and so the rules
/// can be tested without a screen.
class Balloon {
  const Balloon({
    required this.id,
    required this.x,
    required this.restY,
    required this.colourIndex,
    required this.sizeFactor,
    required this.bobPhase,
    required this.bornAt,
  });

  /// Spawn order, starting at 0. Also the widget key.
  final int id;

  /// Where it sits across the play area, `[0, 1]`.
  final double x;

  /// Where it comes to rest, `[0, 1]` from the top of the play area.
  final double restY;

  /// Which colour of the balloon palette it wears.
  final int colourIndex;

  /// A little variety in size, around 1.
  final double sizeFactor;

  /// Offset into the bob cycle, so they do not all sway together.
  final double bobPhase;

  /// Time on the game clock when it appeared, for the drift upward.
  final Duration bornAt;

  @override
  String toString() => 'Balloon($id, x: $x, restY: $restY)';
}
