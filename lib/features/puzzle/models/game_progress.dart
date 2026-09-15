/// Çocuğun şimdiye kadar başardıkları ve oyunda nerede olduğu (§25, K-15).
class GameProgress {
  const GameProgress({
    required this.completedPuzzleIds,
    this.lastPlayedPuzzleId,
    this.stage = 0,
    this.carsFinished = 0,
    this.playedThisGame = const {},
    this.currentSolved = false,
    this.schemaVersion = currentSchemaVersion,
  })  : assert(stage >= 0, 'stages are counted from 0'),
        assert(carsFinished >= 0, 'cars are counted from 0');

  const GameProgress.initial()
      : completedPuzzleIds = const {},
        lastPlayedPuzzleId = null,
        stage = 0,
        carsFinished = 0,
        playedThisGame = const {},
        currentSolved = false,
        schemaVersion = currentSchemaVersion;

  /// Saklanan yapı değiştiğinde artırılır; uyuşmazlıkta ne yapılacağını
  /// §25.1 söyler.
  ///
  /// 2 — K-15: kademe gitti, safha ve araba geldi. 1'den geçişte çıkartmalar
  /// korunur, oyun baştan başlar.
  static const int currentSchemaVersion = 2;

  /// Bir kez bitirilmiş her resim. Albümün çıkartmaları bunlardır (§25).
  final Set<String> completedPuzzleIds;

  /// Oynanan ya da en son oynanan resim; uygulama yeniden açılınca bu
  /// safhada kaldığı yer (§25).
  final String? lastPlayedPuzzleId;

  /// Şu anki arabanın kaçıncı safhası, 0'dan (K-15).
  final int stage;

  /// Bu oyunda biten arabalar (K-15).
  final int carsFinished;

  /// Bu oyunda gelmiş resimler; aynı oyunda tekrar gelmezler (K-15).
  final Set<String> playedThisGame;

  /// [lastPlayedPuzzleId] çözüldü ama safhanın dizisi (kutlama, balon,
  /// çıkartma, boyama) bitmeden uygulama kapandı. Açılışta safha
  /// ilerletilir; çocuk çözülmüş bir board'a dönmez.
  final bool currentSolved;

  final int schemaVersion;

  /// Türetilir, asla saklanmaz (§25): tamamlanan resim *zaten* kendi
  /// çıkartmasıdır, dolayısıyla bununla desenkron olabilecek ikinci bir
  /// küme yoktur.
  Set<String> get unlockedStickerIds => completedPuzzleIds;

  bool isCompleted(String puzzleId) => completedPuzzleIds.contains(puzzleId);

  GameProgress copyWith({
    Set<String>? completedPuzzleIds,
    String? lastPlayedPuzzleId,
    bool clearLastPlayed = false,
    int? stage,
    int? carsFinished,
    Set<String>? playedThisGame,
    bool? currentSolved,
  }) {
    return GameProgress(
      completedPuzzleIds: completedPuzzleIds ?? this.completedPuzzleIds,
      lastPlayedPuzzleId: clearLastPlayed
          ? null
          : (lastPlayedPuzzleId ?? this.lastPlayedPuzzleId),
      stage: stage ?? this.stage,
      carsFinished: carsFinished ?? this.carsFinished,
      playedThisGame: playedThisGame ?? this.playedThisGame,
      currentSolved: currentSolved ?? this.currentSolved,
      schemaVersion: schemaVersion,
    );
  }

  /// Bir resmi bitirilmiş işaretler. Aynı resmi ikinci kez bitirmek
  /// çıkartmaları değiştirmez — tekrar oynamak her zaman serbesttir ve hiçbir
  /// bedeli yoktur (§4).
  GameProgress withCompleted(String puzzleId) => copyWith(
        completedPuzzleIds: {...completedPuzzleIds, puzzleId},
        lastPlayedPuzzleId: puzzleId,
        currentSolved: true,
      );

  @override
  bool operator ==(Object other) =>
      other is GameProgress &&
      other.lastPlayedPuzzleId == lastPlayedPuzzleId &&
      other.stage == stage &&
      other.carsFinished == carsFinished &&
      other.currentSolved == currentSolved &&
      other.schemaVersion == schemaVersion &&
      _sameSet(other.completedPuzzleIds, completedPuzzleIds) &&
      _sameSet(other.playedThisGame, playedThisGame);

  static bool _sameSet(Set<String> a, Set<String> b) =>
      a.length == b.length && a.containsAll(b);

  @override
  int get hashCode => Object.hash(
        lastPlayedPuzzleId,
        stage,
        carsFinished,
        currentSolved,
        schemaVersion,
        Object.hashAllUnordered(completedPuzzleIds),
        Object.hashAllUnordered(playedThisGame),
      );

  @override
  String toString() => 'GameProgress(stage $stage, car $carsFinished, '
      '${completedPuzzleIds.length} stickers, last $lastPlayedPuzzleId'
      '${currentSolved ? ' (solved)' : ''})';
}
