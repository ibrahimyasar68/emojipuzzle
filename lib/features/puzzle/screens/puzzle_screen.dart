import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../album/widgets/sticker_reward_overlay.dart';
import '../../balloon/widgets/balloon_game_overlay.dart';
import '../../celebration/widgets/celebration_overlay.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/snap_calculator.dart';
import '../engine/geometry/tray_layout_calculator.dart';
import '../engine/path/piece_paths.dart';
import '../engine/hint_target.dart';
import '../models/app_state.dart';
import '../models/drag_state.dart';
import '../models/hint_stage.dart';
import '../models/piece_flight.dart';
import '../models/placement_burst.dart';
import '../models/puzzle_definition.dart';
import '../models/puzzle_piece.dart';
import '../providers/game_provider.dart';
import '../providers/hint_controller.dart';
import '../widgets/drag_layer.dart';
import '../widgets/feedback_layer.dart';
import '../widgets/hint_layer.dart';
import '../widgets/puzzle_board.dart';
import '../widgets/puzzle_tray.dart';

/// Board on top, tray underneath, drag layer over both (§40, §10).
///
/// The board is solved first, then whatever height is left becomes the
/// tray — the two are sized together, because the tray is not a leftover:
/// it has to keep every piece above 64 px (§16.1).
///
/// This screen also makes the snap decision. It is the layer that knows the
/// board size, and geometry is not the provider's job (§39): it asks
/// [SnapCalculator] and tells the provider what happened.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver {
  /// The moving piece lives here, not in the provider: it changes on every
  /// pointer frame and must not rebuild the board (§17).
  final ValueNotifier<DragState?> _drag = ValueNotifier<DragState?>(null);

  /// The piece between "let go" and "arrived" (§3, §20).
  final ValueNotifier<PieceFlight?> _flight = ValueNotifier<PieceFlight?>(null);

  /// The sparkles over a piece that just landed (§22).
  final ValueNotifier<PlacementBurst?> _burst =
      ValueNotifier<PlacementBurst?>(null);
  int _burstCount = 0;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _trayKey = GlobalKey();

  PiecePaths? _paths;
  String? _pathsPuzzleId;

  /// True from the last piece landing until the celebration is over (§23).
  bool _celebrating = false;

  /// True while the balloon reward is on screen (§23, §24).
  bool _playingBalloons = false;

  /// The sticker just earned, while it is being handed over (§23, §25).
  PuzzleDefinition? _stickerAwarded;

  /// Watches for a child who has stopped playing (§21).
  late final HintController _hint;

  /// The last layout a frame used, so the hint's automatic placement knows
  /// where the tray slots are without waiting for a build.
  TrayLayout? _lastLayout;
  double _lastTrayScale = 1;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _hint = HintController()
      ..onAutoPlace = _autoPlaceHintTarget
      ..addListener(_onHintStage)
      ..start();
  }

  /// §21 — the first offer of help is the only one that speaks. Repeating
  /// the chime every eight seconds would nag rather than help.
  void _onHintStage() {
    if (_hint.stage != HintStage.pulsePiece) return;
    context.read<GameProvider>().audio.playHint();
  }

  /// §21 — after 32 seconds the game puts the piece in itself, using the
  /// same landing the child would have got, sound and sparkles included.
  void _autoPlaceHintTarget() {
    if (!mounted) return;
    final game = context.read<GameProvider>();
    final boardSize = _paths?.boardSize;
    final layout = _lastLayout;
    if (boardSize == null || layout == null) return;

    final target = HintTarget.choose(game.trayPieces);
    if (target == null) return;

    final slot = layout.slotRect(game.stateOf(target.id).traySlotIndex);
    game.beginAutoPlace(target.id);
    _flight.value = PieceFlight(
      pieceId: target.id,
      from: _originInStack(_trayKey) + slot.topLeft,
      to: _originInStack(_boardKey) +
          SnapCalculator.restingOrigin(
            piece: target,
            grid: game.grid,
            boardSize: boardSize,
          ),
      fromScale: _lastTrayScale,
      toScale: 1,
      kind: PieceFlightKind.settle,
    );
  }

  /// §28 — the app went away mid-game.
  ///
  /// Whatever the child was holding goes back to its slot. The interruption
  /// is not a try: no counter moves, so the piece is no easier and no
  /// harder to place when they come back. Hints stop where they are, and
  /// progress is written out while there is still time to write it (§30).
  ///
  /// `inactive` is treated the same as `paused`: a notification shade or a
  /// system dialog takes the finger away just as surely as backgrounding
  /// does, and the pointer stream is not guaranteed to end politely.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _interrupt();
      case AppLifecycleState.resumed:
        // A fresh start, not a continuation: the child has been away and
        // deserves their own eight seconds to look at the board (§21.2).
        _hint.resume();
    }
  }

  void _interrupt() {
    if (!mounted) return;
    final game = context.read<GameProvider>();
    _cancelDrag(game);
    _hint.pause();
    unawaited(game.saveProgress());
  }

  /// Puts a held piece back where it came from, with nothing recorded.
  void _cancelDrag(GameProvider game) {
    final drag = _drag.value;
    if (drag == null) return;
    _drag.value = null;
    game.returnToTray(drag.pieceId);
  }

  /// §30 — Android Back. No dialog: a child cannot read one, and will not
  /// be asked a question they cannot answer.
  ///
  /// Anything being held goes back to its slot, progress is saved, and the
  /// screen closes. A sequence still running is cut short, but whatever it
  /// was celebrating has already been recorded: Back never takes a reward
  /// away.
  Future<void> _leaveForHome() async {
    final game = context.read<GameProvider>();
    final navigator = Navigator.of(context);
    final wasCelebrating =
        _celebrating || _playingBalloons || _stickerAwarded != null;

    _cancelDrag(game);
    _hint.pause();

    if (wasCelebrating) {
      setState(() {
        _celebrating = false;
        _playingBalloons = false;
        _stickerAwarded = null;
      });
      // The picture behind the sequence is finished. Leaving the game on a
      // solved board would give the child nothing to come back to, so the
      // next one is set up on the way out.
      unawaited(game.startNextPuzzle());
    }

    await game.saveProgress();
    if (navigator.canPop()) navigator.pop();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _hint
      ..removeListener(_onHintStage)
      ..dispose();
    _drag.dispose();
    _flight.dispose();
    _burst.dispose();
    super.dispose();
  }

  /// Rebuilds the path cache only when it no longer fits.
  ///
  /// It is tied to a board size *and* to a puzzle: the next puzzle may have
  /// a different grid entirely (§4).
  PiecePaths _pathsFor(GameProvider game, Size boardSize) {
    final cached = _paths;
    if (cached != null &&
        cached.matches(boardSize) &&
        _pathsPuzzleId == game.puzzle.id) {
      return cached;
    }
    _pathsPuzzleId = game.puzzle.id;
    return _paths = PiecePaths.build(
      pieces: game.pieces,
      grid: game.grid,
      boardSize: boardSize,
    );
  }

  RenderBox? _boxOf(GlobalKey key) =>
      key.currentContext?.findRenderObject() as RenderBox?;

  Offset get _boardOriginGlobal =>
      _boxOf(_boardKey)?.localToGlobal(Offset.zero) ?? Offset.zero;

  Offset _originInStack(GlobalKey key) {
    final stack = _boxOf(_stackKey);
    final box = _boxOf(key);
    if (stack == null || box == null) return Offset.zero;
    return stack.globalToLocal(box.localToGlobal(Offset.zero));
  }

  void _startDrag(
    GameProvider game,
    PuzzlePiece piece,
    DragStartDetails details,
    double trayScale,
  ) {
    _drag.value = DragState(
      pieceId: piece.id,
      // The finger grabbed a point on the small tray piece; at board scale
      // that point is this far into the piece (§9).
      grabOffset: details.localPosition / trayScale,
      pointerBoardLocal: CoordinateMapper.globalToBoard(
        details.globalPosition,
        _boardOriginGlobal,
      ),
      fromScale: trayScale,
    );
    // The provider owns the tap the child feels (§17, §27).
    game.beginDrag(piece.id);
  }

  void _updateDrag(DragUpdateDetails details) {
    final current = _drag.value;
    if (current == null) return;
    _drag.value = current.movedTo(
      CoordinateMapper.globalToBoard(
        details.globalPosition,
        _boardOriginGlobal,
      ),
    );
  }

  void _endDrag(
    GameProvider game,
    Size boardSize,
    TrayLayout layout,
    double trayScale,
  ) {
    final drag = _drag.value;
    if (drag == null) return;
    _drag.value = null;

    final piece = game.pieces.firstWhere((p) => p.id == drag.pieceId);
    final droppedAt = drag.pieceOriginBoardLocal;
    final onTarget = SnapCalculator.snaps(
      pieceOriginBoardLocal: droppedAt,
      piece: piece,
      grid: game.grid,
      boardSize: boardSize,
      // §19 — a piece that keeps missing gets a wider target.
      failedAttempts: game.stateOf(piece.id).failedAttempts,
    );

    final from = _originInStack(_boardKey) + droppedAt;

    if (onTarget) {
      game.beginSnap(piece.id);
      _flight.value = PieceFlight(
        pieceId: piece.id,
        from: from,
        to: _originInStack(_boardKey) +
            SnapCalculator.restingOrigin(
              piece: piece,
              grid: game.grid,
              boardSize: boardSize,
            ),
        fromScale: 1,
        toScale: 1,
        kind: PieceFlightKind.settle,
      );
      return;
    }

    // §20 — the piece wobbles home. Nothing else happens.
    final slot = layout.slotRect(game.stateOf(piece.id).traySlotIndex);
    _flight.value = PieceFlight(
      pieceId: piece.id,
      from: from,
      to: _originInStack(_trayKey) + slot.topLeft,
      fromScale: 1,
      toScale: trayScale,
      kind: PieceFlightKind.snapBack,
    );
  }

  void _onFlightComplete(GameProvider game, PieceFlight flight) {
    _flight.value = null;
    switch (flight.kind) {
      case PieceFlightKind.settle:
        // Asked before the piece lands: landing the last one is what marks
        // the puzzle finished, and after that every puzzle looks earned.
        final alreadyEarned = game.isPuzzleCompleted(game.puzzle.id);
        game.markPlaced(flight.pieceId);
        _sparkleOver(game, flight.pieceId);
        if (game.isComplete) {
          _beginCelebration(game, alreadyEarned: alreadyEarned);
        }
      case PieceFlightKind.snapBack:
        game.dropFailed(flight.pieceId);
    }
  }

  /// Sets off the sparkles over the slot a piece just filled (§22).
  void _sparkleOver(GameProvider game, int pieceId) {
    final boardSize = _paths?.boardSize;
    if (boardSize == null) return;

    final piece = game.pieces.firstWhere((p) => p.id == pieceId);
    final cellSize = CoordinateMapper.cellSizeOf(game.grid, boardSize);
    _burst.value = PlacementBurst(
      id: ++_burstCount,
      centre: _originInStack(_boardKey) +
          CoordinateMapper.pixelOf(piece.normalizedPosition, boardSize) +
          Offset(cellSize.width / 2, cellSize.height / 2),
    );
  }

  /// The picture is finished: celebrate it (§23).
  ///
  /// Hints stop while this runs — the game has nothing left to suggest, and
  /// a pulsing tray behind the confetti would be nonsense (§21).
  void _beginCelebration(GameProvider game, {required bool alreadyEarned}) {
    _hint.pause();
    // Noted now, handed over two steps later (§23). A picture played again
    // in Free Mode earns nothing new, and a sticker given twice would be a
    // reward for nothing (§4, §25).
    _awardedSticker = alreadyEarned ? null : game.puzzle;
    setState(() => _celebrating = true);
  }

  /// The sticker this completion earned, or null when the child already had
  /// it.
  PuzzleDefinition? _awardedSticker;

  /// The celebration ended, by itself or because the child tapped through
  /// it. The balloons come next; Faz 13 adds the sticker after them (§23).
  void _finishCelebration(GameProvider game) {
    if (!_celebrating) return;
    setState(() {
      _celebrating = false;
      _playingBalloons = true;
    });
  }

  /// The balloons are done — popped, or fifteen seconds went by. Either
  /// way nothing is counted and nothing is said (§20, §24).
  ///
  /// The sticker comes next, and only for a picture finished for the first
  /// time: in Free Mode the child already owns it, and handing it over
  /// again would be a reward for nothing (§4, §25).
  void _finishBalloons(GameProvider game) {
    if (!_playingBalloons) return;
    final earned = _awardedSticker;
    setState(() {
      _playingBalloons = false;
      _stickerAwarded = earned;
    });
    if (earned == null) _moveOn(game);
  }

  /// The sticker has been seen. On to the next picture (§23).
  void _finishSticker(GameProvider game) {
    if (_stickerAwarded == null) return;
    setState(() => _stickerAwarded = null);
    _moveOn(game);
  }

  void _moveOn(GameProvider game) {
    _hint.resume();
    game.startNextPuzzle();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        unawaited(_leaveForHome());
      },
      child: _buildScreen(context),
    );
  }

  Widget _buildScreen(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EF),
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
            final image = game.image;
            if (game.appState != AppState.ready || image == null) {
              // No spinner, no message: a child gets a calm empty screen
              // for the moment this takes (§2, §14).
              return const SizedBox.expand();
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final boardEdge = math.min(
                  math.min(
                    constraints.maxWidth - 2 * PuzzleConfig.boardMargin,
                    constraints.maxHeight * PuzzleConfig.boardHeightFactor,
                  ),
                  PuzzleConfig.maxBoardSize,
                );
                final boardSize = Size(boardEdge, boardEdge);
                final paths = _pathsFor(game, boardSize);

                final trayHeight = constraints.maxHeight - boardEdge;
                final pieceSize = CoordinateMapper.pieceSizeOf(
                  CoordinateMapper.cellSizeOf(game.grid, boardSize),
                );
                final layout = TrayLayoutCalculator.calculate(
                  traySize: Size(constraints.maxWidth, trayHeight),
                  pieceCount: game.grid.pieceCount,
                  boardPieceSize: pieceSize,
                );
                final trayScale = layout.itemSize.width / pieceSize.width;
                // Kept for the automatic placement, which happens on a
                // timer rather than inside a build (§21).
                _lastLayout = layout;
                _lastTrayScale = trayScale;

                return Listener(
                  behavior: HitTestBehavior.translucent,
                  // Any touch at all means the child is busy (§21.2).
                  onPointerDown: (_) => _hint.registerInteraction(),
                  child: ListenableBuilder(
                    listenable: _hint,
                    builder: (context, _) {
                      final hintTarget = HintTarget.choose(game.trayPieces);
                      final hinting =
                          _hint.stage.index >= HintStage.pulsePiece.index;

                      return Stack(
                        key: _stackKey,
                        children: [
                          Column(
                            children: [
                              SizedBox(
                                height: boardEdge,
                                child: Center(
                                  child: PuzzleBoard(
                                    key: _boardKey,
                                    image: image,
                                    grid: game.grid,
                                    paths: paths,
                                    placedPieces: game.placedPieces,
                                    boardSize: boardSize,
                                    backgroundCategory: game.puzzle.category,
                                  ),
                                ),
                              ),
                              PuzzleTray(
                                key: _trayKey,
                                image: image,
                                grid: game.grid,
                                paths: paths,
                                trayPieces: game.trayPieces,
                                slotOf: (piece) =>
                                    game.stateOf(piece.id).traySlotIndex,
                                layout: layout,
                                boardSize: boardSize,
                                onPieceDragStart: (piece, details) =>
                                    _startDrag(game, piece, details, trayScale),
                                onPieceDragUpdate: _updateDrag,
                                onPieceDragEnd: () => _endDrag(
                                    game, boardSize, layout, trayScale),
                                backgroundCategory: game.puzzle.category,
                                hintPieceId: hinting ? hintTarget?.id : null,
                              ),
                            ],
                          ),
                          DragLayer(
                            drag: _drag,
                            flight: _flight,
                            onFlightComplete: (flight) =>
                                _onFlightComplete(game, flight),
                            pieceOf: (id) =>
                                game.pieces.firstWhere((p) => p.id == id),
                            image: image,
                            grid: game.grid,
                            paths: paths,
                            boardSize: boardSize,
                            boardOrigin: _originInStack(_boardKey),
                            backgroundCategory: game.puzzle.category,
                          ),
                          HintLayer(
                            stage: _hint.stage,
                            target: hintTarget,
                            image: image,
                            grid: game.grid,
                            paths: paths,
                            boardSize: boardSize,
                            boardOrigin: _originInStack(_boardKey),
                            trayPieceOrigin: hintTarget == null
                                ? Offset.zero
                                : _originInStack(_trayKey) +
                                    layout
                                        .slotRect(
                                          game
                                              .stateOf(hintTarget.id)
                                              .traySlotIndex,
                                        )
                                        .topLeft,
                            trayScale: trayScale,
                            backgroundCategory: game.puzzle.category,
                          ),
                          FeedbackLayer(burst: _burst),
                          if (_celebrating)
                            CelebrationOverlay(
                              origin: _originInStack(_boardKey) +
                                  Offset(
                                    boardSize.width / 2,
                                    boardSize.height / 2,
                                  ),
                              onFinished: () => _finishCelebration(game),
                            ),
                          if (_playingBalloons)
                            BalloonGameOverlay(
                              audio: game.audio,
                              onFinished: () => _finishBalloons(game),
                            ),
                          if (_stickerAwarded != null)
                            StickerRewardOverlay(
                              puzzle: _stickerAwarded!,
                              onFinished: () => _finishSticker(game),
                            ),
                        ],
                      );
                    },
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
