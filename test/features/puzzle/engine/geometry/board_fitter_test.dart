import 'dart:math' as math;
import 'dart:ui' show Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/board_fitter.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/tray_layout_calculator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/tray_shelf.dart';

/// The five stages of a game (K-15): 2×2, 2×3, 3×3, 4×3, 4×4.
const _stages = [
  PuzzleGrid(rows: 2, columns: 2),
  PuzzleGrid(rows: 2, columns: 3),
  PuzzleGrid(rows: 3, columns: 3),
  PuzzleGrid(rows: 4, columns: 3),
  PuzzleGrid(rows: 4, columns: 4),
];

const _screens = <String, Size>{
  'small phone': Size(320, 568),
  'reference phone': Size(360, 640),
  'reference phone, system bars taken': Size(360, 592),
  'normal phone': Size(414, 896),
  'tablet': Size(768, 1024),
  'big tablet': Size(1024, 1366),
  'phone, turned sideways': Size(640, 360),
  'tablet, turned sideways': Size(1024, 768),
};

double _preferred(Size area) => math.min(
      math.min(
        area.width - 2 * PuzzleConfig.boardMargin,
        area.height * PuzzleConfig.boardHeightFactor,
      ),
      PuzzleConfig.maxBoardSize,
    );

bool _fitsAt(
  Size area,
  PuzzleGrid grid,
  double edge, {
  required bool shelf,
}) =>
    TrayLayoutCalculator.tryCalculate(
      traySize: Size(area.width, area.height - edge),
      pieceCount: grid.pieceCount,
      boardPieceSize: CoordinateMapper.pieceSizeOf(
        CoordinateMapper.cellSizeOf(grid, Size(edge, edge)),
      ),
      requireShelf: shelf,
    ) !=
    null;

void main() {
  for (final screen in _screens.entries) {
    for (final grid in _stages) {
      final name = '${screen.key}, ${grid.rows}x${grid.columns}';

      test('$name: every piece stays big enough to hit (§2, K-15)', () {
        final fit = BoardFitter.fit(area: screen.value, grid: grid);
        final preferred = _preferred(screen.value);

        expect(fit.tray.meetsTouchTarget, isTrue);
        expect(
          fit.tray.slotCount,
          greaterThanOrEqualTo(grid.pieceCount),
          reason: 'the tray does not scroll: every piece has a slot (§16)',
        );
        expect(fit.boardEdge, lessThanOrEqualTo(preferred));
        // A board that had to shrink stops while a slot is still
        // finger-sized. A board at its usual size is not held to that: on a
        // sideways phone a 4×4 slot is 54 px, and always was.
        if (fit.boardEdge < preferred) {
          expect(
            fit.boardEdge / math.max(grid.rows, grid.columns),
            greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
            reason: 'a shrunken board keeps its slots finger-sized',
          );
        }
      });

      test('$name: the board shrinks only as far as it has to', () {
        final fit = BoardFitter.fit(area: screen.value, grid: grid);
        if (fit.boardEdge == _preferred(screen.value)) return;

        expect(
          _fitsAt(
            screen.value,
            grid,
            fit.boardEdge + PuzzleConfig.boardFitStep,
            shelf: false,
          ),
          isFalse,
          reason: 'one step bigger would not have fitted',
        );
      });

      test('$name: the tray is a shelf wherever one can fit (§16.1)', () {
        final fit = BoardFitter.fit(area: screen.value, grid: grid);
        if (!shelfPossible(screen.value, grid)) return;
        expect(fit.tray.columns, greaterThanOrEqualTo(fit.tray.rows));
      });
    }
  }

  test('on a 320 dp phone a 4×3 tray cannot be a shelf, at any board size', () {
    // Four of its pieces side by side are too short to touch (measured):
    // the touch target wins and the tray is laid out down (§2, §16.1).
    const small = Size(320, 568);
    const grid = PuzzleGrid(rows: 4, columns: 3);
    expect(shelfPossible(small, grid), isFalse);

    final fit = BoardFitter.fit(area: small, grid: grid);
    expect(fit.tray.meetsTouchTarget, isTrue);
    expect(fit.tray.rows, greaterThan(fit.tray.columns));

    expect(
      shelfPossible(const Size(360, 640), grid),
      isTrue,
      reason: 'a normal phone keeps the shelf',
    );
  });

  test('up to nine pieces, no board ever shrinks (§40 as it was)', () {
    for (final area in _screens.values) {
      for (final grid in _stages.take(3)) {
        expect(
          BoardFitter.fit(area: area, grid: grid).boardEdge,
          _preferred(area),
          reason: '$area ${grid.rows}x${grid.columns}',
        );
      }
    }
  });

  test('the small phone needs a smaller board for twelve and sixteen', () {
    const small = Size(320, 568);
    for (final grid in _stages.skip(3)) {
      final fit = BoardFitter.fit(area: small, grid: grid);
      expect(fit.boardEdge, lessThan(_preferred(small)));
      expect(fit.boardEdge, greaterThanOrEqualTo(270));
    }
  });
}
