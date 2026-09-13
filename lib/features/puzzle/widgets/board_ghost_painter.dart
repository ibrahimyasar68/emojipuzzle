import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
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
    this.slotOutlines = const <int, Path>{},
    this.filledPieceIds = const <int>{},
  });

  final ui.Image image;
  final PuzzleGrid grid;

  /// The dashed outline of each slot, by piece id, in board coordinates
  /// (§15). Built once by [PiecePaths]; this painter only draws it.
  final Map<int, Path> slotOutlines;

  /// Pieces that are already on the board.
  ///
  /// A filled slot stops asking to be filled: its dashed outline is not
  /// drawn any more. The piece is opaque and covers its own outline, but
  /// its tabs reach into the slots next door, so an outline left behind
  /// would show through the finished picture (§15).
  final Set<int> filledPieceIds;

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

    for (final entry in slotOutlines.entries) {
      if (filledPieceIds.contains(entry.key)) continue;
      canvas.drawPath(entry.value, outline);
    }
  }

  @override
  bool shouldRepaint(BoardGhostPainter oldDelegate) =>
      !setEquals(oldDelegate.filledPieceIds, filledPieceIds) ||
      !identical(oldDelegate.slotOutlines, slotOutlines) ||
      !identical(oldDelegate.image, image) ||
      oldDelegate.grid != grid ||
      oldDelegate.background != background;
}
