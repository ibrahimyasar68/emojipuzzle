import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../engine/geometry/coordinate_mapper.dart';
import '../models/puzzle_grid.dart';

/// The empty board: the picture showing faintly through, plus a dashed
/// outline around every slot (§15).
///
/// Both cues are there for a child who cannot read: the ghost says *what*
/// goes here, the outline says *something* goes here.
class BoardGhostPainter extends CustomPainter {
  const BoardGhostPainter({
    required this.image,
    required this.grid,
    this.background,
  });

  final ui.Image image;
  final PuzzleGrid grid;

  /// The surface the pieces themselves are painted on, so the empty board
  /// promises the picture that is coming (§15, §34).
  final PieceBackground? background;

  // Written as explicit channel values so the painter does not depend on
  // Color.withValues, which only exists from Flutter 3.27 (§0 allows 3.24).
  static const _ghostVeil = Color.fromRGBO(0, 0, 0, PuzzleConfig.ghostOpacity);
  static const _outlineColour = Color.fromRGBO(141, 110, 99, 0.45);

  @override
  void paint(Canvas canvas, Size size) {
    final board = Offset.zero & size;

    canvas.saveLayer(board, Paint()..color = _ghostVeil);
    final surface = background;
    if (surface != null) {
      canvas.drawRect(
        board,
        Paint()
          ..shader = ui.Gradient.linear(
            surface.boardRect.topLeft,
            surface.boardRect.bottomRight,
            [surface.from, surface.to],
          ),
      );
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      board,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true,
    );
    canvas.restore();

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = PuzzleConfig.slotOutlineStrokeWidth
      ..color = _outlineColour
      ..isAntiAlias = true;

    final cell = CoordinateMapper.cellSizeOf(grid, size);
    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        canvas.drawPath(
          _dashed(
            Rect.fromLTWH(
              column * cell.width,
              row * cell.height,
              cell.width,
              cell.height,
            ),
          ),
          outline,
        );
      }
    }
  }

  /// A dashed rectangle. The edges are straight, so the dashes can be laid
  /// out directly instead of walking path metrics every frame.
  Path _dashed(Rect rect) {
    final path = Path();
    const dash = PuzzleConfig.slotOutlineDashLength;
    const gap = PuzzleConfig.slotOutlineDashGap;

    void run(Offset from, Offset to) {
      final delta = to - from;
      final length = delta.distance;
      if (length == 0) return;
      final step = delta / length;
      for (var travelled = 0.0; travelled < length; travelled += dash + gap) {
        final end = travelled + dash < length ? travelled + dash : length;
        path
          ..moveTo(
            from.dx + step.dx * travelled,
            from.dy + step.dy * travelled,
          )
          ..lineTo(from.dx + step.dx * end, from.dy + step.dy * end);
      }
    }

    run(rect.topLeft, rect.topRight);
    run(rect.topRight, rect.bottomRight);
    run(rect.bottomRight, rect.bottomLeft);
    run(rect.bottomLeft, rect.topLeft);
    return path;
  }

  @override
  bool shouldRepaint(BoardGhostPainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      oldDelegate.grid != grid ||
      oldDelegate.background != background;
}
