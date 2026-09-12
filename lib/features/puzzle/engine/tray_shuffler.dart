import 'dart:math' show Random;

/// Decides which tray slot each piece starts in (§16.3).
///
/// Randomness is injected so a test can pin the arrangement, and so Serbest
/// Mod can reshuffle the same puzzle every session.
class TrayShuffler {
  TrayShuffler({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Returns a slot index per piece id: `result[pieceId] == slotIndex`.
  ///
  /// The result is a permutation of `0 .. pieceCount - 1`, so no two pieces
  /// share a slot and no slot is skipped.
  List<int> assignSlots(int pieceCount) {
    assert(pieceCount > 0, 'pieceCount must be positive');
    final slots = List<int>.generate(pieceCount, (i) => i);

    // Fisher–Yates.
    for (var i = slots.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = slots[i];
      slots[i] = slots[j];
      slots[j] = temp;
    }

    return List.unmodifiable(slots);
  }
}
