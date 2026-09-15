import '../models/puzzle_grid.dart';

/// Bir oyunun biçimi (K-15).
///
/// Bir araba beş safhadır: her safhada rastgele bir resim, her seferinde bir
/// boy büyük bir puzzle olarak gelir ve bitince arabanın bir parçası boyanır.
/// Arabanın beş parçası olduğu için beşinci safhadan sonra araba biter ve
/// sıradaki araba yeniden 2 × 2'den başlar. Üç araba bir oyundur.
abstract final class GameRules {
  /// Safhaların puzzle ebatları, satır × sütun: 2×2, 2×3, 3×3, 4×3, 4×4.
  static const List<PuzzleGrid> stageGrids = [
    PuzzleGrid(rows: 2, columns: 2),
    PuzzleGrid(rows: 2, columns: 3),
    PuzzleGrid(rows: 3, columns: 3),
    PuzzleGrid(rows: 4, columns: 3),
    PuzzleGrid(rows: 4, columns: 4),
  ];

  /// Bir arabanın kaç safha sürdüğü; boyama defterindeki her arabanın parça
  /// sayısıyla aynıdır (testle korunur).
  static int get stagesPerCar => stageGrids.length;

  /// Oyunun bitmesi için boyanan araba sayısı.
  static const int carsPerGame = 3;
}
