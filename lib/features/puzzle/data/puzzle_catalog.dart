import '../models/level_definition.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_grid.dart';

/// Oyunun içeriği ve içinde ilerleme kuralları (§4, §13).
///
/// JSON değil Dart: dokuz puzzle bir ayrıştırıcıya değmez ve derleyici,
/// griddeki bir yazım hatasını JSON dosyasının ancak çocuğun cihazında
/// patlayacağı yerde yakalar. İçerik tek ekrana sığmamaya başladığında JSON
/// ilginç hale gelir (§13).
class PuzzleCatalog {
  const PuzzleCatalog(this.levels);

  final List<LevelDefinition> levels;

  /// K-1 = A: üç kademe, dokuz puzzle. Engine 1×3 ve 3×4'ü desteklemeye
  /// devam eder — bunlar engine yetenekleridir, içerik değil (§4).
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

  /// Hata fırlatmak yerine null; depodan gelen ve bu sürümde artık
  /// bulunmayan bir puzzle'ı adlandırabilecek kimlikler için (§25.1).
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

  /// Katalogdaki bütün puzzle'lar, çocuğun onlarla karşılaşma sırasıyla.
  List<PuzzleDefinition> get allPuzzles => [
        for (final level in levels) ...level.puzzles,
      ];

  /// Albümün biçimi (§25): puzzle'lar kategorilerine göre gruplanmış.
  ///
  /// Yalnızca gerçekten puzzle'ı olan kategoriler görünür ve enum'daki
  /// sırayla gelirler; böylece çocuk çıkartma kazandıkça albüm kendini
  /// yeniden dizmez.
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

  /// Tamamlananlara göre kaç kademenin açık olduğu (§4).
  ///
  /// Bir kademe, kendisinden öncekinde [LevelDefinition.requiredCompletions]
  /// kadar puzzle bitince açılır. Merdiven hiçbir basamağı atlamaz: bir
  /// kademe eksik kaldığı anda üstündeki her şey kapalı kalır.
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

  /// Sunulacak sonraki puzzle: çocuğun açtığı kademeler içindeki ilk
  /// bitirilmemiş olan. Null, erişilebilir her şeyin bittiği anlamına gelir.
  ///
  /// [unavailable], şu an oynanamayacak puzzle'ları tutar — yüklenemeyen
  /// görseller (§14). Atlanırlar, ama tamamlananların aksine hiçbir şeyin
  /// kilidini açmazlar.
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
