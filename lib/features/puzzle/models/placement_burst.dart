import 'dart:ui' show Offset;

/// A "that one is home" flourish, at a point on the screen (§22).
class PlacementBurst {
  const PlacementBurst({required this.id, required this.centre});

  /// Rises with every burst, so two pieces landing in the same slot — or a
  /// piece landing twice after a restart — still restart the animation.
  final int id;

  /// Middle of the slot, in the coordinates of the layer that draws it.
  final Offset centre;

  @override
  bool operator ==(Object other) =>
      other is PlacementBurst && other.id == id && other.centre == centre;

  @override
  int get hashCode => Object.hash(id, centre);

  @override
  String toString() => 'PlacementBurst(#$id at $centre)';
}
