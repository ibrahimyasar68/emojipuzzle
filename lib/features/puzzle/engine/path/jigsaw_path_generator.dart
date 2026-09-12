import 'dart:ui' show Offset, Path, Size;

import '../../models/edge_type.dart';
import '../../models/puzzle_piece.dart';
import '../geometry/coordinate_mapper.dart';

/// One cubic segment of the knob, expressed in edge space.
class _KnobCubic {
  const _KnobCubic(this.control1, this.control2, this.end);

  final Offset control1;
  final Offset control2;
  final Offset end;
}

/// Knob profile in edge space (§7).
///
/// `dx` = u, the fraction travelled along the edge (0 → 1).
/// `dy` = v, the perpendicular distance in tabSize units; positive points
/// away from the cell, so a tab uses `+v` and a blank the mirrored `-v`.
///
/// Two properties of this table are load-bearing:
///
/// 1. It is symmetric about `u = 0.5`. A tab and the neighbouring blank
///    trace the same edge in opposite directions, so the two pieces meet
///    without a gap or an overlap.
/// 2. No control point exceeds `v = 1.0`, so the knob reaches exactly the
///    piece bounding box and never spills out of it (§7).
const _knobLeadInU = 0.35;

const _knobCurves = <_KnobCubic>[
  // Neck: swings out, then back in to undercut the head.
  _KnobCubic(Offset(0.45, 0.00), Offset(0.27, 0.45), Offset(0.31, 0.72)),
  // Head, left half, up to the apex.
  _KnobCubic(Offset(0.35, 1.00), Offset(0.44, 1.00), Offset(0.50, 1.00)),
  // Head, right half (mirror of the left).
  _KnobCubic(Offset(0.56, 1.00), Offset(0.65, 1.00), Offset(0.69, 0.72)),
  // Neck, mirrored.
  _KnobCubic(Offset(0.73, 0.45), Offset(0.55, 0.00), Offset(0.65, 0.00)),
];

/// Builds the outline of a single piece (§5, §7).
///
/// The path is in **piece-local coordinates**: `(0,0)` is the top-left of
/// the piece bounding box, and the cell body starts at `(tabSize, tabSize)`.
/// Tabs reach the bounding box edge; blanks bite into the cell.
abstract final class JigsawPathGenerator {
  /// Traverses the cell clockwise: top, right, bottom, left.
  static Path build({required PuzzlePiece piece, required Size cellSize}) {
    assert(!cellSize.isEmpty, 'cellSize must be non-empty');
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);

    final topLeft = Offset(tabSize, tabSize);
    final topRight = topLeft + Offset(cellSize.width, 0);
    final bottomRight = topLeft + Offset(cellSize.width, cellSize.height);
    final bottomLeft = topLeft + Offset(0, cellSize.height);

    final path = Path()..moveTo(topLeft.dx, topLeft.dy);
    _addEdge(path, topLeft, topRight, piece.top, tabSize);
    _addEdge(path, topRight, bottomRight, piece.right, tabSize);
    _addEdge(path, bottomRight, bottomLeft, piece.bottom, tabSize);
    _addEdge(path, bottomLeft, topLeft, piece.left, tabSize);

    return path..close();
  }

  static void _addEdge(
    Path path,
    Offset start,
    Offset end,
    EdgeType type,
    double tabSize,
  ) {
    if (type == EdgeType.flat) {
      path.lineTo(end.dx, end.dy);
      return;
    }

    final along = end - start;
    final length = along.distance;
    final unit = along / length;
    // Clockwise traversal, so this points away from the cell.
    final outward = Offset(unit.dy, -unit.dx);
    final direction = type == EdgeType.tab ? 1.0 : -1.0;

    Offset at(Offset uv) =>
        start +
        unit * (uv.dx * length) +
        outward * (uv.dy * tabSize * direction);

    final leadIn = at(const Offset(_knobLeadInU, 0));
    path.lineTo(leadIn.dx, leadIn.dy);

    for (final curve in _knobCurves) {
      final c1 = at(curve.control1);
      final c2 = at(curve.control2);
      final e = at(curve.end);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
    }

    path.lineTo(end.dx, end.dy);
  }
}
