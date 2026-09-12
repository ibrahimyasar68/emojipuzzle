import 'dart:ui' show Path, Size;

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
  PiecePaths._(this.boardSize, this._paths);

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
    return PiecePaths._(boardSize, Map.unmodifiable(paths));
  }

  /// The board size these paths were built for.
  final Size boardSize;

  final Map<int, Path> _paths;

  /// Exact piece outline, in piece-local coordinates.
  Path of(int pieceId) => _pathFrom(_paths, pieceId);

  int get length => _paths.length;

  /// Whether this cache is still valid for [candidate].
  bool matches(Size candidate) => boardSize == candidate;

  Path _pathFrom(Map<int, Path> source, int pieceId) =>
      source[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'no path for this piece'));
}
