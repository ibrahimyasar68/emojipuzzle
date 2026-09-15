import 'dart:async' show unawaited;
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/theme/app_theme.dart';
import '../../album/widgets/sticker_reward_overlay.dart';
import '../../balloon/widgets/balloon_game_overlay.dart';
import '../../celebration/widgets/celebration_overlay.dart';
import '../../colouring/widgets/colouring_overlay.dart';
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

/// Üstte board, altta tepsi, ikisinin de üstünde sürükleme katmanı
/// (§40, §10).
///
/// Önce board çözülür, kalan yükseklik tepsi olur — ikisi birlikte
/// boyutlandırılır, çünkü tepsi artakalan değildir: her parçayı 64 px'in
/// üstünde tutmak zorundadır (§16.1).
///
/// Snap kararını da bu ekran verir. Board boyutunu bilen katman odur ve
/// geometri provider'ın işi değildir (§39): [SnapCalculator]'a sorar ve
/// provider'a ne olduğunu söyler.
class PuzzleScreen extends StatefulWidget {
  const PuzzleScreen({super.key});

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen>
    with WidgetsBindingObserver {
  /// Hareket eden parça provider'da değil burada yaşar: her işaretçi
  /// karesinde değişir ve board'u yeniden kurmamalıdır (§17).
  final ValueNotifier<DragState?> _drag = ValueNotifier<DragState?>(null);

  /// "Bırakıldı" ile "vardı" arasındaki parça (§3, §20).
  final ValueNotifier<PieceFlight?> _flight = ValueNotifier<PieceFlight?>(null);

  /// Az önce yerleşen bir parçanın üstündeki parıltılar (§22).
  final ValueNotifier<PlacementBurst?> _burst =
      ValueNotifier<PlacementBurst?>(null);
  int _burstCount = 0;

  final GlobalKey _stackKey = GlobalKey();
  final GlobalKey _boardKey = GlobalKey();
  final GlobalKey _trayKey = GlobalKey();

  PiecePaths? _paths;
  String? _pathsPuzzleId;

  /// Son parça yerleştiğinden kutlama bitene kadar true (§23).
  bool _celebrating = false;

  /// Balon ödülü ekrandayken true (§23, §24).
  bool _playingBalloons = false;

  /// Az önce kazanılan çıkartma, teslim edilirken (§23, §25).
  PuzzleDefinition? _stickerAwarded;

  /// Boyama safhası ekrandayken true (§24.2).
  bool _colouring = false;

  /// Oynamayı bırakmış bir çocuğu gözler (§21).
  late final HintController _hint;

  /// Bir karenin kullandığı son yerleşim; böylece ipucunun otomatik
  /// yerleştirmesi, bir build beklemeden tepsi yuvalarının nerede olduğunu
  /// bilir.
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

  /// §21 — yardımın yalnızca ilk teklifi ses çıkarır. Sesi her sekiz
  /// saniyede bir tekrarlamak yardım değil, dırdır olurdu.
  void _onHintStage() {
    if (_hint.stage != HintStage.pulsePiece) return;
    context.read<GameProvider>().audio.playHint();
  }

  /// §21 — 32 saniye sonra oyun parçayı kendisi yerleştirir; çocuğun
  /// alacağı inişin aynısını kullanarak, sesi ve parıltıları dahil.
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

  /// §28 — uygulama oyunun ortasında arka plana gitti.
  ///
  /// Çocuk ne tutuyorsa yuvasına döner. Kesinti bir deneme değildir: hiçbir
  /// sayaç oynamaz, yani çocuk döndüğünde parça ne daha kolay ne daha zor
  /// yerleşir. İpuçları oldukları yerde durur ve ilerleme, yazmaya hâlâ
  /// vakit varken yazılır (§30).
  ///
  /// `inactive`, `paused` ile aynı muameleyi görür: bir bildirim perdesi ya
  /// da sistem penceresi parmağı en az arka plana geçmek kadar kesin
  /// biçimde koparır ve işaretçi akışının kibarca bitmesi garanti
  /// değildir.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.inactive:
      case AppLifecycleState.hidden:
      case AppLifecycleState.paused:
      case AppLifecycleState.detached:
        _interrupt();
      case AppLifecycleState.resumed:
        // Devam değil, temiz bir başlangıç: çocuk uzakta kalmıştır ve
        // board'a bakmak için kendi sekiz saniyesini hak eder (§21.2).
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

  /// Tutulan bir parçayı geldiği yere koyar, hiçbir şey kaydedilmeden.
  void _cancelDrag(GameProvider game) {
    final drag = _drag.value;
    if (drag == null) return;
    _drag.value = null;
    game.returnToTray(drag.pieceId);
  }

  /// §30 — Android geri tuşu. Pencere yok: çocuk okuyamaz ve cevap
  /// veremeyeceği bir soru sorulmaz.
  ///
  /// Tutulan ne varsa yuvasına döner, ilerleme kaydedilir ve ekran kapanır.
  /// Süren bir dizi kesilir, ama neyi kutluyorsa o zaten kaydedilmiştir:
  /// geri tuşu hiçbir ödülü geri almaz.
  Future<void> _leaveForHome() async {
    final game = context.read<GameProvider>();
    final navigator = Navigator.of(context);
    final wasCelebrating = _celebrating ||
        _playingBalloons ||
        _stickerAwarded != null ||
        _colouring;

    _cancelDrag(game);
    _hint.pause();

    if (wasCelebrating) {
      setState(() {
        _celebrating = false;
        _playingBalloons = false;
        _stickerAwarded = null;
        _colouring = false;
      });
      // Dizinin arkasındaki resim tamamlandı. Oyunu çözülmüş bir board'da
      // bırakmak çocuğa dönecek bir şey vermezdi, bu yüzden sonraki puzzle
      // çıkarken hazırlanır.
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

  /// Path önbelleğini yalnızca artık uymadığında yeniden kurar.
  ///
  /// Hem bir board boyutuna *hem de* bir puzzle'a bağlıdır: sonraki
  /// puzzle'ın gridi tamamen farklı olabilir (§4).
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
      // Parmak, küçük tepsi parçasının bir noktasını tuttu; board ölçeğinde
      // o nokta parçanın bu kadar içindedir (§9).
      grabOffset: details.localPosition / trayScale,
      pointerBoardLocal: CoordinateMapper.globalToBoard(
        details.globalPosition,
        _boardOriginGlobal,
      ),
      fromScale: trayScale,
    );
    // Çocuğun hissettiği dokunuş provider'a aittir (§17, §27).
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
      // §19 — ıskalamaya devam eden bir parça daha geniş bir hedef alır.
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

    // §20 — parça sallanarak evine döner. Başka hiçbir şey olmaz.
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
        // Parça yerleşmeden önce sorulur: puzzle'ı bitmiş işaretleyen şey
        // sonuncunun yerleşmesidir ve ondan sonra her puzzle kazanılmış
        // görünür.
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

  /// Bir parçanın az önce doldurduğu yuvanın üstünde parıltıları başlatır
  /// (§22).
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

  /// Resim tamamlandı: kutla (§23).
  ///
  /// Bu sürerken ipuçları durur — oyunun önerecek bir şeyi kalmamıştır ve
  /// konfetinin arkasında nabız atan bir tepsi saçmalık olurdu (§21).
  void _beginCelebration(GameProvider game, {required bool alreadyEarned}) {
    _hint.pause();
    // Şimdi not edilir, iki adım sonra teslim edilir (§23). Serbest Mod'da
    // yeniden oynanan bir resim yeni bir şey kazandırmaz ve iki kez verilen
    // bir çıkartma, hiçbir şeyin ödülü olurdu (§4, §25).
    _awardedSticker = alreadyEarned ? null : game.puzzle;
    setState(() => _celebrating = true);
  }

  /// Bu tamamlamanın kazandırdığı çıkartma; çocukta zaten varsa null.
  PuzzleDefinition? _awardedSticker;

  /// Kutlama bitti — kendiliğinden ya da çocuk dokunup geçtiği için. Sırada
  /// balonlar var; Faz 13 onlardan sonra çıkartmayı ekledi (§23).
  void _finishCelebration(GameProvider game) {
    if (!_celebrating) return;
    setState(() {
      _celebrating = false;
      _playingBalloons = true;
    });
  }

  /// Balonlar bitti — patlatıldılar ya da on beş saniye doldu. Her iki
  /// durumda da hiçbir şey sayılmaz ve hiçbir şey söylenmez (§20, §24).
  ///
  /// Sırada çıkartma var, ve yalnızca ilk kez bitirilen bir resim için:
  /// Serbest Mod'da çocuk ona zaten sahiptir ve yeniden teslim etmek hiçbir
  /// şeyin ödülü olurdu (§4, §25). Çıkartmadan sonra — ya da çıkartma yoksa
  /// hemen — boyama gelir (§24.2).
  void _finishBalloons(GameProvider game) {
    if (!_playingBalloons) return;
    final earned = _awardedSticker;
    setState(() {
      _playingBalloons = false;
      _stickerAwarded = earned;
      // Çıkartma yoksa boyama hemen gelir (§24.2).
      _colouring = earned == null;
    });
  }

  /// Çıkartma görüldü. Sırada boyama var (§23, §24.2).
  void _finishSticker() {
    if (_stickerAwarded == null) return;
    setState(() {
      _stickerAwarded = null;
      _colouring = true;
    });
  }

  /// Bir parça boyandı ya da çocuk geçti. Sıradaki resme (§23, §24.2).
  ///
  /// Boyama her bitirişte gelir, Serbest Mod dahil: çıkartma yalnızca bir
  /// kez kazanılır, ama arabanın bir parçası her seferinde (K-6).
  void _finishColouring(GameProvider game) {
    if (!_colouring) return;
    setState(() => _colouring = false);
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
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Consumer<GameProvider>(
          builder: (context, game, _) {
            final image = game.image;
            if (game.appState != AppState.ready || image == null) {
              // Dönen çark yok, mesaj yok: bu ne kadar sürerse çocuk o
              // kadar sakin ve boş bir ekran görür (§2, §14).
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
                // Otomatik yerleştirme için saklanır; o iş build içinde
                // değil bir zamanlayıcıda olur (§21).
                _lastLayout = layout;
                _lastTrayScale = trayScale;

                return Listener(
                  behavior: HitTestBehavior.translucent,
                  // Herhangi bir dokunuş çocuğun meşgul olduğu anlamına
                  // gelir (§21.2).
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
                              onFinished: _finishSticker,
                            ),
                          if (_colouring)
                            ColouringOverlay(
                              book: game.colouring,
                              audio: game.audio,
                              onFinished: () => _finishColouring(game),
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
