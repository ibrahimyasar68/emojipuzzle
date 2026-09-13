import 'dart:ui' show Offset, Path, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import '../geometry/coordinate_mapper.dart';
import 'jigsaw_path_generator.dart';

/// Immutable path cache for one board size (§14, §42).
///
/// Paths are built once per puzzle and reused for every frame; nothing
/// builds a [Path] inside `build()` or `paint()`.
///
/// One path per piece, used for hit-testing, snapping, clipping and
/// painting alike.
///
/// There used to be a second, slightly larger copy of each outline, so that
/// neighbours overlapped by a hair and anti-aliasing could not leave a
/// visible seam between them (§14). Growing these curves with boolean path
/// operations turned out not to work at all — the knob's neck crosses its
/// own head, and the union came back as a different shape while its
/// bounding box looked exactly right. The bleed now belongs to
/// `PuzzlePiecePainter`, which strokes the outline.
///
/// Paths depend on the board size, so a resize invalidates the whole set.
/// Callers check [matches] and rebuild only when it returns false.
class PiecePaths {
  PiecePaths._(this.boardSize, this._paths, this._dashedSlots);

  factory PiecePaths.build({
    required List<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    required Size boardSize,
  }) {
    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);

    final paths = <int, Path>{
      for (final piece in pieces)
        piece.id: JigsawPathGenerator.build(piece: piece, cellSize: cellSize),
    };
    // §15 — the dashed outline a child sees around an empty slot, built
    // here so `paint` never has to walk a path (§42).
    final slots = <int, Path>{
      for (final piece in pieces)
        piece.id: _dashedSlot(
          piece: piece,
          grid: grid,
          boardSize: boardSize,
          cellSize: cellSize,
        ),
    };

    return PiecePaths._(
      boardSize,
      Map.unmodifiable(paths),
      Map.unmodifiable(slots),
    );
  }

  /// The board size these paths were built for.
  final Size boardSize;

  final Map<int, Path> _paths;
  final Map<int, Path> _dashedSlots;

  /// Exact piece outline, in piece-local coordinates.
  Path of(int pieceId) => _pathFrom(_paths, pieceId);

  /// The dashed outline of every slot, by piece id (§15).
  ///
  /// **These are in board coordinates**, unlike [of], which is piece-local:
  /// they are drawn by the board's ghost layer, which has no piece to be
  /// local to. The translation is done once, here.
  Map<int, Path> get dashedSlots => _dashedSlots;

  int get length => _paths.length;

  /// Whether this cache is still valid for [candidate].
  bool matches(Size candidate) => boardSize == candidate;

  /// The four edges of one slot, dashed, in board coordinates.
  ///
  /// Built edge by edge rather than from the closed outline, because each
  /// edge has to be walked in a fixed direction: a piece's right edge and
  /// its neighbour's left edge are the same curve, and only identical
  /// walks produce identical dashes. Dashing the closed outline instead
  /// starts each piece at its own corner, so the two sides of every seam
  /// fall out of step and fill each other's gaps — a seam that should be
  /// dashed comes out solid.
  static Path _dashedSlot({
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
    required Size cellSize,
  }) {
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );

    final dashed = Path();
    for (final side in PieceSide.values) {
      final edge = JigsawPathGenerator.edgePath(
        piece: piece,
        side: side,
        cellSize: cellSize,
      );
      for (final metric in edge.computeMetrics()) {
        var travelled = 0.0;
        while (travelled < metric.length) {
          final end = (travelled + PuzzleConfig.slotOutlineDashLength)
              .clamp(0.0, metric.length);
          dashed.addPath(
            metric.extractPath(travelled, end),
            Offset.zero,
          );
          travelled = end + PuzzleConfig.slotOutlineDashGap;
        }
      }
    }
    return dashed.shift(origin);
  }

  Path _pathFrom(Map<int, Path> source, int pieceId) =>
      source[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'no path for this piece'));
}
