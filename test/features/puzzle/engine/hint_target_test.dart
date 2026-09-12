import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/hint_target.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_grids.dart';

PuzzlePiece _piece({
  required int id,
  required int flatEdges,
}) {
  EdgeType edge(int index) => index < flatEdges ? EdgeType.flat : EdgeType.tab;
  return PuzzlePiece(
    id: id,
    row: 0,
    column: id,
    top: edge(0),
    right: edge(1),
    bottom: edge(2),
    left: edge(3),
    normalizedPosition: Offset.zero,
  );
}

void main() {
  group('HintTarget.choose (§21.1)', () {
    test('nothing to suggest when nothing is left', () {
      expect(HintTarget.choose(const []), isNull);
    });

    test('prefers the piece with the most flat sides', () {
      final pieces = [
        _piece(id: 0, flatEdges: 0),
        _piece(id: 1, flatEdges: 2),
        _piece(id: 2, flatEdges: 1),
      ];

      expect(HintTarget.choose(pieces)?.id, 1);
    });

    test('breaks a tie on the lowest id, always', () {
      final pieces = [
        _piece(id: 3, flatEdges: 2),
        _piece(id: 1, flatEdges: 2),
        _piece(id: 2, flatEdges: 2),
      ];

      expect(HintTarget.choose(pieces)?.id, 1);
      // Order of the candidates must not change the answer.
      expect(HintTarget.choose(pieces.reversed)?.id, 1);
    });

    test('every grid has exactly one answer, and it is a corner', () {
      for (final grid in supportedGrids) {
        final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
        final target = HintTarget.choose(pieces)!;
        final best = pieces
            .map((piece) => piece.flatEdgeCount)
            .reduce((a, b) => a > b ? a : b);

        expect(target.flatEdgeCount, best, reason: '$grid');
        expect(
          pieces
              .where((p) => p.flatEdgeCount == best)
              .map((p) => p.id)
              .reduce((a, b) => a < b ? a : b),
          target.id,
          reason: '$grid picks the lowest id among the best',
        );
      }
    });

    test('a 2×2 starts at piece 0: every piece is a corner', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final pieces = PuzzleGenerator(random: Random(0)).generate(grid);

      expect(pieces.every((p) => p.flatEdgeCount == 2), isTrue);
      expect(HintTarget.choose(pieces)?.id, 0);
    });

    test('the answer changes as pieces are solved', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      final pieces = PuzzleGenerator(random: Random(0)).generate(grid);
      final remaining = pieces.where((p) => p.id != 0).toList();

      expect(HintTarget.choose(pieces)?.id, 0);
      expect(HintTarget.choose(remaining)?.id, isNot(0));
    });
  });
}
