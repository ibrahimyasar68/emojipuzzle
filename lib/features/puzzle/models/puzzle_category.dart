/// Content groups a puzzle can belong to (§4).
///
/// v1 has exactly these five. `colors`, `numbers` and friends are §47
/// material and must not be added here on a whim: the album groups by
/// category, so every new value changes a screen a child has learned.
enum PuzzleCategory {
  fruits,
  animals,
  vehicles,
  nature,
  shapes,
}
