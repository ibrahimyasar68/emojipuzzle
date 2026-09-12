import 'dart:ui' show Offset, Path, PathOperation, Size;

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
/// Every piece gets two paths:
///
/// * [of] — the exact geometry. Hit-testing and snapping use this.
/// * [renderOf] — the same shape grown by [PuzzleConfig.renderBleedPixels]
///   so neighbours overlap by a hair and anti-aliasing cannot leave a
///   visible seam between them (§14).
///
/// Paths depend on the board size, so a resize invalidates the whole set.
/// Callers check [matches] and rebuild only when it returns false.
class PiecePaths {
  PiecePaths._(this.boardSize, this._paths, this._renderPaths);

  factory PiecePaths.build({
    required List<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    required Size boardSize,
    double bleed = PuzzleConfig.renderBleedPixels,
  }) {
    assert(bleed >= 0, 'bleed must not be negative');
    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);

    final paths = <int, Path>{
      for (final piece in pieces)
        piece.id: JigsawPathGenerator.build(piece: piece, cellSize: cellSize),
    };
    final renderPaths = <int, Path>{
      for (final entry in paths.entries)
        entry.key: _inflate(entry.value, bleed: bleed),
    };

    return PiecePaths._(
      boardSize,
      Map.unmodifiable(paths),
      Map.unmodifiable(renderPaths),
    );
  }

  /// The board size these paths were built for.
  final Size boardSize;

  final Map<int, Path> _paths;
  final Map<int, Path> _renderPaths;

  /// Exact piece outline, in piece-local coordinates.
  Path of(int pieceId) => _pathFrom(_paths, pieceId);

  /// Outline to paint with: [of] grown outward by the render bleed.
  Path renderOf(int pieceId) => _pathFrom(_renderPaths, pieceId);

  int get length => _paths.length;

  /// Whether this cache is still valid for [candidate].
  bool matches(Size candidate) => boardSize == candidate;

  Path _pathFrom(Map<int, Path> source, int pieceId) =>
      source[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'no path for this piece'));

  /// Grows [path] outward by [bleed] in every direction.
  ///
  /// This is the union of the outline with copies of itself nudged in eight
  /// directions, which dilates the shape evenly — the knob's neck curves
  /// back on itself, and scaling the whole outline about its centre would
  /// slide that stretch of boundary along itself instead of pushing it
  /// outward, leaving exactly the hairline gaps this is meant to close.
  ///
  /// Runs once per piece when the cache is built, never while painting.
  static Path _inflate(Path path, {required double bleed}) {
    if (bleed == 0) return path;

    const diagonal = 0.7071067811865476; // 1 / √2
    const directions = <Offset>[
      Offset(1, 0),
      Offset(-1, 0),
      Offset(0, 1),
      Offset(0, -1),
      Offset(diagonal, diagonal),
      Offset(diagonal, -diagonal),
      Offset(-diagonal, diagonal),
      Offset(-diagonal, -diagonal),
    ];

    var inflated = path;
    for (final direction in directions) {
      inflated = Path.combine(
        PathOperation.union,
        inflated,
        path.shift(direction * bleed),
      );
    }
    return inflated;
  }
}
