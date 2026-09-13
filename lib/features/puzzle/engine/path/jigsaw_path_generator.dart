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

/// Which side of the cell an edge is on.
enum PieceSide { top, right, bottom, left }

/// Builds the outline of a single piece (§5, §7).
///
/// The path is in **piece-local coordinates**: `(0,0)` is the top-left of
/// the piece bounding box, and the cell body starts at `(tabSize, tabSize)`.
/// Tabs reach the bounding box edge; blanks bite into the cell.
abstract final class JigsawPathGenerator {
  /// Traverses the cell clockwise: top, right, bottom, left.
  static Path build({required PuzzlePiece piece, required Size cellSize}) {
    assert(!cellSize.isEmpty, 'cellSize must be non-empty');
    final corners = _cornersOf(cellSize);
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);

    final path = Path()..moveTo(corners.topLeft.dx, corners.topLeft.dy);
    _addEdge(
      path,
      corners.topLeft,
      corners.topRight,
      const Offset(0, -1),
      piece.top,
      tabSize,
    );
    _addEdge(
      path,
      corners.topRight,
      corners.bottomRight,
      const Offset(1, 0),
      piece.right,
      tabSize,
    );
    _addEdge(
      path,
      corners.bottomRight,
      corners.bottomLeft,
      const Offset(0, 1),
      piece.bottom,
      tabSize,
    );
    _addEdge(
      path,
      corners.bottomLeft,
      corners.topLeft,
      const Offset(-1, 0),
      piece.left,
      tabSize,
    );

    return path..close();
  }

  /// One edge on its own, always drawn left to right or top to bottom.
  ///
  /// The direction is fixed on purpose. Two neighbours share an edge — one
  /// side's tab is the other's blank, and they trace the same curve — so
  /// walking it the same way from both sides produces the *same path*, down
  /// to the point. Anything derived from it, dashes especially, then lines
  /// up instead of interleaving into a solid line (§15).
  static Path edgePath({
    required PuzzlePiece piece,
    required PieceSide side,
    required Size cellSize,
  }) {
    assert(!cellSize.isEmpty, 'cellSize must be non-empty');
    final corners = _cornersOf(cellSize);
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);

    final (start, end, outward, type) = switch (side) {
      PieceSide.top => (
          corners.topLeft,
          corners.topRight,
          const Offset(0, -1),
          piece.top,
        ),
      PieceSide.bottom => (
          corners.bottomLeft,
          corners.bottomRight,
          const Offset(0, 1),
          piece.bottom,
        ),
      PieceSide.left => (
          corners.topLeft,
          corners.bottomLeft,
          const Offset(-1, 0),
          piece.left,
        ),
      PieceSide.right => (
          corners.topRight,
          corners.bottomRight,
          const Offset(1, 0),
          piece.right,
        ),
    };

    final path = Path()..moveTo(start.dx, start.dy);
    _addEdge(path, start, end, outward, type, tabSize);
    return path;
  }

  static ({
    Offset topLeft,
    Offset topRight,
    Offset bottomRight,
    Offset bottomLeft,
  }) _cornersOf(Size cellSize) {
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);
    final topLeft = Offset(tabSize, tabSize);
    return (
      topLeft: topLeft,
      topRight: topLeft + Offset(cellSize.width, 0),
      bottomRight: topLeft + Offset(cellSize.width, cellSize.height),
      bottomLeft: topLeft + Offset(0, cellSize.height),
    );
  }

  /// [outward] points away from the cell, whichever way the edge is being
  /// walked. It cannot be derived from the direction of travel any more:
  /// [edgePath] walks the bottom and left edges the opposite way round from
  /// [build].
  static void _addEdge(
    Path path,
    Offset start,
    Offset end,
    Offset outward,
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
