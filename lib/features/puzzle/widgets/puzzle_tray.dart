import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/piece_image_mapper.dart';
import '../engine/geometry/tray_layout_calculator.dart';
import '../engine/path/piece_paths.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import 'puzzle_piece_painter.dart';

/// Henüz oynanmamış parçaların tepsisi (§16).
///
/// Asla kaydırılmaz: bütün parçalar aynı anda görünür. Yuvalar sabittir —
/// bir parça ayrıldığında yuvası boş kalır ve hiçbir şey yer değiştirmez;
/// böylece çocuğun "o şuradaydı" hafızası çalışmaya devam eder (§16.2).
///
/// Jestler parçaya değil, **yuvaya** aittir. Parça alındığı anda tepsiden
/// ayrılır ve onunla birlikte giden bir dinleyici "bırakma" olayını da
/// götürürdü — bırakma hiç ulaşmazdı. Yuvalar parçalardan uzun yaşar, bu
/// yüzden sürüklemenin tamamı tek bir yerden bildirilir.
///
/// Parçalar, board boyutunda önbelleklenmiş aynı path'lerden küçültülerek
/// çizilir. Bu, puzzle boyunca tek bir path kümesi tutar ve alma
/// animasyonunu tepsi boyundan board boyuna sade bir ölçeklemeye indirger
/// (§17).
class PuzzleTray extends StatelessWidget {
  const PuzzleTray({
    super.key,
    required this.image,
    required this.grid,
    required this.paths,
    required this.trayPieces,
    required this.slotOf,
    required this.layout,
    required this.boardSize,
    required this.onPieceDragStart,
    required this.onPieceDragUpdate,
    required this.onPieceDragEnd,
    this.backgroundCategory,
    this.hintPieceId,
  });

  final ui.Image image;
  final PuzzleGrid grid;
  final PiecePaths paths;

  /// Şu anda tepside duran parçalar. Havadaki bir parça bu listede yoktur;
  /// yuvası boş olarak kalır.
  final List<PuzzlePiece> trayPieces;

  /// Bir parçanın sabit yuva indeksi (§16.2).
  final int Function(PuzzlePiece piece) slotOf;

  final TrayLayout layout;
  final Size boardSize;

  final void Function(PuzzlePiece piece, DragStartDetails details)
      onPieceDragStart;
  final void Function(DragUpdateDetails details) onPieceDragUpdate;
  final VoidCallback onPieceDragEnd;

  /// Şeffaf görselin altına boyanacak yüzeyi seçer (§34). Tepsideki bir
  /// parça, ait olduğu yerin tonunu giyer.
  final PuzzleCategory? backgroundCategory;

  /// Varsa ipucunun işaret ettiği parça: çocuk bir şey yapana kadar nefes
  /// alır (§21).
  final int? hintPieceId;

  @override
  Widget build(BuildContext context) {
    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);
    final imageSize = Size(image.width.toDouble(), image.height.toDouble());
    final scale = layout.itemSize.width / pieceSize.width;

    final occupant = <int, PuzzlePiece>{
      for (final piece in trayPieces) slotOf(piece): piece,
    };

    return SizedBox(
      width: layout.traySize.width,
      height: layout.traySize.height,
      child: Stack(
        // Nabız atan bir ipucu yuvasının dışına taşar; onu kırpmak hata
        // gibi görünürdü (§21).
        clipBehavior: Clip.none,
        children: [
          for (var slot = 0; slot < grid.pieceCount; slot++)
            _slot(slot, occupant[slot], pieceSize, imageSize, scale),
        ],
      ),
    );
  }

  /// Board'un gradyanı, bu parçanın varacağı yerden görüldüğü haliyle.
  PieceBackground? _backgroundFor(PuzzlePiece piece) {
    final category = backgroundCategory;
    if (category == null) return null;
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );
    return PuzzlePalette.backgroundFor(
      category,
      boardRect: Rect.fromLTWH(
        -origin.dx,
        -origin.dy,
        boardSize.width,
        boardSize.height,
      ),
    );
  }

  Widget _slot(
    int slotIndex,
    PuzzlePiece? piece,
    Size pieceSize,
    Size imageSize,
    double scale,
  ) {
    final rect = layout.slotRect(slotIndex);

    return Positioned(
      key: ValueKey('tray-slot-$slotIndex'),
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        // Şu an alınacak parça yok — ama güncelleme ve bitiş geri
        // çağrıları bağlı kalır; böylece burada başlayan bir sürükleme
        // bırakmasını yine de bildirir.
        onPanStart: piece == null
            ? null
            : (details) => onPieceDragStart(piece, details),
        onPanUpdate: onPieceDragUpdate,
        onPanEnd: (_) => onPieceDragEnd(),
        onPanCancel: onPieceDragEnd,
        child: piece == null
            ? const SizedBox.expand()
            : _HintPulse(
                pulsing: piece.id == hintPieceId,
                child: Semantics(
                  // §31 — bir yapboz parçasının çocuğun bileceği bir adı
                  // yoktur; bu yüzden etiket onun hakkındaki tek doğru şeyi
                  // söyler: hangisi olduğunu ve taşınabileceğini.
                  label: 'Puzzle parçası ${piece.id + 1}',
                  child: SizedBox(
                    // Dokunma hedefi yuvadır; bu yüzden anahtarı taşıyan
                    // ve bir testin ölçebileceği boyutu veren kutu odur
                    // (§2).
                    key: ValueKey('tray-piece-${piece.id}'),
                    width: rect.width,
                    height: rect.height,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.topLeft,
                      child: SizedBox(
                        width: pieceSize.width,
                        height: pieceSize.height,
                        child: CustomPaint(
                          size: pieceSize,
                          painter: PuzzlePiecePainter(
                            image: image,
                            renderPath: paths.of(piece.id),
                            background: _backgroundFor(piece),
                            rects: PieceImageMapper.rectsOf(
                              piece: piece,
                              grid: grid,
                              boardSize: boardSize,
                              imageSize: imageSize,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

/// [pulsing] iken nefes alır, değilken sıradan bir kutudur (§21).
class _HintPulse extends StatefulWidget {
  const _HintPulse({required this.pulsing, required this.child});

  final bool pulsing;
  final Widget child;

  @override
  State<_HintPulse> createState() => _HintPulseState();
}

class _HintPulseState extends State<_HintPulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: PuzzleConfig.hintPulseDuration,
    );
    if (widget.pulsing) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_HintPulse oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.pulsing == oldWidget.pulsing) return;
    if (widget.pulsing) {
      _controller.repeat(reverse: true);
    } else {
      _controller
        ..stop()
        ..value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.pulsing) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.scale(
        scale: 1 +
            (PuzzleConfig.hintPulseScale - 1) *
                Curves.easeInOut.transform(_controller.value),
        child: child,
      ),
      child: widget.child,
    );
  }
}
