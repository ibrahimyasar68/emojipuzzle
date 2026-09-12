import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // Compiling a `const` instance proves the constructor is const and
  // therefore every field is final (§49).
  const corner = PuzzlePiece(
    id: 0,
    row: 0,
    column: 0,
    top: EdgeType.flat,
    right: EdgeType.tab,
    bottom: EdgeType.blank,
    left: EdgeType.flat,
    normalizedPosition: Offset.zero,
  );

  group('PuzzlePiece', () {
    test('flatEdgeCount counts flat sides', () {
      expect(corner.flatEdgeCount, 2);

      const inner = PuzzlePiece(
        id: 4,
        row: 1,
        column: 1,
        top: EdgeType.tab,
        right: EdgeType.blank,
        bottom: EdgeType.tab,
        left: EdgeType.blank,
        normalizedPosition: Offset(1 / 3, 1 / 3),
      );
      expect(inner.flatEdgeCount, 0);
    });

    test('value equality', () {
      const same = PuzzlePiece(
        id: 0,
        row: 0,
        column: 0,
        top: EdgeType.flat,
        right: EdgeType.tab,
        bottom: EdgeType.blank,
        left: EdgeType.flat,
        normalizedPosition: Offset.zero,
      );
      const differentEdge = PuzzlePiece(
        id: 0,
        row: 0,
        column: 0,
        top: EdgeType.flat,
        right: EdgeType.blank,
        bottom: EdgeType.blank,
        left: EdgeType.flat,
        normalizedPosition: Offset.zero,
      );

      expect(corner, same);
      expect(corner.hashCode, same.hashCode);
      expect(corner, isNot(differentEdge));
    });
  });
}
