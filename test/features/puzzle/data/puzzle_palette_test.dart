import 'dart:ui' show Color;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_palette.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('six categories, Eşyalar the newest (§4, K-14)', () {
    expect(PuzzleCategory.values, hasLength(6));
    expect(PuzzleCategory.values.last, PuzzleCategory.objects);
  });

  test('every category has a surface of its own (§34)', () {
    // What an unknown category falls back to: the plain cream.
    const fallback = (Color(0xFFFDF7EF), Color(0xFFF3E4D0));

    final gradients = {
      for (final category in PuzzleCategory.values)
        category: PuzzlePalette.gradientOf(category),
    };

    for (final entry in gradients.entries) {
      expect(
        entry.value,
        isNot(fallback),
        reason: '${entry.key} was given no surface and fell back to cream',
      );
    }
    // And no two share one: the surface is how a mostly empty piece tells
    // the child which picture it belongs to.
    expect(gradients.values.toSet(), hasLength(PuzzleCategory.values.length));
  });
}
