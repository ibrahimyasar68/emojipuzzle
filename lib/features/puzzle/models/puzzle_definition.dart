import 'puzzle_category.dart';
import 'puzzle_grid.dart';

/// One puzzle in the catalogue (§13).
class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.grid,
    required this.displayName,
  });

  /// Stable id; also the sticker id (§25).
  final String id;

  /// Asset following the §34 naming: `assets/images/puzzles/apple.png`.
  final String imagePath;

  final PuzzleCategory category;
  final PuzzleGrid grid;

  /// Turkish, shown as-is. v1 is single-language, so there is no key to
  /// resolve and no l10n layer to resolve it with (§13).
  final String displayName;

  @override
  bool operator ==(Object other) => other is PuzzleDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PuzzleDefinition($id, $grid)';
}
