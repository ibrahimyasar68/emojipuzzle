import 'package:emoji_puzzle_kids/features/colouring/data/car_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('five stages, each a size bigger: 2×2, 2×3, 3×3, 4×3, 4×4 (K-15)', () {
    expect(GameRules.stageGrids, const [
      PuzzleGrid(rows: 2, columns: 2),
      PuzzleGrid(rows: 2, columns: 3),
      PuzzleGrid(rows: 3, columns: 3),
      PuzzleGrid(rows: 4, columns: 3),
      PuzzleGrid(rows: 4, columns: 4),
    ]);
    final counts = GameRules.stageGrids.map((g) => g.pieceCount).toList();
    expect(counts, [4, 6, 9, 12, 16]);
  });

  test('three cars make a game', () {
    expect(GameRules.carsPerGame, 3);
  });

  test('every car has exactly one part per stage', () {
    // Five stages paint five parts: a car with a sixth part would never be
    // finished, and one with four would leave a stage with nothing to paint.
    for (final model in CarCatalog.models) {
      expect(model.parts, hasLength(GameRules.stagesPerCar), reason: model.id);
    }
  });
}
