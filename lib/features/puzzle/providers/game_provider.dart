import 'dart:async';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/puzzle_image_loader.dart';
import '../../colouring/providers/colouring_book.dart';
import '../data/game_rules.dart';
import '../data/progress_repository.dart';
import '../data/puzzle_catalog.dart';
import '../engine/geometry/puzzle_generator.dart';
import '../engine/tray_shuffler.dart';
import '../models/app_state.dart';
import '../models/game_progress.dart';
import '../models/piece_runtime_state.dart';
import '../models/piece_status.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import '../models/puzzle_session_state.dart';

/// Tek bir puzzle oturumunun durumuna ve oyunun safha ile araba yürüyüşüne
/// sahiptir (§38, §39, K-15).
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
    Random? random,
  })  : _generator = generator ?? PuzzleGenerator(),
        _shuffler = shuffler ?? TrayShuffler(),
        _imageLoader = imageLoader ?? PuzzleImageLoader(),
        _progressRepository = progressRepository,
        _audio = audio ?? AudioService(),
        _ownsAudio = audio == null,
        _colouring = colouring ?? ColouringBook(),
        _ownsColouring = colouring == null,
        _haptics = haptics,
        _catalog = catalog,
        _random = random ?? Random();

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

  /// Resmi seçen zar (K-15). Testler tohumlu bir tane verir.
  final Random _random;

  Future<void> _lastWrite = Future<void>.value();

  AppState _appState = AppState.loading;
  PuzzleSessionState _sessionState = PuzzleSessionState.idle;
  GameProgress _progress = const GameProgress.initial();

  PuzzleDefinition? _definition;
  PuzzleGrid? _grid;
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

  /// Oynanan puzzle'ın ebadı; resmin değil, safhanın (K-15).
  PuzzleGrid get grid => _grid ?? (throw StateError('no puzzle started yet'));

  List<PuzzlePiece> get pieces => _pieces;

  ui.Image? get image => _image;

  // ── Oyun: safhalar ve arabalar (K-15) ─────────────────────────────────

  /// Şu anki arabanın kaçıncı safhası, 0'dan.
  int get stage => _progress.stage;

  /// Bu safhanın puzzle ebadı.
  PuzzleGrid get stageGrid => GameRules.stageGrids[_progress.stage];

  /// Bu oyunda biten arabalar.
  int get carsFinished => _progress.carsFinished;

  /// Bu safha arabanın son safhası mı: boyamadan sonra araba gider.
  bool get isLastStageOfCar => _progress.stage == GameRules.stagesPerCar - 1;

  /// Üç araba bitti: sırada oyun sonu kutlaması ve yeni bir oyun var.
  bool get isGameOver => _progress.carsFinished >= GameRules.carsPerGame;

  bool isPuzzleCompleted(String puzzleId) => _progress.isCompleted(puzzleId);

  /// Sıradaki resim, havuzdan rastgele (K-15).
  ///
  /// Bir oyunda aynı resim iki kez gelmez. Havuz bir oyuna yetmezse tekrar
  /// serbesttir, ama az önce oynanan hemen yeniden gelmez. Görseli
  /// yüklenemeyen resim hiç gelmez (§14). Oynanabilecek hiçbir şey yoksa
  /// null.
  PuzzleDefinition? _pickPicture() {
    final pool = [
      for (final puzzle in _catalog.puzzles)
        if (!_unloadable.contains(puzzle.id)) puzzle,
    ];
    if (pool.isEmpty) return null;

    final fresh = [
      for (final puzzle in pool)
        if (!_progress.playedThisGame.contains(puzzle.id)) puzzle,
    ];
    final notAgain = [
      for (final puzzle in pool)
        if (puzzle.id != _progress.lastPlayedPuzzleId) puzzle,
    ];
    final choices =
        fresh.isNotEmpty ? fresh : (notAgain.isNotEmpty ? notAgain : pool);
    return choices[_random.nextInt(choices.length)];
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
  /// Ebat verilmezse bu safhanınkidir (K-15). Albümden seçilen bir resim de
  /// böyle oynanır: resmi çocuk seçer, ebadı safha.
  ///
  /// Görsel yüklenemezse çocuk hiçbir hata görmez: resim havuzdan çıkarılır
  /// ve yerine başka bir resim aynı ebatla başlar. Hiçbir şey yüklenemezse
  /// uygulama [AppState.error] durumuna yerleşir ve ekran sakin ve boş kalır
  /// (§14, §2).
  Future<void> startPuzzle(
    PuzzleDefinition definition, {
    PuzzleGrid? grid,
  }) async {
    final size = grid ?? stageGrid;
    _appState = AppState.loading;
    _sessionState = PuzzleSessionState.idle;
    _definition = definition;
    _grid = size;
    _pieces = _generator.generate(size);

    final slots = _shuffler.assignSlots(size.pieceCount);
    _runtime = Map.unmodifiable({
      for (final piece in _pieces)
        piece.id: PieceRuntimeState(
          pieceId: piece.id,
          traySlotIndex: slots[piece.id],
        ),
    });
    _progress = _progress.copyWith(
      lastPlayedPuzzleId: definition.id,
      playedThisGame: {..._progress.playedThisGame, definition.id},
      currentSolved: false,
    );
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

      final fallback = _pickPicture();
      if (fallback == null) {
        _appState = AppState.error;
        notifyListeners();
        return;
      }
      return startPuzzle(fallback, grid: size);
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

  /// Bu safhanın puzzle'ını rastgele bir resimle başlatır (K-15).
  Future<void> startNextPuzzle() async {
    final next = _pickPicture();
    if (next == null) {
      // Oynanabilecek tek bir resim yok: buraya gelmenin tek yolu, görselleri
      // hiç yüklenmeyen bir katalogdur (§14).
      _appState = AppState.error;
      notifyListeners();
      return;
    }
    await startPuzzle(next);
  }

  /// Bir safhanın dizisi bitti — kutlama, balon, çıkartma, boyama — ya da
  /// çocuk dizinin ortasında çıktı (§30). Oyun bir safha ilerler (K-15).
  ///
  /// Beşinci safhadan sonra araba biter: boyama defteri sıradaki arabaya
  /// geçer, safha 2 × 2'ye döner. Üçüncü araba oyunu bitirir ([isGameOver]).
  ///
  /// Yalnızca çözülmüş bir puzzle'dan sonra bir şey yapar; iki kez
  /// çağrılması bir safhayı iki kez ilerletmez.
  Future<void> finishStage() async {
    if (!_progress.currentSolved) return;

    var stage = _progress.stage + 1;
    var cars = _progress.carsFinished;
    if (stage >= GameRules.stagesPerCar) {
      stage = 0;
      cars += 1;
      await _colouring.startNextCar();
    }
    _progress = _progress.copyWith(
      stage: stage,
      carsFinished: cars,
      currentSolved: false,
    );
    _persist();
    notifyListeners();
  }

  /// Oyun sonu kutlamasından sonra: ilk arabanın 2 × 2'sinden yeniden
  /// (K-15). Çıkartmalar kalır; boyama defteri arabaları kaldığı yerden
  /// sürdürür.
  Future<void> startNewGame() async {
    _progress = _progress.copyWith(
      stage: 0,
      carsFinished: 0,
      playedThisGame: const {},
      currentSolved: false,
      clearLastPlayed: true,
    );
    _persist();
    notifyListeners();
    await startNextPuzzle();
  }

  // ── İlerleme (§25, §26) ───────────────────────────────────────────────

  /// Kayıtlı ilerlemeyi yükler ve çocuğun bıraktığı yerden devam eder
  /// (§25, K-15).
  ///
  /// Bir safhanın puzzle'ı çözülmüş ama dizisi bitmeden uygulama kapanmışsa
  /// safha ilerletilir: çözülmüş bir board'a dönmek çocuğa hiçbir şey
  /// vermezdi. Yarım kalan bir puzzle aynı resimle, ama baştan açılır. Bitmiş
  /// bir oyun yenisiyle açılır.
  Future<void> resume() async {
    final repository = _progressRepository;
    if (repository != null) {
      final stored = await repository.load();
      // Bu sürümün kurallarından büyük bir safha hiç oynanamaz.
      _progress = stored.stage < GameRules.stagesPerCar
          ? stored
          : stored.copyWith(stage: 0);
      notifyListeners();
    }

    if (_progress.currentSolved) {
      await finishStage();
    } else if (!isGameOver) {
      final lastPlayed = _progress.lastPlayedPuzzleId;
      final unfinished =
          lastPlayed == null ? null : _catalog.findById(lastPlayed);
      if (unfinished != null && !_unloadable.contains(unfinished.id)) {
        await startPuzzle(unfinished);
        return;
      }
    }

    if (isGameOver) {
      await startNewGame();
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
      // Resim çıkartma olarak kazanılır; safha, dizisi bitince ilerler
      // (K-15, [finishStage]).
      _progress = _progress.withCompleted(puzzle.id);
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
