import 'package:flutter/widgets.dart';

import '../engine/geometry/coordinate_mapper.dart';
import '../engine/geometry/snap_calculator.dart';
import '../models/drag_state.dart';
import '../models/puzzle_grid.dart';

/// Geliştirici katmanı (K-4): hücre sınırları, her yuvanın etrafındaki snap
/// yarıçapı ve anlık tutma vektörü. Yalnızca debug derlemelerinde.
class DebugOverlayPainter extends CustomPainter {
  const DebugOverlayPainter({required this.grid, required this.drag});

  final PuzzleGrid grid;
  final DragState? drag;

  static const _cellColour = Color(0xFFE91E63);
  static const _snapColour = Color(0x5500BCD4);
  static const _grabColour = Color(0xFF7C4DFF);

  @override
  void paint(Canvas canvas, Size size) {
    final cell = CoordinateMapper.cellSizeOf(grid, size);

    final cellPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _cellColour;
    final snapPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = _snapColour;

    // Bir bırakmanın gerçekte hangi yarıçapa göre değerlendirildiği (§18).
    final snapRadius = SnapCalculator.thresholdFor(cellSize: cell);

    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        final rect = Rect.fromLTWH(
          column * cell.width,
          row * cell.height,
          cell.width,
          cell.height,
        );
        canvas
          ..drawRect(rect, cellPaint)
          ..drawCircle(rect.center, snapRadius, snapPaint);
      }
    }

    final active = drag;
    if (active != null) {
      canvas.drawLine(
        active.pieceOriginBoardLocal,
        active.pointerBoardLocal,
        Paint()
          ..strokeWidth = 2
          ..color = _grabColour,
      );
      canvas.drawCircle(
        active.pointerBoardLocal,
        4,
        Paint()..color = _grabColour,
      );
    }
  }

  @override
  bool shouldRepaint(DebugOverlayPainter oldDelegate) =>
      oldDelegate.grid != grid || oldDelegate.drag != drag;
}
