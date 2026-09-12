import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// Every grid the engine must support (§41), including engine-only ones.
const supportedGrids = [
  PuzzleGrid(rows: 1, columns: 3),
  PuzzleGrid(rows: 2, columns: 2),
  PuzzleGrid(rows: 2, columns: 3),
  PuzzleGrid(rows: 3, columns: 3),
  PuzzleGrid(rows: 3, columns: 4),
];

/// Floating point tolerance for coordinate round-trips.
const coordinateTolerance = 1e-9;

void expectOffsetClose(Offset actual, Offset expected, {String? reason}) {
  expect(actual.dx, closeTo(expected.dx, coordinateTolerance), reason: reason);
  expect(actual.dy, closeTo(expected.dy, coordinateTolerance), reason: reason);
}
