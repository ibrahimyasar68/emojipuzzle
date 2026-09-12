import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:flutter_test/flutter_test.dart';

/// §41-style statistical check: one seed pair proves nothing.
const _seedCount = 50;
const _minUniqueArrangements = 40;

void main() {
  group('TrayShuffler', () {
    for (final pieceCount in [4, 6, 9]) {
      test('$pieceCount pieces: every slot used exactly once', () {
        final slots = TrayShuffler(random: Random(0)).assignSlots(pieceCount);

        expect(slots, hasLength(pieceCount));
        expect(slots.toSet(), hasLength(pieceCount));
        expect(
          slots.toList()..sort(),
          List.generate(pieceCount, (i) => i),
        );
      });
    }

    test('same seed, same arrangement', () {
      expect(
        TrayShuffler(random: Random(42)).assignSlots(9),
        TrayShuffler(random: Random(42)).assignSlots(9),
      );
    });

    test(
        '$_seedCount seeds produce at least '
        '$_minUniqueArrangements arrangements', () {
      final arrangements = {
        for (var seed = 0; seed < _seedCount; seed++)
          TrayShuffler(random: Random(seed)).assignSlots(9).join(','),
      };
      expect(
        arrangements.length,
        greaterThanOrEqualTo(_minUniqueArrangements),
      );
    });

    test('result is unmodifiable', () {
      final slots = TrayShuffler(random: Random(0)).assignSlots(4);
      expect(() => slots[0] = 3, throwsUnsupportedError);
    });

    test('works without an injected Random', () {
      expect(TrayShuffler().assignSlots(6), hasLength(6));
    });
  });
}
