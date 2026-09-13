/// Çocuğun şimdiye kadar başardıkları (§25).
///
/// Kalıcılık Faz 8'de geldi; saklanan yapı budur.
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

  /// Saklanan yapı değiştiğinde artırılır; uyuşmazlıkta ne yapılacağını
  /// §25.1 söyler.
  static const int currentSchemaVersion = 1;

  final int unlockedLevel;
  final Set<String> completedPuzzleIds;

  /// Uygulama yeniden açıldığında nereden devam edileceği (§25).
  final String? lastPlayedPuzzleId;

  final int schemaVersion;

  /// Türetilir, asla saklanmaz (§25): tamamlanan puzzle *zaten* kendi
  /// çıkartmasıdır, dolayısıyla bununla desenkron olabilecek ikinci bir
  /// küme yoktur.
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

  /// Bir puzzle'ı tamamlanmış işaretler. Aynı puzzle'ı ikinci kez bitirmek
  /// hiçbir şeyi değiştirmez — tekrar oynamak her zaman serbesttir ve hiçbir
  /// bedeli yoktur (§4).
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
