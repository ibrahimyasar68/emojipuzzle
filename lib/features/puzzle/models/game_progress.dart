/// What the child has achieved so far (§25).
///
/// Persistence arrives in Faz 8; this is the shape that will be stored.
class GameProgress {
  const GameProgress({
    required this.unlockedLevel,
    required this.completedPuzzleIds,
    this.lastPlayedPuzzleId,
    this.schemaVersion = currentSchemaVersion,
  }) : assert(unlockedLevel >= 1, 'level 1 is always open');

  const GameProgress.initial()
      : unlockedLevel = 1,
        completedPuzzleIds = const {},
        lastPlayedPuzzleId = null,
        schemaVersion = currentSchemaVersion;

  /// Bump when the stored shape changes; §25.1 says what to do on a
  /// mismatch.
  static const int currentSchemaVersion = 1;

  final int unlockedLevel;
  final Set<String> completedPuzzleIds;

  /// Where to pick up when the app is opened again (§25).
  final String? lastPlayedPuzzleId;

  final int schemaVersion;

  /// Derived, never stored (§25): a finished puzzle *is* its sticker, so
  /// there is no second set that can drift out of step with this one.
  Set<String> get unlockedStickerIds => completedPuzzleIds;

  bool isCompleted(String puzzleId) => completedPuzzleIds.contains(puzzleId);

  GameProgress copyWith({
    int? unlockedLevel,
    Set<String>? completedPuzzleIds,
    String? lastPlayedPuzzleId,
    bool clearLastPlayed = false,
  }) {
    return GameProgress(
      unlockedLevel: unlockedLevel ?? this.unlockedLevel,
      completedPuzzleIds: completedPuzzleIds ?? this.completedPuzzleIds,
      lastPlayedPuzzleId: clearLastPlayed
          ? null
          : (lastPlayedPuzzleId ?? this.lastPlayedPuzzleId),
      schemaVersion: schemaVersion,
    );
  }

  /// Marks a puzzle finished. Completing the same puzzle twice changes
  /// nothing — replaying is always allowed and never costs anything (§4).
  GameProgress withCompleted(String puzzleId) => copyWith(
        completedPuzzleIds: {...completedPuzzleIds, puzzleId},
        lastPlayedPuzzleId: puzzleId,
      );

  @override
  bool operator ==(Object other) =>
      other is GameProgress &&
      other.unlockedLevel == unlockedLevel &&
      other.lastPlayedPuzzleId == lastPlayedPuzzleId &&
      other.schemaVersion == schemaVersion &&
      other.completedPuzzleIds.length == completedPuzzleIds.length &&
      other.completedPuzzleIds.containsAll(completedPuzzleIds);

  @override
  int get hashCode => Object.hash(
        unlockedLevel,
        lastPlayedPuzzleId,
        schemaVersion,
        Object.hashAllUnordered(completedPuzzleIds),
      );

  @override
  String toString() => 'GameProgress(level $unlockedLevel, '
      '${completedPuzzleIds.length} done, last $lastPlayedPuzzleId)';
}
