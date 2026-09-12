import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/tray_layout_calculator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

/// §16.1 reference device: 360×640 dp, board 344, tray 256 — the 40 dp the
/// arithmetic is missing is the status bar and safe area.
const _board = Size(344, 344);
const _tray = Size(360, 256);

Size _pieceSizeOf(PuzzleGrid grid) =>
    CoordinateMapper.pieceSizeOf(CoordinateMapper.cellSizeOf(grid, _board));

void main() {
  group('360 dp reference phone (§16.1)', () {
    const playable = [
      PuzzleGrid(rows: 2, columns: 2),
      PuzzleGrid(rows: 2, columns: 3),
      PuzzleGrid(rows: 3, columns: 3),
    ];

    for (final grid in playable) {
      test('$grid fits with every piece above the touch target', () {
        final layout = TrayLayoutCalculator.calculate(
          traySize: _tray,
          pieceCount: grid.pieceCount,
          boardPieceSize: _pieceSizeOf(grid),
        );

        expect(layout.meetsTouchTarget, isTrue);
        expect(
          layout.itemSize.width,
          greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
          reason: '$layout',
        );
        expect(
          layout.itemSize.height,
          greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
          reason: '$layout',
        );
        expect(layout.slotCount, greaterThanOrEqualTo(grid.pieceCount));
      });
    }

    test('9 pieces land in a 3×3 tray', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      final layout = TrayLayoutCalculator.calculate(
        traySize: _tray,
        pieceCount: 9,
        boardPieceSize: _pieceSizeOf(grid),
      );
      expect(layout.rows, 3);
      expect(layout.columns, 3);
    });

    test('12 pieces cannot be played on this screen (§2 ceiling)', () {
      const grid = PuzzleGrid(rows: 3, columns: 4);
      expect(
        () => TrayLayoutCalculator.calculate(
          traySize: _tray,
          pieceCount: 12,
          boardPieceSize: _pieceSizeOf(grid),
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('the 12-piece ceiling belongs to the screen, not to the number', () {
      const grid = PuzzleGrid(rows: 3, columns: 4);
      // Give the tray back the 40 dp the status bar took and 12 pieces
      // clear the target again. Worth knowing before anyone reads "12 is
      // impossible" as a property of the grid (§4, K-1).
      final layout = TrayLayoutCalculator.calculate(
        traySize: const Size(360, 296),
        pieceCount: 12,
        boardPieceSize: _pieceSizeOf(grid),
      );
      expect(layout.meetsTouchTarget, isTrue);
      expect(layout.itemSize.width, closeTo(73, 1));
    });
  });

  group('choosing between fitting layouts', () {
    test('picks the candidate closest to the preferred scale', () {
      // Candidates here are ~90px (1 row), ~154px (2 rows) and ~99px
      // (3 rows) against a 200px board piece, i.e. scales .45, .77, .49.
      final layout = TrayLayoutCalculator.calculate(
        traySize: const Size(600, 320),
        pieceCount: 6,
        boardPieceSize: const Size(200, 200),
      );
      expect(layout.rows, 2);
      expect(layout.columns, 3);
      expect(layout.itemSize.width, closeTo(154, 1));
    });

    test('the touch target beats the preferred scale', () {
      // One row would sit closer to 0.70 but falls under 64 px.
      final layout = TrayLayoutCalculator.calculate(
        traySize: const Size(300, 300),
        pieceCount: 4,
        boardPieceSize: const Size(100, 100),
      );
      expect(layout.meetsTouchTarget, isTrue);
      expect(layout.itemSize.width, greaterThanOrEqualTo(64));
    });

    test('same input, same layout', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      final a = TrayLayoutCalculator.calculate(
        traySize: _tray,
        pieceCount: 9,
        boardPieceSize: _pieceSizeOf(grid),
      );
      final b = TrayLayoutCalculator.calculate(
        traySize: _tray,
        pieceCount: 9,
        boardPieceSize: _pieceSizeOf(grid),
      );
      expect(a.rows, b.rows);
      expect(a.columns, b.columns);
      expect(a.itemSize, b.itemSize);
    });
  });

  group('slot geometry', () {
    test('slots are row-major, inside the tray, and never overlap', () {
      const grid = PuzzleGrid(rows: 3, columns: 3);
      final layout = TrayLayoutCalculator.calculate(
        traySize: _tray,
        pieceCount: 9,
        boardPieceSize: _pieceSizeOf(grid),
      );

      final rects = [
        for (var slot = 0; slot < 9; slot++) layout.slotRect(slot),
      ];

      for (final rect in rects) {
        expect(rect.left, greaterThanOrEqualTo(-0.01));
        expect(rect.top, greaterThanOrEqualTo(-0.01));
        expect(rect.right, lessThanOrEqualTo(_tray.width + 0.01));
        expect(rect.bottom, lessThanOrEqualTo(_tray.height + 0.01));
      }

      // Row-major: slot 1 is right of slot 0, slot 3 is below it.
      expect(rects[1].left, greaterThan(rects[0].left));
      expect(rects[1].top, closeTo(rects[0].top, 0.01));
      expect(rects[3].top, greaterThan(rects[0].top));

      for (var a = 0; a < rects.length; a++) {
        for (var b = a + 1; b < rects.length; b++) {
          expect(
            rects[a].overlaps(rects[b]),
            isFalse,
            reason: 'slot $a overlaps slot $b',
          );
        }
      }
    });

    test('asserts on an out-of-range slot', () {
      const grid = PuzzleGrid(rows: 2, columns: 2);
      final layout = TrayLayoutCalculator.calculate(
        traySize: _tray,
        pieceCount: 4,
        boardPieceSize: _pieceSizeOf(grid),
      );
      expect(
        () => layout.slotRect(layout.slotCount),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
