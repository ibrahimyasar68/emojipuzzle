import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/puzzle_image_loader.dart';
import '../../colouring/providers/colouring_book.dart';
import '../data/progress_repository.dart';
import '../data/puzzle_catalog.dart';
import '../engine/geometry/puzzle_generator.dart';
import '../engine/tray_shuffler.dart';
import '../models/app_state.dart';
import '../models/game_progress.dart';
import '../models/level_definition.dart';
import '../models/piece_runtime_state.dart';
import '../models/piece_status.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import '../models/puzzle_session_state.dart';

/// Tek bir puzzle oturumunun durumuna ve katalog içindeki yürüyüşe sahiptir
/// (§38, §39).
///
/// Bilerek burada olmayanlar: geometri, path kurma, tepsi yerleşimi, görsel
/// çözme, ses, kalıcılık ve çizim. Bu sınıf durumu tutar, engine ile
/// servisleri çağırır ve arayüze neyin değiştiğini söyler.
///
/// Yerleşime bağlı şeyler (board boyutu, path önbelleği, tepsi yerleşimi,
/// snap kararı) da durum değildir — ekran boyutunu bilene aittirler (§40).
class GameProvider extends ChangeNotifier {
  GameProvider({
    PuzzleGenerator? generator,
    TrayShuffler? shuffler,
    PuzzleImageLoader? imageLoader,
    ProgressRepository? progressRepository,
    AudioService? audio,
    ColouringBook? colouring,
    HapticService haptics = const HapticService(),
    PuzzleCatalog catalog = PuzzleCatalog.v1,
  })  : _generator = generator ?? PuzzleGenerator(),
        _shuffler = shuffler ?? TrayShuffler(),
        _imageLoader = imageLoader ?? PuzzleImageLoader(),
        _progressRepository = progressRepository,
        _audio = audio ?? AudioService(),
        _ownsAudio = audio == null,
        _colouring = colouring ?? ColouringBook(),
        _ownsColouring = colouring == null,
        _haptics = haptics,
        _catalog = catalog;

  final PuzzleGenerator _generator;
  final TrayShuffler _shuffler;
  final PuzzleImageLoader _imageLoader;

  /// Null, bu oturumun hiçbir şey saklamadığı anlamına gelir: testlerde
  /// işe yarar ve depo açılamazsa uygulama yine de oynanır.
  final ProgressRepository? _progressRepository;

  /// Çocuğun duyduğu ve hissettiği şey durumun bir sonucudur, bu yüzden
  /// burada tetiklenir (§39 servis çağırmaya izin verir). Board üzerinde bir
  /// noktada *gördüğü* şey ekran koordinatı ister ve widget'larda kalır.
  final AudioService _audio;
  final bool _ownsAudio;
  final HapticService _haptics;

  /// Her bitişten sonra bir parçası boyanan araba (§24.2). Durumu puzzle'ın
  /// değildir; burada yalnızca ilerleme sıfırlanınca temizlensin diye durur
  /// (§26).
  final ColouringBook _colouring;
  final bool _ownsColouring;

  final PuzzleCatalog _catalog;

  Future<void> _lastWrite = Future<void>.value();

  AppState _appState = AppState.loading;
  PuzzleSessionState _sessionState = PuzzleSessionState.idle;
  GameProgress _progress = const GameProgress.initial();

  PuzzleDefinition? _definition;
  List<PuzzlePiece> _pieces = const [];
  Map<int, PieceRuntimeState> _runtime = const {};
  ui.Image? _image;
  String? _imagePath;

  /// Görseli yüklenemeyen puzzle'lar. Çocuğa hata olarak gösterilmek yerine
  /// sessizce sıradan çıkarılırlar (§14).
  final Set<String> _unloadable = <String>{};

  AppState get appState => _appState;
  PuzzleSessionState get sessionState => _sessionState;

  PuzzleCatalog get catalog => _catalog;
  GameProgress get progress => _progress;
  AudioService get audio => _audio;
  ColouringBook get colouring => _colouring;

  PuzzleDefinition get puzzle =>
      _definition ?? (throw StateError('no puzzle started yet'));

  PuzzleGrid get grid => puzzle.grid;

  List<PuzzlePiece> get pieces => _pieces;

  ui.Image? get image => _image;

  // ── Merdiven (§4) ─────────────────────────────────────────────────────

  int get unlockedLevelCount =>
      _catalog.unlockedLevelCount(_progress.completedPuzzleIds);

  List<LevelDefinition> get unlockedLevels =>
      _catalog.levels.take(unlockedLevelCount).toList();

  bool isLevelUnlocked(int levelIndex) =>
      _catalog.isLevelUnlocked(levelIndex, _progress.completedPuzzleIds);

  bool isPuzzleCompleted(String puzzleId) => _progress.isCompleted(puzzleId);

  /// Sunulacak sonraki puzzle; açık olan her şey bittiyse null.
  ///
  /// Görseli eksik olan puzzle atlanır, ama yine de oynanmamış sayılır —
  /// hiçbir şeyin kilidini açmamalıdır (§14).
  PuzzleDefinition? get nextPuzzle => _catalog.firstUnsolved(
        _progress.completedPuzzleIds,
        unavailable: _unloadable,
      );

  /// §4 — bitirilmiş bütün puzzle'lar, katalog sırasında. Serbest Mod'un
  /// sunduğu bunlardır ve albümdeki çıkartmaların tam olarak aynısıdırlar
  /// (§25).
  List<PuzzleDefinition> get replayablePuzzles => [
        for (final level in _catalog.levels)
          for (final puzzle in level.puzzles)
            if (_progress.isCompleted(puzzle.id) &&
                !_unloadable.contains(puzzle.id))
              puzzle,
      ];

  /// Geriye yeni bir şey kalmayıp oyun tekrarlarla yaşamaya başlayınca
  /// true olur.
  bool get isInFreeMode => nextPuzzle == null && replayablePuzzles.isNotEmpty;

  /// Serbest Mod'da sırada sunulacak bitirilmiş puzzle.
  ///
  /// En son oynananın bir sonrakidir; böylece oyna'ya basmayı sürdüren bir
  /// çocuk aynı resmi almak yerine albümde yürür (§4).
  PuzzleDefinition? get nextReplay {
    final replayable = replayablePuzzles;
    if (replayable.isEmpty) return null;

    final lastPlayed = _progress.lastPlayedPuzzleId;
    final at = replayable.indexWhere((puzzle) => puzzle.id == lastPlayed);
    return replayable[(at + 1) % replayable.length];
  }

  // ── Tek oturum ────────────────────────────────────────────────────────

  PieceRuntimeState stateOf(int pieceId) =>
      _runtime[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'unknown piece'));

  /// Tepside duran parçalar, yuva sırasında (§16.2).
  ///
  /// Havadaki bir parça burada değildir: sürükleme katmanına aittir ve geri
  /// dönene kadar yuvası boş kalır (§10).
  List<PuzzlePiece> get trayPieces {
    final waiting = _pieces
        .where((p) => _runtime[p.id]!.status == PieceStatus.inTray)
        .toList();
    waiting.sort(
      (a, b) => _runtime[a.id]!
          .traySlotIndex
          .compareTo(_runtime[b.id]!.traySlotIndex),
    );
    return waiting;
  }

  List<PuzzlePiece> get placedPieces => _pieces
      .where((p) => _runtime[p.id]!.status == PieceStatus.placed)
      .toList();

  int get placedCount => placedPieces.length;

  bool get isComplete => _pieces.isNotEmpty && placedCount == _pieces.length;

  /// Bir puzzle kurar ve görselini hazırlar.
  ///
  /// Görsel yüklenemezse çocuk hiçbir hata görmez: puzzle sıradan çıkarılır
  /// ve yerine oynanabilir olan bir sonraki başlar. Hiçbir şey yüklenemezse
  /// uygulama [AppState.error] durumuna yerleşir ve ekran sakin ve boş kalır
  /// (§14, §2).
  Future<void> startPuzzle(PuzzleDefinition definition) async {
    _appState = AppState.loading;
    _sessionState = PuzzleSessionState.idle;
    _definition = definition;
    _pieces = _generator.generate(definition.grid);

    final slots = _shuffler.assignSlots(definition.grid.pieceCount);
    _runtime = Map.unmodifiable({
      for (final piece in _pieces)
        piece.id: PieceRuntimeState(
          pieceId: piece.id,
          traySlotIndex: slots[piece.id],
        ),
    });
    _progress = _progress.copyWith(lastPlayedPuzzleId: definition.id);
    // Nerede olduğumuz, uygulama bu puzzle'ın sonuna hiç varmasa bile
    // saklanmaya değer (§25).
    _persist();
    notifyListeners();

    final ui.Image image;
    try {
      image = await _imageLoader.load(definition.imagePath);
    } catch (error, stackTrace) {
      _unloadable.add(definition.id);
      debugPrint('Puzzle ${definition.id}: ${definition.imagePath} '
          'could not be loaded — skipping it. $error');
      assert(() {
        debugPrintStack(stackTrace: stackTrace);
        return true;
      }());

      final fallback = nextPuzzle;
      if (fallback == null) {
        _appState = AppState.error;
        notifyListeners();
        return;
      }
      return startPuzzle(fallback);
    }

    final previousPath = _imagePath;
    if (previousPath != null && previousPath != definition.imagePath) {
      _imageLoader.evict(previousPath);
    }
    _image = image;
    _imagePath = definition.imagePath;
    _appState = AppState.ready;
    notifyListeners();
  }

  /// İlerler: bitirilmemiş sonraki puzzle ya da bitirilmiş bir tanesi
  /// yeniden.
  ///
  /// Burada sessizce dönmek, hepsi bitince uygulamayı temelli boş bir
  /// ekranda bırakıyordu — "her şeyi bitirdin" ile "hâlâ yükleniyor" birbirine
  /// tıpatıp benziyordu. §4'ün o noktada istediği şey Serbest Mod'dur ve aynı
  /// zamanda dürüst cevap budur: oynanacak her zaman bir şey vardır (§2).
  Future<void> startNextPuzzle() async {
    final next = nextPuzzle ?? nextReplay;
    if (next == null) {
      // Yeni bir şey de yok, bitirilmiş bir şey de: buraya gelmenin tek
      // yolu, görselleri hiç yüklenmeyen bir katalogdur (§14).
      _appState = AppState.error;
      notifyListeners();
      return;
    }
    await startPuzzle(next);
  }

  // ── İlerleme (§25, §26) ───────────────────────────────────────────────

  /// Kayıtlı ilerlemeyi yükler ve çocuğun bıraktığı yerden devam eder (§25).
  Future<void> resume() async {
    final repository = _progressRepository;
    if (repository != null) {
      final stored = await repository.load();
      // Doğru olan, bitirilmiş puzzle'lardır; açık kademe burada onlardan
      // yeniden türetilir, böylece saklanmış bir kademe kataloğun izin
      // verdiğinden daha cömert olamaz (§4).
      _progress = stored.copyWith(
        unlockedLevel: _catalog.unlockedLevelCount(stored.completedPuzzleIds),
      );
      notifyListeners();
    }

    final lastPlayed = _progress.lastPlayedPuzzleId;
    final unfinished =
        lastPlayed == null ? null : _catalog.findById(lastPlayed);
    if (unfinished != null &&
        !_progress.isCompleted(unfinished.id) &&
        !_unloadable.contains(unfinished.id) &&
        isLevelUnlocked(_catalog.levelOf(unfinished.id).index)) {
      await startPuzzle(unfinished);
      return;
    }
    await startNextPuzzle();
  }

  /// İlerlemeyi yazar. Faz 14 bunu ekrandan çıkmadan önce çağırır (§30).
  Future<void> saveProgress() async {
    final repository = _progressRepository;
    if (repository == null) return;
    try {
      await repository.save(_progress);
    } on Object catch (error) {
      // Bir yazmayı kaybetmek, çocuğun oyununu bölmeye değmez (§2).
      debugPrint('Progress could not be saved: $error');
    }
  }

  /// Son arka plan yazmasını bekler. Testler ve Faz 14 bunu kullanır.
  Future<void> get pendingWrite => _lastWrite;

  void _persist() {
    _lastWrite = saveProgress();
    unawaited(_lastWrite);
  }

  /// §26 — temiz bir sayfaya dönüş. Ebeveyn alanından ulaşılır (§33).
  Future<void> clearProgress() async {
    _progress = const GameProgress.initial();
    notifyListeners();
    await _progressRepository?.clear();
    // Boyama defteri de ilk arabaya, boş döner.
    await _colouring.clear();
  }

  // ── Oynama (§10, §17, §18, §19) ───────────────────────────────────────

  /// Çocuk bir parça aldı.
  ///
  /// Bir kez, burada haber verir — her işaretçi hareketinde değil. Hareket
  /// eden konum, sürükleme katmanının kendi notifier'ı üzerinden gider
  /// (§17).
  void beginDrag(int pieceId) {
    final current = stateOf(pieceId);
    // Yerleşmiş parça kilitlidir; yeniden sökülemez (§10).
    if (current.status != PieceStatus.inTray) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(status: PieceStatus.dragging),
    });
    _sessionState = PuzzleSessionState.dragging;
    // §17 — parça yerinden çıktığı anda küçük bir dokunuş.
    _haptics.selection();
    notifyListeners();
  }

  /// Bırakma hedefindeydi; parça artık yuvasına uçuyor (§18).
  void beginSnap(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status != PieceStatus.dragging) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(
        status: PieceStatus.snapping,
        clearDragOffset: true,
      ),
    });
    _sessionState = PuzzleSessionState.snapping;
    notifyListeners();
  }

  /// §21 — oyun beklemekten vazgeçer ve parçayı kendisi yerleştirir.
  ///
  /// Doğrudan tepsiden yerleşme animasyonuna geçer: sürükleme olmadığı için
  /// hissedilecek bir şey de, geri alınacak bir şey de yoktur.
  void beginAutoPlace(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status != PieceStatus.inTray) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(status: PieceStatus.snapping),
    });
    _sessionState = PuzzleSessionState.snapping;
    notifyListeners();
  }

  /// Bırakma ıskaladı. Parça evine döner ve sayacı artar (§19).
  ///
  /// Başka hiçbir şey olmaz: puan yok, ses yok, azarlama yok (§20). Sayaç
  /// yalnızca bir sonraki denemeyi kolaylaştırmak için vardır.
  void dropFailed(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status == PieceStatus.placed) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(
        status: PieceStatus.inTray,
        clearDragOffset: true,
        failedAttempts: current.failedAttempts + 1,
      ),
    });
    _sessionState = PuzzleSessionState.idle;
    notifyListeners();
  }

  /// Sürüklenen bir parçayı kendi yuvasına gönderir (§10, §16.2).
  ///
  /// Faz 14'teki lifecycle iptali bunu kullanır. Ne bu, ne de sıradan bir
  /// bırakma başarısız deneme sayılır (§28).
  void returnToTray(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status != PieceStatus.dragging) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(
        status: PieceStatus.inTray,
        clearDragOffset: true,
      ),
    });
    _sessionState = PuzzleSessionState.idle;
    notifyListeners();
  }

  /// Bir parçayı yuvasına kilitler ve sonuncusuysa puzzle'ı bitirir.
  void markPlaced(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status == PieceStatus.placed) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(
        status: PieceStatus.placed,
        clearDragOffset: true,
        // §19 — sayaç parçaya aittir ve onunla birlikte ölür.
        failedAttempts: 0,
      ),
    });

    if (isComplete) {
      _sessionState = PuzzleSessionState.completed;
      // Merdivenin sonraki basamağını açan şey, bitirmektir (§4).
      _progress = _progress.withCompleted(puzzle.id).copyWith(
            unlockedLevel: _catalog.unlockedLevelCount({
              ..._progress.completedPuzzleIds,
              puzzle.id,
            }),
          );
      _persist();
      // Bitiş ezgisi parçanın kendi 'pop' sesinin yerine geçer: son parçada
      // aynı anda iki ses, ödül değil gürültü olurdu (§22, §23).
      _audio.playPuzzleComplete();
      _haptics.medium();
    } else {
      _sessionState = PuzzleSessionState.idle;
      _audio.playPieceSnap();
      _haptics.light();
    }
    notifyListeners();
  }

  /// Bütün parçaları yuvalarına geri gönderir, puzzle aynı kalır.
  void restart() {
    _runtime = Map.unmodifiable({
      for (final entry in _runtime.entries)
        entry.key: PieceRuntimeState(
          pieceId: entry.value.pieceId,
          traySlotIndex: entry.value.traySlotIndex,
        ),
    });
    _sessionState = PuzzleSessionState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    _image = null;
    _imagePath = null;
    _imageLoader.evictAll();
    // Yalnızca kendi kurduğumuzu serbest bırakırız: dışarıdan verilen bir
    // servis uygulamaya aittir.
    if (_ownsAudio) _audio.dispose();
    if (_ownsColouring) _colouring.dispose();
    super.dispose();
  }
}
