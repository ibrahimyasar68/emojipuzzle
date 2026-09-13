import 'puzzle_category.dart';
import 'puzzle_grid.dart';

/// Katalogdaki tek bir puzzle (§13).
class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.grid,
    required this.displayName,
  });

  /// Değişmeyen kimlik; aynı zamanda çıkartma kimliğidir (§25).
  final String id;

  /// §34 adlandırmasına uyan asset: `assets/images/puzzles/apple.png`.
  final String imagePath;

  final PuzzleCategory category;
  final PuzzleGrid grid;

  /// Türkçe, olduğu gibi gösterilir. v1 tek dillidir; çözülecek bir anahtar
  /// da, onu çözecek bir l10n katmanı da yoktur (§13).
  final String displayName;

  @override
  bool operator ==(Object other) => other is PuzzleDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PuzzleDefinition($id, $grid)';
}
