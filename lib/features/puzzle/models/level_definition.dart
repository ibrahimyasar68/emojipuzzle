import 'puzzle_definition.dart';

/// Merdivenin bir basamağı (§4, §13).
class LevelDefinition {
  const LevelDefinition({
    required this.index,
    required this.puzzles,
    required this.requiredCompletions,
  })  : assert(index >= 1, 'levels are numbered from 1'),
        assert(
          requiredCompletions >= 1,
          'a level that needs no completions would unlock the next one '
          'before the child played anything',
        );

  /// 1'den başlar; çocuğun ilerlemesi de böyle sayılır.
  final int index;

  final List<PuzzleDefinition> puzzles;

  /// Sonraki kademenin açılması için [puzzles] içinden kaç tanesinin
  /// bitirilmesi gerektiği.
  ///
  /// Sabit değil, veri: içerik büyür ve gömülü bir "2", bir kademe beş
  /// puzzle içerdiği gün sessizce yanlışa döner (§4).
  final int requiredCompletions;

  @override
  String toString() => 'LevelDefinition($index, ${puzzles.length} puzzles, '
      'needs $requiredCompletions)';
}
