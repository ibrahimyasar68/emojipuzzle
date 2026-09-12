import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/piece_image_mapper.dart';
import '../engine/path/piece_paths.dart';
import '../models/hint_stage.dart';
import '../models/puzzle_category.dart';
import '../models/puzzle_grid.dart';
import '../models/puzzle_piece.dart';
import 'puzzle_piece_painter.dart';

/// Draws the louder half of a hint: the slot breathing, and the ghost that
/// drifts to it (§21).
///
/// The quiet half — the tray piece pulsing — belongs to the tray, where the
/// piece already lives. Both take no touches: a hint is an offer, and the
/// child must be able to ignore it or play straight through it (§20).
class HintLayer extends StatefulWidget {
  const HintLayer({
    super.key,
    required this.stage,
    required this.target,
    required this.image,
    required this.grid,
    required this.paths,
    required this.boardSize,
    required this.boardOrigin,
    required this.trayPieceOrigin,
    required this.trayScale,
    this.backgroundCategory,
  });

  final HintStage stage;

  /// The piece being pointed at, or null when there is nothing to suggest.
  final PuzzlePiece? target;

  final ui.Image image;
  final PuzzleGrid grid;
  final PiecePaths paths;
  final Size boardSize;

  /// Both in the coordinates of the stack this layer paints into.
  final Offset boardOrigin;
  final Offset trayPieceOrigin;

  final double trayScale;
  final PuzzleCategory? backgroundCategory;

  @override
  State<HintLayer> createState() => _HintLayerState();
}

class _HintLayerState extends State<HintLayer> with TickerProviderStateMixin {
  late final AnimationController _pulse;
  late final AnimationController _ghost;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: PuzzleConfig.hintPulseDuration,
    );
    _ghost = AnimationController(
      vsync: this,
      duration: PuzzleConfig.hintGhostDuration,
    );
    _syncAnimations();
  }

  @override
  void didUpdateWidget(HintLayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.stage != widget.stage || oldWidget.target != widget.target) {
      _syncAnimations();
    }
  }

  void _syncAnimations() {
    final wantsPulse = widget.target != null &&
        widget.stage.index >= HintStage.pulseBoth.index;
    final wantsGhost =
        widget.target != null && widget.stage == HintStage.ghostMove;

    if (wantsPulse && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!wantsPulse && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }

    if (wantsGhost && !_ghost.isAnimating) {
      _ghost.repeat();
    } else if (!wantsGhost && _ghost.isAnimating) {
      _ghost.stop();
      _ghost.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    _ghost.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    if (target == null || widget.stage.index < HintStage.pulseBoth.index) {
      return const SizedBox.shrink();
    }

    final cellSize = CoordinateMapper.cellSizeOf(widget.grid, widget.boardSize);
    final slotOrigin = widget.boardOrigin +
        CoordinateMapper.pixelOf(target.normalizedPosition, widget.boardSize);

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: slotOrigin.dx,
              top: slotOrigin.dy,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (context, _) => CustomPaint(
                  key: const ValueKey('hint-slot-pulse'),
                  size: cellSize,
                  painter: _SlotPulsePainter(progress: _pulse.value),
                ),
              ),
            ),
            if (widget.stage == HintStage.ghostMove) _travellingGhost(target),
          ],
        ),
      ),
    );
  }

  /// A faded copy of the piece, drifting from the tray to where it belongs
  /// and starting over until the child does something (§21).
  Widget _travellingGhost(PuzzlePiece target) {
    final cellSize = CoordinateMapper.cellSizeOf(widget.grid, widget.boardSize);
    final pieceSize = CoordinateMapper.pieceSizeOf(cellSize);
    final imageSize = Size(
      widget.image.width.toDouble(),
      widget.image.height.toDouble(),
    );
    final restingOrigin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: target.normalizedPosition,
      grid: widget.grid,
      boardSize: widget.boardSize,
    );
    final destination = widget.boardOrigin + restingOrigin;

    return AnimatedBuilder(
      animation: _ghost,
      builder: (context, child) {
        final progress = Curves.easeInOut.transform(_ghost.value);
        final position =
            Offset.lerp(widget.trayPieceOrigin, destination, progress)!;
        final scale = ui.lerpDouble(widget.trayScale, 1, progress)!;
        // Fades out as it arrives, so the ghost never looks like a piece
        // that is actually there.
        final opacity = PuzzleConfig.hintGhostOpacity * (1 - progress * 0.6);

        return Positioned(
          left: position.dx,
          top: position.dy,
          child: Opacity(
            opacity: opacity.clamp(0.0, 1.0),
            child: Transform.scale(
              scale: scale,
              alignment: Alignment.topLeft,
              child: child,
            ),
          ),
        );
      },
      child: SizedBox(
        key: const ValueKey('hint-ghost'),
        width: pieceSize.width,
        height: pieceSize.height,
        child: CustomPaint(
          size: pieceSize,
          painter: PuzzlePiecePainter(
            image: widget.image,
            renderPath: widget.paths.of(target.id),
            background: _backgroundFor(restingOrigin),
            rects: PieceImageMapper.rectsOf(
              piece: target,
              grid: widget.grid,
              boardSize: widget.boardSize,
              imageSize: imageSize,
            ),
          ),
        ),
      ),
    );
  }

  PieceBackground? _backgroundFor(Offset origin) {
    final category = widget.backgroundCategory;
    if (category == null) return null;
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
}

/// A slot breathing: "this one is empty, and something fits here" (§21).
class _SlotPulsePainter extends CustomPainter {
  const _SlotPulsePainter({required this.progress});

  final double progress;

  static const _red = 255;
  static const _green = 167;
  static const _blue = 38;

  @override
  void paint(Canvas canvas, Size size) {
    final swell = Curves.easeInOut.transform(progress);
    final inset = 3.0 - swell * 2;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2 + swell * 2
      ..color = Color.fromRGBO(_red, _green, _blue, 0.35 + swell * 0.35)
      ..isAntiAlias = true;

    canvas.drawRRect(
      RRect.fromRectXY(
        Rect.fromLTWH(
            inset, inset, size.width - inset * 2, size.height - inset * 2),
        8,
        8,
      ),
      paint,
    );
  }

  @override
  bool shouldRepaint(_SlotPulsePainter oldDelegate) =>
      oldDelegate.progress != progress;
}
