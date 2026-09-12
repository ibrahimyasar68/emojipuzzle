import 'dart:math' show Random, min;
import 'dart:ui' show Offset, Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/test_grids.dart';

/// §6.1 max board, and the §16.1 reference phone board.
const _boardSizes = [Size(500, 500), Size(344, 344)];

void main() {
  group('global ↔ board', () {
    test('round-trip', () {
      const boardOrigin = Offset(8, 120);
      const global = Offset(210.5, 333.25);
      final board = CoordinateMapper.globalToBoard(global, boardOrigin);
      expect(board, const Offset(202.5, 213.25));
      expectOffsetClose(
        CoordinateMapper.boardToGlobal(board, boardOrigin),
        global,
      );
    });
  });

  group('pixel ↔ normalized', () {
    test('pixelOf scales by board size', () {
      expect(
        CoordinateMapper.pixelOf(const Offset(0.5, 0.25), const Size(500, 500)),
        const Offset(250, 125),
      );
    });

    test('round-trip within tolerance', () {
      final random = Random(1);
      for (final board in _boardSizes) {
        for (var i = 0; i < 100; i++) {
          final normalized = Offset(random.nextDouble(), random.nextDouble());
          final pixel = CoordinateMapper.pixelOf(normalized, board);
          expectOffsetClose(
            CoordinateMapper.normalizedOf(pixel, board),
            normalized,
          );
        }
      }
    });
  });

  group('cell / tab / piece size', () {
    test('2×3 on 500: non-square cells, tab from the short edge', () {
      const grid = PuzzleGrid(rows: 2, columns: 3);
      final cell = CoordinateMapper.cellSizeOf(grid, const Size(500, 500));
      expect(cell.width, closeTo(500 / 3, coordinateTolerance));
      expect(cell.height, closeTo(250, coordinateTolerance));

      final tab = CoordinateMapper.tabSizeOf(cell);
      expect(tab, closeTo(500 / 3 * 0.20, coordinateTolerance));

      final piece = CoordinateMapper.pieceSizeOf(cell);
      expect(piece.width, closeTo(500 / 3 + 2 * tab, coordinateTolerance));
      expect(piece.height, closeTo(250 + 2 * tab, coordinateTolerance));
    });

    for (final grid in supportedGrids) {
      for (final board in _boardSizes) {
        test('$grid on $board: tabSize and pieceSize contract', () {
          final cell = CoordinateMapper.cellSizeOf(grid, board);
          final tab = CoordinateMapper.tabSizeOf(cell);
          final piece = CoordinateMapper.pieceSizeOf(cell);

          expect(
            tab,
            closeTo(
              min(cell.width, cell.height) * PuzzleConfig.tabSizeRatio,
              coordinateTolerance,
            ),
          );
          expect(
              piece.width, closeTo(cell.width + 2 * tab, coordinateTolerance));
          expect(piece.height,
              closeTo(cell.height + 2 * tab, coordinateTolerance));
        });
      }
    }
  });

  group('normalizedPosition contract (§8.5)', () {
    for (final grid in supportedGrids) {
      for (final board in _boardSizes) {
        test('$grid on $board: cell origin vs piece origin', () {
          final pieces = PuzzleGenerator(random: Random(3)).generate(grid);
          final cell = CoordinateMapper.cellSizeOf(grid, board);
          final tab = CoordinateMapper.tabSizeOf(cell);

          for (final p in pieces) {
            final cellOrigin =
                CoordinateMapper.pixelOf(p.normalizedPosition, board);
            // normalizedPosition is the *cell* top-left…
            expectOffsetClose(
              cellOrigin,
              Offset(p.column * cell.width, p.row * cell.height),
              reason: 'piece ${p.id} cell origin',
            );
            // …and the piece path origin sits one tab up-left of it.
            expectOffsetClose(
              CoordinateMapper.pieceOriginOf(
                normalizedPosition: p.normalizedPosition,
                grid: grid,
                boardSize: board,
              ),
              cellOrigin - Offset(tab, tab),
              reason: 'piece ${p.id} piece origin',
            );
          }
        });
      }
    }

    test('top-left piece: normalized is (0,0), piece origin is negative', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      const board = Size(500, 500);
      final corner = PuzzleGenerator(random: Random(0)).generate(grid).first;
      expect(corner.normalizedPosition, Offset.zero);

      final origin = CoordinateMapper.pieceOriginOf(
        normalizedPosition: corner.normalizedPosition,
        grid: grid,
        boardSize: board,
      );
      expect(origin.dx, lessThan(0));
      expect(origin.dy, lessThan(0));
    });
  });

  group('grab offset (§9)', () {
    test('round-trip keeps the grab point under the finger', () {
      const pieceOrigin = Offset(40, 60);
      const pointerDown = Offset(95, 70); // grabbed near the top-right
      final grab = CoordinateMapper.grabOffsetOf(
        pointerBoardLocal: pointerDown,
        pieceOriginBoardLocal: pieceOrigin,
      );
      expect(grab, const Offset(55, 10));

      // No jump on the first frame.
      expectOffsetClose(
        CoordinateMapper.pieceOriginFromPointer(
          pointerBoardLocal: pointerDown,
          grabOffset: grab,
        ),
        pieceOrigin,
      );

      // Moving the finger moves the piece by exactly the same delta.
      const delta = Offset(-120.5, 33.25);
      expectOffsetClose(
        CoordinateMapper.pieceOriginFromPointer(
          pointerBoardLocal: pointerDown + delta,
          grabOffset: grab,
        ),
        pieceOrigin + delta,
      );
    });
  });
}
