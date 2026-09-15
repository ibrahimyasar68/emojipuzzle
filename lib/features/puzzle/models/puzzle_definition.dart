import 'puzzle_category.dart';

/// Katalogdaki tek bir resim (§13).
///
/// Ebadı yoktur: puzzle'ın kaç parça olduğunu resim değil, oyunun safhası
/// belirler (K-15).
class PuzzleDefinition {
  const PuzzleDefinition({
    required this.id,
    required this.imagePath,
    required this.category,
    required this.displayName,
  });

  /// Değişmeyen kimlik; aynı zamanda çıkartma kimliğidir (§25).
  final String id;

  /// §34 adlandırmasına uyan asset: `assets/images/puzzles/apple.png`.
  final String imagePath;

  final PuzzleCategory category;

  /// Türkçe, olduğu gibi gösterilir. v1 tek dillidir; çözülecek bir anahtar
  /// da, onu çözecek bir l10n katmanı da yoktur (§13).
  final String displayName;

  @override
  bool operator ==(Object other) => other is PuzzleDefinition && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'PuzzleDefinition($id)';
}
