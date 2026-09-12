import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
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
    this.bleed = PuzzleConfig.renderBleedPixels,
  });

  /// Decoded once per puzzle and shared by every piece (§14).
  final ui.Image image;

  /// The piece outline, in piece-local coordinates.
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

  /// §14 — how far the piece is painted past its own outline.
  ///
  /// Two neighbours share a boundary, and two half-covered anti-aliased
  /// edges do not add up to an opaque one: without this there is a visible
  /// hairline between them. The piece is drawn once a hair larger and then
  /// again at its true size on top, so the overlap is real picture rather
  /// than a smeared edge.
  ///
  /// This used to be done by growing the outline itself. It is done here
  /// instead because dilating these particular curves with boolean path
  /// operations does not work — see `PiecePaths`.
  final double bleed;

  static const _shadowColour = Color(0xFF6D4C41);

  @override
  void paint(Canvas canvas, Size size) {
    if (elevation > 0) {
      canvas.drawShadow(renderPath, _shadowColour, elevation, false);
    }

    final surface = background;
    if (surface != null) {
      // The gradient runs across the whole board, so neighbouring pieces
      // continue each other instead of forming a patchwork.
      _draw(
        canvas,
        ui.Gradient.linear(
          surface.boardRect.topLeft,
          surface.boardRect.bottomRight,
          [surface.from, surface.to],
        ),
      );
    }
    _draw(canvas, _imageShader());
  }

  /// Fills the outline with [shader], then runs the same shader along the
  /// outline as a stroke.
  ///
  /// The stroke is the bleed (§14): half of a `bleed * 2` line sits outside
  /// the path, which pushes the painted edge out by exactly [bleed]
  /// everywhere, including the knob's neck where the boundary doubles back
  /// on itself. Growing the *path* instead does not survive these curves —
  /// see `PiecePaths`.
  void _draw(Canvas canvas, ui.Shader shader) {
    canvas.drawPath(
      renderPath,
      Paint()
        ..shader = shader
        ..isAntiAlias = true,
    );
    if (bleed <= 0) return;
    canvas.drawPath(
      renderPath,
      Paint()
        ..shader = shader
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = bleed * 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// The shared puzzle image, positioned so that [PieceDrawRects.src] lands
  /// on [PieceDrawRects.dst] in piece-local coordinates — the same mapping
  /// `drawImageRect` would do, as a shader so it can stroke as well as
  /// fill.
  ui.ImageShader _imageShader() {
    final src = rects.src;
    final dst = rects.dst;
    final scaleX = dst.width / src.width;
    final scaleY = dst.height / src.height;

    return ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList(<double>[
        scaleX, 0, 0, 0, //
        0, scaleY, 0, 0, //
        0, 0, 1, 0, //
        dst.left - src.left * scaleX, dst.top - src.top * scaleY, 0, 1,
      ]),
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(PuzzlePiecePainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      !identical(oldDelegate.renderPath, renderPath) ||
      oldDelegate.rects != rects ||
      oldDelegate.background != background ||
      oldDelegate.elevation != elevation ||
      oldDelegate.bleed != bleed;
}
