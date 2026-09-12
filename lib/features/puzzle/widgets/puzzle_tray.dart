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

/// The tray of unplayed pieces (§16).
///
/// It never scrolls: every piece is visible at once. Slots are fixed — when
/// a piece leaves, its slot stays empty and nothing shuffles around, so the
/// child's memory of "that one was over there" keeps working (§16.2).
///
/// The gestures belong to the **slot**, not to the piece. A piece leaves
/// the tray the moment it is picked up, and a detector that left with it
/// would take the "let go" event with it — the drop would never arrive.
/// Slots outlive pieces, so the whole drag is reported from one place.
///
/// Pieces are drawn from the same cached board-size paths, scaled down.
/// That keeps one set of paths for the whole puzzle and makes the pick-up
/// animation a plain scale from tray size to board size (§17).
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

  /// Pieces currently resting in the tray. A piece in the air is missing
  /// from this list; its slot stays, empty.
  final List<PuzzlePiece> trayPieces;

  /// Fixed slot index of a piece (§16.2).
  final int Function(PuzzlePiece piece) slotOf;

  final TrayLayout layout;
  final Size boardSize;

  final void Function(PuzzlePiece piece, DragStartDetails details)
      onPieceDragStart;
  final void Function(DragUpdateDetails details) onPieceDragUpdate;
  final VoidCallback onPieceDragEnd;

  /// Picks the surface painted under the transparent artwork (§34). A tray
  /// piece wears the shade of the place it belongs to.
  final PuzzleCategory? backgroundCategory;

  /// The piece a hint is pointing at, if any: it breathes until the child
  /// does something (§21).
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
        // A pulsing hint swells past its slot; clipping it would look like
        // a mistake (§21).
        clipBehavior: Clip.none,
        children: [
          for (var slot = 0; slot < grid.pieceCount; slot++)
            _slot(slot, occupant[slot], pieceSize, imageSize, scale),
        ],
      ),
    );
  }

  /// The board's gradient as seen from where this piece will end up.
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
        // No piece to pick up right now — but the update and end callbacks
        // stay wired, so a drag that started here still reports its drop.
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
                child: SizedBox(
                  // The slot is the touch target, so it is the box that
                  // carries the key and the size a test can measure (§2).
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
                          renderPath: paths.renderOf(piece.id),
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
    );
  }
}

/// Breathes while [pulsing], and is an ordinary box otherwise (§21).
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
