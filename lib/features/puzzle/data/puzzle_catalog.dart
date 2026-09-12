import '../models/level_definition.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_grid.dart';

/// The content of the game, and the rules for walking through it (§4, §13).
///
/// Dart, not JSON: nine puzzles are not worth a parser, and the compiler
/// catches a typo in a grid where a JSON file would only fail on a child's
/// device. JSON becomes interesting when the content stops fitting on one
/// screen (§13).
class PuzzleCatalog {
  const PuzzleCatalog(this.levels);

  final List<LevelDefinition> levels;

  /// K-1 = A: three levels, nine puzzles. The engine still supports 1×3 and
  /// 3×4 — those are engine capabilities, not content (§4).
  static const PuzzleCatalog v1 = PuzzleCatalog([
    LevelDefinition(
      index: 1,
      requiredCompletions: 2,
      puzzles: [
        PuzzleDefinition(
          id: 'apple_01',
          imagePath: 'assets/images/puzzles/apple.png',
          category: PuzzleCategory.fruits,
          grid: PuzzleGrid(rows: 2, columns: 2),
          displayName: 'Elma',
        ),
        PuzzleDefinition(
          id: 'cat_01',
          imagePath: 'assets/images/puzzles/cat.png',
          category: PuzzleCategory.animals,
          grid: PuzzleGrid(rows: 2, columns: 2),
          displayName: 'Kedi',
        ),
        PuzzleDefinition(
          id: 'ball_01',
          imagePath: 'assets/images/puzzles/ball.png',
          category: PuzzleCategory.shapes,
          grid: PuzzleGrid(rows: 2, columns: 2),
          displayName: 'Top',
        ),
      ],
    ),
    LevelDefinition(
      index: 2,
      requiredCompletions: 2,
      puzzles: [
        PuzzleDefinition(
          id: 'banana_01',
          imagePath: 'assets/images/puzzles/banana.png',
          category: PuzzleCategory.fruits,
          grid: PuzzleGrid(rows: 2, columns: 3),
          displayName: 'Muz',
        ),
        PuzzleDefinition(
          id: 'dog_01',
          imagePath: 'assets/images/puzzles/dog.png',
          category: PuzzleCategory.animals,
          grid: PuzzleGrid(rows: 2, columns: 3),
          displayName: 'Köpek',
        ),
        PuzzleDefinition(
          id: 'bus_01',
          imagePath: 'assets/images/puzzles/bus.png',
          category: PuzzleCategory.vehicles,
          grid: PuzzleGrid(rows: 2, columns: 3),
          displayName: 'Otobüs',
        ),
      ],
    ),
    LevelDefinition(
      index: 3,
      requiredCompletions: 2,
      puzzles: [
        PuzzleDefinition(
          id: 'car_01',
          imagePath: 'assets/images/puzzles/car.png',
          category: PuzzleCategory.vehicles,
          grid: PuzzleGrid(rows: 3, columns: 3),
          displayName: 'Araba',
        ),
        PuzzleDefinition(
          id: 'sun_01',
          imagePath: 'assets/images/puzzles/sun.png',
          category: PuzzleCategory.nature,
          grid: PuzzleGrid(rows: 3, columns: 3),
          displayName: 'Güneş',
        ),
        PuzzleDefinition(
          id: 'lion_01',
          imagePath: 'assets/images/puzzles/lion.png',
          category: PuzzleCategory.animals,
          grid: PuzzleGrid(rows: 3, columns: 3),
          displayName: 'Aslan',
        ),
      ],
    ),
  ]);

  List<PuzzleDefinition> get puzzles => [
        for (final level in levels) ...level.puzzles,
      ];

  PuzzleDefinition byId(String puzzleId) => puzzles.firstWhere(
        (puzzle) => puzzle.id == puzzleId,
        orElse: () => throw ArgumentError.value(
          puzzleId,
          'puzzleId',
          'not in the catalogue',
        ),
      );

  /// Null instead of throwing, for ids that come from storage and may name
  /// a puzzle this build no longer has (§25.1).
  PuzzleDefinition? findById(String puzzleId) {
    for (final puzzle in puzzles) {
      if (puzzle.id == puzzleId) return puzzle;
    }
    return null;
  }

  LevelDefinition levelOf(String puzzleId) => levels.firstWhere(
        (level) => level.puzzles.any((puzzle) => puzzle.id == puzzleId),
        orElse: () => throw ArgumentError.value(
          puzzleId,
          'puzzleId',
          'not in the catalogue',
        ),
      );

  /// Every puzzle in the catalogue, in the order a child meets them.
  List<PuzzleDefinition> get allPuzzles => [
        for (final level in levels) ...level.puzzles,
      ];

  /// The album's shape (§25): puzzles grouped under their category.
  ///
  /// Only categories that actually have a puzzle appear, and they come in
  /// the order the enum declares them, so the album does not rearrange
  /// itself as a child earns stickers.
  Map<PuzzleCategory, List<PuzzleDefinition>> get byCategory {
    final grouped = <PuzzleCategory, List<PuzzleDefinition>>{};
    for (final category in PuzzleCategory.values) {
      final puzzles = allPuzzles
          .where((puzzle) => puzzle.category == category)
          .toList(growable: false);
      if (puzzles.isNotEmpty) grouped[category] = puzzles;
    }
    return Map.unmodifiable(grouped);
  }

  /// How many levels are open, given what has been finished (§4).
  ///
  /// A level opens when the one before it has [LevelDefinition
  /// .requiredCompletions] finished puzzles. The ladder never skips a rung:
  /// the moment one level falls short, everything above it stays shut.
  int unlockedLevelCount(Set<String> completedPuzzleIds) {
    var unlocked = 1;
    for (var i = 0; i < levels.length - 1; i++) {
      final level = levels[i];
      final done = level.puzzles
          .where((puzzle) => completedPuzzleIds.contains(puzzle.id))
          .length;
      if (done < level.requiredCompletions) break;
      unlocked = i + 2;
    }
    return unlocked;
  }

  bool isLevelUnlocked(int levelIndex, Set<String> completedPuzzleIds) =>
      levelIndex <= unlockedLevelCount(completedPuzzleIds);

  /// The next puzzle to offer: the first unfinished one inside the levels
  /// the child has opened. Null means everything available is done.
  ///
  /// [unavailable] holds puzzles that cannot be played right now — artwork
  /// that would not load (§14). They are skipped over, but unlike finished
  /// puzzles they unlock nothing.
  PuzzleDefinition? firstUnsolved(
    Set<String> completedPuzzleIds, {
    Set<String> unavailable = const {},
  }) {
    final unlocked = unlockedLevelCount(completedPuzzleIds);
    for (final level in levels.take(unlocked)) {
      for (final puzzle in level.puzzles) {
        if (completedPuzzleIds.contains(puzzle.id)) continue;
        if (unavailable.contains(puzzle.id)) continue;
        return puzzle;
      }
    }
    return null;
  }
}
