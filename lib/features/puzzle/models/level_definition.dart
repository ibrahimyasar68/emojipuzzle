import 'puzzle_definition.dart';

/// One rung of the ladder (§4, §13).
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

  /// 1-based, the way the child's progress is counted.
  final int index;

  final List<PuzzleDefinition> puzzles;

  /// How many of [puzzles] must be finished before the next level opens.
  ///
  /// Data, not a constant: content grows, and a hard-coded "2" would
  /// quietly become wrong the day a level has five puzzles (§4).
  final int requiredCompletions;

  @override
  String toString() => 'LevelDefinition($index, ${puzzles.length} puzzles, '
      'needs $requiredCompletions)';
}
