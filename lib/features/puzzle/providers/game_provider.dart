import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';

import '../../../core/services/audio_service.dart';
import '../../../core/services/haptic_service.dart';
import '../../../core/services/puzzle_image_loader.dart';
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

/// Owns the state of one puzzle session and the walk through the catalogue
/// (§38, §39).
///
/// Deliberately not here: geometry, path building, tray layout, image
/// decoding, audio, persistence and rendering. This class holds state,
/// calls the engine and the services, and tells the UI what changed.
///
/// Layout-dependent things (board size, path cache, tray layout, the snap
/// decision) are not state either — they belong to whoever knows the screen
/// size (§40).
class GameProvider extends ChangeNotifier {
  GameProvider({
    PuzzleGenerator? generator,
    TrayShuffler? shuffler,
    PuzzleImageLoader? imageLoader,
    ProgressRepository? progressRepository,
    AudioService? audio,
    HapticService haptics = const HapticService(),
    PuzzleCatalog catalog = PuzzleCatalog.v1,
  })  : _generator = generator ?? PuzzleGenerator(),
        _shuffler = shuffler ?? TrayShuffler(),
        _imageLoader = imageLoader ?? PuzzleImageLoader(),
        _progressRepository = progressRepository,
        _audio = audio ?? AudioService(),
        _ownsAudio = audio == null,
        _haptics = haptics,
        _catalog = catalog;

  final PuzzleGenerator _generator;
  final TrayShuffler _shuffler;
  final PuzzleImageLoader _imageLoader;

  /// Null means this session keeps nothing: useful in tests, and the app
  /// still plays if the store cannot be opened.
  final ProgressRepository? _progressRepository;

  /// What the child hears and feels is a consequence of state, so it is
  /// triggered here (§39 allows calling services). What they *see* at a
  /// point on the board needs screen coordinates and stays in the widgets.
  final AudioService _audio;
  final bool _ownsAudio;
  final HapticService _haptics;

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

  /// Puzzles whose picture would not load. They are quietly left out of the
  /// rotation instead of being shown to a child as an error (§14).
  final Set<String> _unloadable = <String>{};

  AppState get appState => _appState;
  PuzzleSessionState get sessionState => _sessionState;

  PuzzleCatalog get catalog => _catalog;
  GameProgress get progress => _progress;
  AudioService get audio => _audio;

  PuzzleDefinition get puzzle =>
      _definition ?? (throw StateError('no puzzle started yet'));

  PuzzleGrid get grid => puzzle.grid;

  List<PuzzlePiece> get pieces => _pieces;

  ui.Image? get image => _image;

  // ── The ladder (§4) ───────────────────────────────────────────────────

  int get unlockedLevelCount =>
      _catalog.unlockedLevelCount(_progress.completedPuzzleIds);

  List<LevelDefinition> get unlockedLevels =>
      _catalog.levels.take(unlockedLevelCount).toList();

  bool isLevelUnlocked(int levelIndex) =>
      _catalog.isLevelUnlocked(levelIndex, _progress.completedPuzzleIds);

  bool isPuzzleCompleted(String puzzleId) => _progress.isCompleted(puzzleId);

  /// The next puzzle to offer, or null when everything open is finished.
  ///
  /// A puzzle whose artwork is missing is skipped, but it still counts as
  /// unplayed — it must not unlock anything (§14).
  PuzzleDefinition? get nextPuzzle => _catalog.firstUnsolved(
        _progress.completedPuzzleIds,
        unavailable: _unloadable,
      );

  // ── One session ───────────────────────────────────────────────────────

  PieceRuntimeState stateOf(int pieceId) =>
      _runtime[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'unknown piece'));

  /// Pieces sitting in the tray, in slot order (§16.2).
  ///
  /// A piece in the air is not here: it belongs to the drag layer, and its
  /// slot stays empty until it comes back (§10).
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

  /// Builds a puzzle and gets its picture ready.
  ///
  /// If the artwork cannot be loaded the child sees no error: the puzzle is
  /// dropped from the rotation and the next playable one starts instead. If
  /// nothing at all loads, the app settles into [AppState.error] and the
  /// screen stays calm and empty (§14, §2).
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
    // Where we are is worth keeping even if the app never gets to the end
    // of this puzzle (§25).
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

  /// Moves on to the next unfinished puzzle, if there is one.
  Future<void> startNextPuzzle() async {
    final next = nextPuzzle;
    if (next == null) return;
    await startPuzzle(next);
  }

  // ── Progress (§25, §26) ───────────────────────────────────────────────

  /// Loads saved progress and picks up where the child left off (§25).
  Future<void> resume() async {
    final repository = _progressRepository;
    if (repository != null) {
      final stored = await repository.load();
      // The finished puzzles are the truth; the unlocked level is derived
      // from them again here, so a stored level can never be more generous
      // than the catalogue allows (§4).
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

  /// Writes progress out. Faz 14 calls this before leaving the screen (§30).
  Future<void> saveProgress() async {
    final repository = _progressRepository;
    if (repository == null) return;
    try {
      await repository.save(_progress);
    } on Object catch (error) {
      // Losing a write is not worth interrupting a child's game (§2).
      debugPrint('Progress could not be saved: $error');
    }
  }

  /// Waits for the last background write. Tests and Faz 14 use this.
  Future<void> get pendingWrite => _lastWrite;

  void _persist() {
    _lastWrite = saveProgress();
    unawaited(_lastWrite);
  }

  /// §26 — back to a clean slate. No child-facing UI reaches this yet.
  Future<void> clearProgress() async {
    _progress = const GameProgress.initial();
    notifyListeners();
    await _progressRepository?.clear();
  }

  // ── Playing (§10, §17, §18, §19) ──────────────────────────────────────

  /// The child picked a piece up.
  ///
  /// Notifies once, here — not on every pointer move. The moving position
  /// travels through the drag layer's own notifier (§17).
  void beginDrag(int pieceId) {
    final current = stateOf(pieceId);
    // A placed piece is locked; it cannot be taken apart again (§10).
    if (current.status != PieceStatus.inTray) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(status: PieceStatus.dragging),
    });
    _sessionState = PuzzleSessionState.dragging;
    // §17 — a small tap the moment the piece comes loose.
    _haptics.selection();
    notifyListeners();
  }

  /// The drop was on target; the piece is now flying into its slot (§18).
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

  /// §21 — the game gives up waiting and places the piece itself.
  ///
  /// It goes straight from the tray into the settling animation: no drag
  /// happened, so there is nothing to feel and nothing to undo.
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

  /// The drop missed. The piece goes home and its counter goes up (§19).
  ///
  /// Nothing else happens: no score, no sound, no scolding (§20). The
  /// counter exists only to make the next try easier.
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

  /// Sends a dragged piece home to its own slot (§10, §16.2).
  ///
  /// Used by the lifecycle cancel in Faz 14. Neither this nor a plain drop
  /// counts as a failed attempt (§28).
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

  /// Locks a piece into its slot, and finishes the puzzle if it was the
  /// last one.
  void markPlaced(int pieceId) {
    final current = stateOf(pieceId);
    if (current.status == PieceStatus.placed) return;

    _runtime = Map.unmodifiable({
      ..._runtime,
      pieceId: current.copyWith(
        status: PieceStatus.placed,
        clearDragOffset: true,
        // §19 — the counter belongs to the piece and dies with it.
        failedAttempts: 0,
      ),
    });

    if (isComplete) {
      _sessionState = PuzzleSessionState.completed;
      // Finishing is what opens the next rung of the ladder (§4).
      _progress = _progress.withCompleted(puzzle.id).copyWith(
            unlockedLevel: _catalog.unlockedLevelCount({
              ..._progress.completedPuzzleIds,
              puzzle.id,
            }),
          );
      _persist();
      // The finishing phrase stands in for the piece's own pop: two sounds
      // at once on the last piece would be a noise, not a reward (§22, §23).
      _audio.playPuzzleComplete();
      _haptics.medium();
    } else {
      _sessionState = PuzzleSessionState.idle;
      _audio.playPieceSnap();
      _haptics.light();
    }
    notifyListeners();
  }

  /// Sends every piece back to its slot, keeping the same puzzle.
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
    // Only dispose what we made: an injected service belongs to the app.
    if (_ownsAudio) _audio.dispose();
    super.dispose();
  }
}
