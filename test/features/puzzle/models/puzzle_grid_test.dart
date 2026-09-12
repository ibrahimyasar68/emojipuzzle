import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PuzzleGrid', () {
    test('pieceCount == rows * columns', () {
      expect(const PuzzleGrid(rows: 1, columns: 3).pieceCount, 3);
      expect(const PuzzleGrid(rows: 2, columns: 2).pieceCount, 4);
      expect(const PuzzleGrid(rows: 2, columns: 3).pieceCount, 6);
      expect(const PuzzleGrid(rows: 3, columns: 3).pieceCount, 9);
      expect(const PuzzleGrid(rows: 3, columns: 4).pieceCount, 12);
    });

    test('idOf is row-major: row * columns + column', () {
      const grid = PuzzleGrid(rows: 2, columns: 3);
      expect(grid.idOf(0, 0), 0);
      expect(grid.idOf(0, 2), 2);
      expect(grid.idOf(1, 0), 3);
      expect(grid.idOf(1, 2), 5);
    });

    test('idOf asserts on out-of-range cells', () {
      const grid = PuzzleGrid(rows: 2, columns: 3);
      expect(() => grid.idOf(2, 0), throwsA(isA<AssertionError>()));
      expect(() => grid.idOf(0, 3), throwsA(isA<AssertionError>()));
      expect(() => grid.idOf(-1, 0), throwsA(isA<AssertionError>()));
    });

    test('rejects non-positive dimensions', () {
      int rows() => 0;
      expect(
        () => PuzzleGrid(rows: rows(), columns: 3),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PuzzleGrid(rows: 3, columns: rows()),
        throwsA(isA<AssertionError>()),
      );
    });

    test('value equality', () {
      expect(
        const PuzzleGrid(rows: 2, columns: 3),
        const PuzzleGrid(rows: 2, columns: 3),
      );
      expect(
        const PuzzleGrid(rows: 2, columns: 3),
        isNot(const PuzzleGrid(rows: 3, columns: 2)),
      );
    });
  });
}
