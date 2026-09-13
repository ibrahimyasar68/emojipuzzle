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

/// İpucunun yüksek sesli yarısını çizer: nefes alan yuva ve ona doğru
/// süzülen hayalet (§21).
///
/// Sessiz yarı — tepsideki parçanın nabzı — parçanın zaten yaşadığı yere,
/// tepsiye aittir. İkisi de dokunuş almaz: ipucu bir tekliftir ve çocuk onu
/// yok sayabilmeli ya da içinden oynayıp geçebilmelidir (§20).
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

  /// İşaret edilen parça; önerilecek bir şey yoksa null.
  final PuzzlePiece? target;

  final ui.Image image;
  final PuzzleGrid grid;
  final PiecePaths paths;
  final Size boardSize;

  /// İkisi de bu katmanın boyadığı stack'in koordinatlarında.
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

  /// Parçanın solgun bir kopyası; tepsiden ait olduğu yere süzülür ve çocuk
  /// bir şey yapana kadar baştan başlar (§21).
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
        // Varırken söner; böylece hayalet hiçbir zaman gerçekten orada
        // olan bir parçaya benzemez.
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

/// Nefes alan bir yuva: "burası boş ve buraya bir şey uyuyor" (§21).
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
