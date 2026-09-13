import 'dart:math' show Random;
import 'dart:ui' show Offset, Path, Size;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/jigsaw_path_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/edge_type.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

const _board = Size(360, 360);

/// Samples a path evenly along its length.
List<Offset> _walk(Path path, {int samples = 60}) {
  final metric = path.computeMetrics().first;
  return [
    for (var i = 0; i <= samples; i++)
      metric.getTangentForOffset(metric.length * i / samples)!.position,
  ];
}

void main() {
  group('one edge at a time (§15)', () {
    test('an edge is part of the outline it came from', () {
      const piece = PuzzlePiece(
        id: 0,
        row: 1,
        column: 1,
        top: EdgeType.tab,
        right: EdgeType.blank,
        bottom: EdgeType.tab,
        left: EdgeType.blank,
        normalizedPosition: Offset(0.5, 0.5),
      );
      const cell = Size(120, 120);
      final outline = JigsawPathGenerator.build(piece: piece, cellSize: cell);

      for (final side in PieceSide.values) {
        final edge = JigsawPathGenerator.edgePath(
          piece: piece,
          side: side,
          cellSize: cell,
        );
        for (final point in _walk(edge)) {
          // Every point of an edge sits on the boundary of the piece: just
          // inside it, or just outside, never far from either.
          final inside = outline.contains(point);
          final nudgedIn = outline.contains(
            point + const Offset(0.01, 0.01),
          );
          expect(
            inside ||
                nudgedIn ||
                outline.getBounds().inflate(1).contains(point),
            isTrue,
            reason: '$side point $point is nowhere near the outline',
          );
        }
      }
    });

    test('two neighbours draw their shared edge identically', () {
      // This is the whole reason the direction is fixed. If the two sides
      // disagree by so much as a hair, their dashes interleave and the
      // shared edge comes out solid instead of dashed.
      for (final gridSize in [
        const PuzzleGrid(rows: 2, columns: 2),
        const PuzzleGrid(rows: 2, columns: 3),
        const PuzzleGrid(rows: 3, columns: 3),
      ]) {
        final pieces = PuzzleGenerator(random: Random(3)).generate(gridSize);
        final cell = CoordinateMapper.cellSizeOf(gridSize, _board);

        PuzzlePiece at(int row, int column) => pieces.firstWhere(
              (p) => p.row == row && p.column == column,
            );

        Offset originOf(PuzzlePiece piece) => CoordinateMapper.pieceOriginOf(
              normalizedPosition: piece.normalizedPosition,
              grid: gridSize,
              boardSize: _board,
            );

        // Vertical seams: this piece's right edge is its neighbour's left.
        for (var row = 0; row < gridSize.rows; row++) {
          for (var column = 0; column < gridSize.columns - 1; column++) {
            final left = at(row, column);
            final right = at(row, column + 1);

            final fromLeft = _walk(
              JigsawPathGenerator.edgePath(
                piece: left,
                side: PieceSide.right,
                cellSize: cell,
              ).shift(originOf(left)),
            );
            final fromRight = _walk(
              JigsawPathGenerator.edgePath(
                piece: right,
                side: PieceSide.left,
                cellSize: cell,
              ).shift(originOf(right)),
            );

            for (var i = 0; i < fromLeft.length; i++) {
              expect(
                (fromLeft[i] - fromRight[i]).distance,
                lessThan(0.01),
                reason: '$gridSize seam between ($row,$column) and '
                    '($row,${column + 1}) at sample $i',
              );
            }
          }
        }

        // Horizontal seams: this piece's bottom edge is its neighbour's top.
        for (var row = 0; row < gridSize.rows - 1; row++) {
          for (var column = 0; column < gridSize.columns; column++) {
            final above = at(row, column);
            final below = at(row + 1, column);

            final fromAbove = _walk(
              JigsawPathGenerator.edgePath(
                piece: above,
                side: PieceSide.bottom,
                cellSize: cell,
              ).shift(originOf(above)),
            );
            final fromBelow = _walk(
              JigsawPathGenerator.edgePath(
                piece: below,
                side: PieceSide.top,
                cellSize: cell,
              ).shift(originOf(below)),
            );

            for (var i = 0; i < fromAbove.length; i++) {
              expect(
                (fromAbove[i] - fromBelow[i]).distance,
                lessThan(0.01),
                reason: '$gridSize seam between ($row,$column) and '
                    '(${row + 1},$column) at sample $i',
              );
            }
          }
        }
      }
    });
  });
}
