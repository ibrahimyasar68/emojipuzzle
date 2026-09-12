import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show ValueListenable, kDebugMode;
import 'package:flutter/widgets.dart';

import '../../../core/constants/debug_flags.dart';
import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/piece_image_mapper.dart';
import '../engine/path/piece_paths.dart';
import '../models/drag_state.dart';
import '../models/piece_flight.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import 'debug_overlay_painter.dart';
import 'puzzle_piece_painter.dart';

/// The layer a piece lives in once the child has hold of it (§10, §17, §20).
///
/// It sits above the board and the tray, so the piece is always on top, and
/// it is the *only* thing that rebuilds while the finger moves — it listens
/// to notifiers instead of the provider (§17).
///
/// It also owns the moment after the drop: the piece keeps belonging to
/// this layer while it settles into its slot or wobbles home, so it is
/// never drawn in two places at once.
class DragLayer extends StatefulWidget {
  const DragLayer({
    super.key,
    required this.drag,
    required this.flight,
    required this.onFlightComplete,
    required this.pieceOf,
    required this.image,
    required this.grid,
    required this.paths,
    required this.boardSize,
    required this.boardOrigin,
    this.backgroundCategory,
  });

  final ValueListenable<DragState?> drag;
  final ValueListenable<PieceFlight?> flight;

  /// Called once the post-drop animation has finished, so the piece can
  /// finally change hands.
  final void Function(PieceFlight flight) onFlightComplete;

  final PuzzlePiece Function(int pieceId) pieceOf;
  final ui.Image image;
  final PuzzleGrid grid;
  final PiecePaths paths;
  final Size boardSize;

  /// Where the board starts inside this layer's coordinate space.
  final Offset boardOrigin;

  /// Picks the surface painted under the transparent artwork (§34).
  final PuzzleCategory? backgroundCategory;

  @override
  State<DragLayer> createState() => _DragLayerState();
}

class _DragLayerState extends State<DragLayer> with TickerProviderStateMixin {
  /// Built eagerly: a lazy `late final` would be created *by* dispose() if
  /// the screen closed without a single drag, asking a dying tree for a
  /// ticker.
  late final AnimationController _lift;
  late final AnimationController _flight;
  int? _liftedPieceId;

  /// §20 — the whole answer to a wrong drop.
  static final Animatable<double> _rubberBand = TweenSequence<double>([
    TweenSequenceItem(
      tween: Tween<double>(begin: 1, end: PuzzleConfig.rubberBandOvershoot),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(
        begin: PuzzleConfig.rubberBandOvershoot,
        end: PuzzleConfig.rubberBandUndershoot,
      ),
      weight: 1,
    ),
    TweenSequenceItem(
      tween: Tween<double>(begin: PuzzleConfig.rubberBandUndershoot, end: 1),
      weight: 1,
    ),
  ]);

  @override
  void initState() {
    super.initState();
    _lift = AnimationController(
      vsync: this,
      duration: PuzzleConfig.dragLiftDuration,
    );
    _flight = AnimationController(
      vsync: this,
      duration: PuzzleConfig.snapSettleDuration,
    );
    _flight.addStatusListener(_onFlightStatus);
    widget.drag.addListener(_onDragChanged);
    widget.flight.addListener(_onFlightChanged);
  }

  @override
  void didUpdateWidget(DragLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.drag, widget.drag)) {
      oldWidget.drag.removeListener(_onDragChanged);
      widget.drag.addListener(_onDragChanged);
    }
    if (!identical(oldWidget.flight, widget.flight)) {
      oldWidget.flight.removeListener(_onFlightChanged);
      widget.flight.addListener(_onFlightChanged);
    }
  }

  void _onDragChanged() {
    final state = widget.drag.value;
    if (state == null) {
      _liftedPieceId = null;
      return;
    }
    if (state.pieceId != _liftedPieceId) {
      _liftedPieceId = state.pieceId;
      _lift.forward(from: 0);
    }
  }

  void _onFlightChanged() {
    final flight = widget.flight.value;
    if (flight == null) return;
    _flight
      ..duration = flight.kind == PieceFlightKind.settle
          ? PuzzleConfig.snapSettleDuration
          : PuzzleConfig.rubberBandDuration
      ..forward(from: 0);
  }

  void _onFlightStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    final flight = widget.flight.value;
    if (flight != null) widget.onFlightComplete(flight);
  }

  @override
  void dispose() {
    widget.drag.removeListener(_onDragChanged);
    widget.flight.removeListener(_onFlightChanged);
    _lift.dispose();
    _flight.dispose();
    super.dispose();
  }

  /// Grows from the tray scale to full size, swelling past it on the way
  /// and settling exactly on 1.0 (§17).
  double _liftScale(DragState drag) {
    final progress = Curves.easeOut.transform(_lift.value);
    final base = ui.lerpDouble(drag.fromScale, 1, progress)!;
    final emphasis = 1 +
        (PuzzleConfig.dragEmphasisScale - 1) * math.sin(math.pi * _lift.value);
    return base * emphasis;
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: ValueListenableBuilder<DragState?>(
          valueListenable: widget.drag,
          builder: (context, drag, _) {
            return ValueListenableBuilder<PieceFlight?>(
              valueListenable: widget.flight,
              builder: (context, flight, _) {
                final showOverlay = kDebugMode && debugShowPuzzleOverlay;
                if (drag == null && flight == null && !showOverlay) {
                  return const SizedBox.shrink();
                }

                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    if (showOverlay)
                      Positioned(
                        left: widget.boardOrigin.dx,
                        top: widget.boardOrigin.dy,
                        child: SizedBox(
                          width: widget.boardSize.width,
                          height: widget.boardSize.height,
                          child: CustomPaint(
                            size: widget.boardSize,
                            painter: DebugOverlayPainter(
                              grid: widget.grid,
                              drag: drag,
                            ),
                          ),
                        ),
                      ),
                    if (drag != null) _draggedPiece(drag),
                    if (flight != null) _flyingPiece(flight),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _draggedPiece(DragState drag) {
    final origin = widget.boardOrigin + drag.pieceOriginBoardLocal;

    return Positioned(
      left: origin.dx,
      top: origin.dy,
      child: RepaintBoundary(
        key: ValueKey('drag-piece-${drag.pieceId}'),
        child: AnimatedBuilder(
          animation: _lift,
          builder: (context, child) => Transform.scale(
            scale: _liftScale(drag),
            alignment: Alignment.topLeft,
            // Scale about the grab point so it stays under the finger
            // while the piece grows (§9).
            origin: drag.grabOffset,
            child: child,
          ),
          child: _pieceCanvas(drag.pieceId),
        ),
      ),
    );
  }

  Widget _flyingPiece(PieceFlight flight) {
    return AnimatedBuilder(
      animation: _flight,
      builder: (context, child) {
        final progress = Curves.easeOut.transform(_flight.value);
        final position = Offset.lerp(flight.from, flight.to, progress)!;
        final scale =
            ui.lerpDouble(flight.fromScale, flight.toScale, progress)!;
        // §20 sends a wrong drop home with a wobble; §22 gives a right one
        // a small squash as it lands. Neither changes where it ends up.
        final wobble = switch (flight.kind) {
          PieceFlightKind.snapBack => _rubberBand.transform(_flight.value),
          PieceFlightKind.settle => 1 +
              (PuzzleConfig.settlePopScale - 1) *
                  math.sin(math.pi * _flight.value),
        };

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Transform.scale(
            scale: scale * wobble,
            alignment: Alignment.topLeft,
            child: child,
          ),
        );
      },
      child: RepaintBoundary(
        key: ValueKey('flight-piece-${flight.pieceId}'),
        child: _pieceCanvas(flight.pieceId),
      ),
    );
  }

  /// The board's gradient as seen from this piece's home, so a piece keeps
  /// its own shade while it is in the air.
  PieceBackground? _backgroundFor(PuzzlePiece piece) {
    final category = widget.backgroundCategory;
    if (category == null) return null;
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: widget.grid,
      boardSize: widget.boardSize,
    );
    return PuzzlePalette.backgroundFor(
      category,
      boardRect: Rect.fromLTWH(
        -origin.dx,
        -origin.dy,
        widget.boardSize.width,
        widget.boardSize.height,
      ),
    );
  }

  Widget _pieceCanvas(int pieceId) {
    final piece = widget.pieceOf(pieceId);
    final cellSize = CoordinateMapper.cellSizeOf(widget.grid, widget.boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);
    final imageSize = Size(
      widget.image.width.toDouble(),
      widget.image.height.toDouble(),
    );

    return SizedBox(
      width: pieceSize.width,
      height: pieceSize.height,
      child: CustomPaint(
        size: pieceSize,
        painter: PuzzlePiecePainter(
          image: widget.image,
          renderPath: widget.paths.renderOf(piece.id),
          background: _backgroundFor(piece),
          rects: PieceImageMapper.rectsOf(
            piece: piece,
            grid: widget.grid,
            boardSize: widget.boardSize,
            imageSize: imageSize,
          ),
          elevation: PuzzleConfig.dragElevation,
        ),
      ),
    );
  }
}
