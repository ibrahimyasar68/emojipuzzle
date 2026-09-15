import '../models/puzzle_category.dart';
import '../models/puzzle_definition.dart';

/// Oyunun resimleri (§13, K-15).
///
/// JSON değil Dart: on sekiz resim bir ayrıştırıcıya değmez ve derleyici,
/// bir yazım hatasını JSON dosyasının ancak çocuğun cihazında patlayacağı
/// yerde yakalar.
///
/// Artık bir merdiven değil, bir havuzdur: kademe de kilit açma da yoktur.
/// Her safhada bu havuzdan rastgele bir resim gelir ve puzzle'ın ebadını
/// safha belirler (`GameRules`). Sıra yalnızca albümün ve testlerin işine
/// yarar.
class PuzzleCatalog {
  const PuzzleCatalog(this.puzzles);

  final List<PuzzleDefinition> puzzles;

  static const PuzzleCatalog v1 = PuzzleCatalog([
    PuzzleDefinition(
      id: 'apple_01',
      imagePath: 'assets/images/puzzles/apple.png',
      category: PuzzleCategory.fruits,
      displayName: 'Elma',
    ),
    PuzzleDefinition(
      id: 'cat_01',
      imagePath: 'assets/images/puzzles/cat.png',
      category: PuzzleCategory.animals,
      displayName: 'Kedi',
    ),
    PuzzleDefinition(
      id: 'ball_01',
      imagePath: 'assets/images/puzzles/ball.png',
      category: PuzzleCategory.shapes,
      displayName: 'Top',
    ),
    PuzzleDefinition(
      id: 'strawberry_01',
      imagePath: 'assets/images/puzzles/strawberry.png',
      category: PuzzleCategory.fruits,
      displayName: 'Çilek',
    ),
    PuzzleDefinition(
      id: 'moon_01',
      imagePath: 'assets/images/puzzles/moon.png',
      category: PuzzleCategory.nature,
      displayName: 'Ay',
    ),
    PuzzleDefinition(
      id: 'sheep_01',
      imagePath: 'assets/images/puzzles/sheep.png',
      category: PuzzleCategory.animals,
      displayName: 'Koyun',
    ),
    PuzzleDefinition(
      id: 'banana_01',
      imagePath: 'assets/images/puzzles/banana.png',
      category: PuzzleCategory.fruits,
      displayName: 'Muz',
    ),
    PuzzleDefinition(
      id: 'dog_01',
      imagePath: 'assets/images/puzzles/dog.png',
      category: PuzzleCategory.animals,
      displayName: 'Köpek',
    ),
    PuzzleDefinition(
      id: 'bus_01',
      imagePath: 'assets/images/puzzles/bus.png',
      category: PuzzleCategory.vehicles,
      displayName: 'Otobüs',
    ),
    PuzzleDefinition(
      id: 'watermelon_01',
      imagePath: 'assets/images/puzzles/watermelon.png',
      category: PuzzleCategory.fruits,
      displayName: 'Karpuz',
    ),
    PuzzleDefinition(
      id: 'bicycle_01',
      imagePath: 'assets/images/puzzles/bicycle.png',
      category: PuzzleCategory.vehicles,
      displayName: 'Bisiklet',
    ),
    PuzzleDefinition(
      id: 'turtle_01',
      imagePath: 'assets/images/puzzles/turtle.png',
      category: PuzzleCategory.animals,
      displayName: 'Kaplumbağa',
    ),
    PuzzleDefinition(
      id: 'car_01',
      imagePath: 'assets/images/puzzles/car.png',
      category: PuzzleCategory.vehicles,
      displayName: 'Araba',
    ),
    PuzzleDefinition(
      id: 'sun_01',
      imagePath: 'assets/images/puzzles/sun.png',
      category: PuzzleCategory.nature,
      displayName: 'Güneş',
    ),
    PuzzleDefinition(
      id: 'lion_01',
      imagePath: 'assets/images/puzzles/lion.png',
      category: PuzzleCategory.animals,
      displayName: 'Aslan',
    ),
    PuzzleDefinition(
      id: 'pineapple_01',
      imagePath: 'assets/images/puzzles/pineapple.png',
      category: PuzzleCategory.fruits,
      displayName: 'Ananas',
    ),
    PuzzleDefinition(
      id: 'airplane_01',
      imagePath: 'assets/images/puzzles/airplane.png',
      category: PuzzleCategory.vehicles,
      displayName: 'Uçak',
    ),
    PuzzleDefinition(
      id: 'saturn_01',
      imagePath: 'assets/images/puzzles/saturn.png',
      category: PuzzleCategory.nature,
      displayName: 'Satürn',
    ),
  ]);

  PuzzleDefinition byId(String puzzleId) => puzzles.firstWhere(
        (puzzle) => puzzle.id == puzzleId,
        orElse: () => throw ArgumentError.value(
          puzzleId,
          'puzzleId',
          'not in the catalogue',
        ),
      );

  /// Hata fırlatmak yerine null; depodan gelen ve bu sürümde artık
  /// bulunmayan bir resmi adlandırabilecek kimlikler için (§25.1).
  PuzzleDefinition? findById(String puzzleId) {
    for (final puzzle in puzzles) {
      if (puzzle.id == puzzleId) return puzzle;
    }
    return null;
  }

  /// Albümün biçimi (§25): resimler kategorilerine göre gruplanmış.
  ///
  /// Yalnızca gerçekten resmi olan kategoriler görünür ve enum'daki
  /// sırayla gelirler; böylece çocuk çıkartma kazandıkça albüm kendini
  /// yeniden dizmez.
  Map<PuzzleCategory, List<PuzzleDefinition>> get byCategory {
    final grouped = <PuzzleCategory, List<PuzzleDefinition>>{};
    for (final category in PuzzleCategory.values) {
      final inCategory = puzzles
          .where((puzzle) => puzzle.category == category)
          .toList(growable: false);
      if (inCategory.isNotEmpty) grouped[category] = inCategory;
    }
    return Map.unmodifiable(grouped);
  }
}
