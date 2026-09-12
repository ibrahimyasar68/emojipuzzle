import 'dart:math' show Random;
import 'dart:ui' show Offset, Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/snap_calculator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:flutter_test/flutter_test.dart';

const _grid = PuzzleGrid(rows: 2, columns: 2);
const _board = Size(344, 344);

/// cell 172 → 172 × 0.35 = 60.2, comfortably above the 24 px floor.
const _expectedThreshold = 60.2;

List<PuzzlePiece> _pieces() =>
    PuzzleGenerator(random: Random(0)).generate(_grid);

Offset _restingOrigin(PuzzlePiece piece) => SnapCalculator.restingOrigin(
      piece: piece,
      grid: _grid,
      boardSize: _board,
    );

bool _snapsAt(Offset origin, PuzzlePiece piece, {int failedAttempts = 0}) =>
    SnapCalculator.snaps(
      pieceOriginBoardLocal: origin,
      piece: piece,
      grid: _grid,
      boardSize: _board,
      failedAttempts: failedAttempts,
    );

void main() {
  group('threshold (§18)', () {
    test('a share of the shorter cell edge', () {
      expect(
        SnapCalculator.thresholdFor(cellSize: const Size(172, 172)),
        closeTo(_expectedThreshold, 0.01),
      );
      // Non-square cells are judged by their short edge.
      expect(
        SnapCalculator.thresholdFor(cellSize: const Size(114.67, 172)),
        closeTo(114.67 * PuzzleConfig.snapThresholdRatio, 0.01),
      );
    });

    test('never tighter than the floor', () {
      // 50 × 0.35 = 17.5, which would be a cruel target for a 3-year-old.
      expect(
        SnapCalculator.thresholdFor(cellSize: const Size(50, 50)),
        PuzzleConfig.minSnapThreshold,
      );
    });

    test('assist widens it after three misses (§19)', () {
      const cell = Size(172, 172);
      for (final attempts in [0, 1, 2]) {
        expect(
          SnapCalculator.thresholdFor(cellSize: cell, failedAttempts: attempts),
          closeTo(_expectedThreshold, 0.01),
          reason: '$attempts misses is not assist territory yet',
        );
      }
      for (final attempts in [3, 4, 10]) {
        expect(
          SnapCalculator.thresholdFor(cellSize: cell, failedAttempts: attempts),
          closeTo(
            _expectedThreshold * PuzzleConfig.assistThresholdMultiplier,
            0.01,
          ),
          reason: 'after $attempts misses the target grows',
        );
      }
    });
  });

  group('distance is centre to centre (§18.1)', () {
    test('zero when the piece is exactly home', () {
      for (final piece in _pieces()) {
        expect(
          SnapCalculator.distanceToSlot(
            pieceOriginBoardLocal: _restingOrigin(piece),
            piece: piece,
            grid: _grid,
            boardSize: _board,
          ),
          closeTo(0, 1e-9),
          reason: 'piece ${piece.id}',
        );
      }
    });

    test('equals how far the piece was moved', () {
      final piece = _pieces().first;
      const shift = Offset(30, 40); // 3-4-5 triangle → 50
      expect(
        SnapCalculator.distanceToSlot(
          pieceOriginBoardLocal: _restingOrigin(piece) + shift,
          piece: piece,
          grid: _grid,
          boardSize: _board,
        ),
        closeTo(50, 1e-9),
      );
    });
  });

  group('the decision', () {
    test('just inside snaps, just outside does not', () {
      final piece = _pieces().first;
      final home = _restingOrigin(piece);

      expect(_snapsAt(home + const Offset(60, 0), piece), isTrue);
      expect(_snapsAt(home + const Offset(61, 0), piece), isFalse);
    });

    test('a piece never snaps into someone else\'s slot (§18.2)', () {
      final pieces = _pieces();
      for (final piece in pieces) {
        for (final other in pieces) {
          if (other.id == piece.id) continue;
          expect(
            _snapsAt(_restingOrigin(other), piece),
            isFalse,
            reason: 'piece ${piece.id} must not accept slot ${other.id}',
          );
        }
      }
    });

    test('dropping on a neighbouring cell is simply a miss', () {
      final pieces = _pieces();
      final cell = CoordinateMapper.cellSizeOf(_grid, _board);
      // One whole cell to the right of home: far outside even with assist.
      final origin = _restingOrigin(pieces.first) + Offset(cell.width, 0);

      expect(_snapsAt(origin, pieces.first), isFalse);
      expect(_snapsAt(origin, pieces.first, failedAttempts: 5), isFalse);
    });

    test('assist rescues a drop that just missed (§19)', () {
      final piece = _pieces().first;
      final origin = _restingOrigin(piece) + const Offset(70, 0);

      expect(_snapsAt(origin, piece), isFalse);
      expect(_snapsAt(origin, piece, failedAttempts: 2), isFalse);
      expect(_snapsAt(origin, piece, failedAttempts: 3), isTrue);
    });
  });

  test('restingOrigin is the piece origin contract (§8.5)', () {
    for (final piece in _pieces()) {
      expect(
        _restingOrigin(piece),
        CoordinateMapper.pieceOriginOf(
          normalizedPosition: piece.normalizedPosition,
          grid: _grid,
          boardSize: _board,
        ),
      );
    }
  });
}
