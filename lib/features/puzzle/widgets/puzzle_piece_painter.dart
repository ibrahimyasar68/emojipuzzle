import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../data/puzzle_palette.dart';
import '../engine/geometry/piece_image_mapper.dart';

/// Draws one piece: clip to its outline, then blit its slice of the shared
/// puzzle image (§14).
///
/// Everything expensive is precomputed: the path comes from the cache and
/// the rectangles from [PieceImageMapper], so `paint` only clips and draws.
class PuzzlePiecePainter extends CustomPainter {
  const PuzzlePiecePainter({
    required this.image,
    required this.renderPath,
    required this.rects,
    this.background,
    this.elevation = 0,
  });

  /// Decoded once per puzzle and shared by every piece (§14).
  final ui.Image image;

  /// Outline including the render bleed, in piece-local coordinates.
  final Path renderPath;

  final PieceDrawRects rects;

  /// Painted inside the outline, under the picture.
  ///
  /// The artwork is transparent by design (§34), and a see-through piece is
  /// one a child can neither see in the tray nor aim at. Null leaves the
  /// piece unpainted, for artwork that is already opaque.
  final PieceBackground? background;

  /// §17 — a dragged piece lifts off the board and casts a shadow.
  final double elevation;

  static final Paint _imagePaint = Paint()
    ..filterQuality = FilterQuality.medium
    ..isAntiAlias = true;

  static const _shadowColour = Color(0xFF6D4C41);

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation > 0) {
      canvas.drawShadow(renderPath, _shadowColour, elevation, false);
    }
    canvas.save();
    canvas.clipPath(renderPath);
    final surface = background;
    if (surface != null) {
      // The gradient runs across the whole board, so neighbouring pieces
      // continue each other instead of forming a patchwork.
      canvas.drawPaint(
        Paint()
          ..shader = ui.Gradient.linear(
            surface.boardRect.topLeft,
            surface.boardRect.bottomRight,
            [surface.from, surface.to],
          ),
      );
    }
    canvas.drawImageRect(image, rects.src, rects.dst, _imagePaint);
    canvas.restore();
  }

  @override
  bool shouldRepaint(PuzzlePiecePainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      !identical(oldDelegate.renderPath, renderPath) ||
      oldDelegate.rects != rects ||
      oldDelegate.background != background ||
      oldDelegate.elevation != elevation;
}
