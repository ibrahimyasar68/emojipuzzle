import 'dart:math' show Random;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/services/puzzle_image_loader.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/piece_image_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_piece.dart';
import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_board.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_piece_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

/// K-19 — a finished puzzle should look like a puzzle: pieces with
/// thickness, not a printed picture (the user asked for exactly this). Each
/// piece carries light inside its top-left edge and shadow inside its
/// bottom-right one, so the seams read even when the picture is whole.
///
/// Every threshold here was measured on the render, not guessed. Two things
/// the measurements caught while this was written:
///
/// * the light and the shadow must be offset by a whole stroke width, or
///   they overlap at the edge and the darker one wins — every edge, top
///   included, came out shaded;
/// * the offsets are the opposite way round to the intuition: the light is
///   shifted *into* the piece from the top-left, because the clip keeps
///   only what falls inside the outline.
///
/// On light artwork the shadow does most of the work (−0.16 at the seam)
/// and the light is slight (+0.015): white over an almost white picture
/// cannot do more. That is why the thresholds differ.

const _board = Size(300, 300);
const _grid = PuzzleGrid(rows: 2, columns: 2);
const _puzzleId = 'lion_01';

/// Columns that cross the horizontal seam on a straight stretch, away from
/// the knob in the middle of the edge.
const _columns = [30, 100];

late ui.Image _image;
late List<PuzzlePiece> _pieces;
late PiecePaths _paths;

Future<ByteData> _render(WidgetTester tester, {required bool bevelled}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Center(
        child: RepaintBoundary(
          key: key,
          child: PuzzleBoard(
            image: _image,
            grid: _grid,
            paths: _paths,
            placedPieces: _pieces,
            boardSize: _board,
            backgroundCategory: PuzzleCatalog.v1.byId(_puzzleId).category,
            bevelled: bevelled,
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  late ByteData bytes;
  await tester.runAsync(() async {
    final boundary =
        key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
    final board = await boundary.toImage();
    bytes = (await board.toByteData())!;
    board.dispose();
  });
  return bytes;
}

double _luminance(ByteData bytes, int x, int y) {
  final i = (y * _board.width.toInt() + x) * 4;
  return Color.fromARGB(
    255,
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  ).computeLuminance();
}

/// Where the two rows of pieces meet.
int get _seamY => CoordinateMapper.cellSizeOf(_grid, _board).height.round();

void main() {
  late ByteData flat;
  late ByteData bevelled;

  setUpAll(() {
    _pieces = PuzzleGenerator(random: Random(3)).generate(_grid);
    _paths = PiecePaths.build(
      pieces: _pieces,
      grid: _grid,
      boardSize: _board,
    );
  });

  testWidgets('the board is rendered both ways', (tester) async {
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);
    await tester.runAsync(() async {
      _image = await loader.load(PuzzleCatalog.v1.byId(_puzzleId).imagePath);
    });

    flat = await _render(tester, bevelled: false);
    bevelled = await _render(tester, bevelled: true);

    // The bevel is a rim, not a wash: the middle of a piece is the picture
    // and nothing else.
    for (final point in [const Offset(75, 75), const Offset(225, 75)]) {
      final x = point.dx.toInt();
      final y = point.dy.toInt();
      expect(
        _luminance(bevelled, x, y),
        closeTo(_luminance(flat, x, y), 0.005),
        reason: 'the middle of a piece at $point',
      );
    }
  });

  test('a piece falls into shadow along its bottom edge', () {
    for (final x in _columns) {
      var deepest = 0.0;
      for (var y = _seamY - 6; y < _seamY; y++) {
        final darker = _luminance(flat, x, y) - _luminance(bevelled, x, y);
        if (darker > deepest) deepest = darker;
      }
      expect(
        deepest,
        greaterThan(0.08),
        reason: 'the seam under the upper piece, at x $x',
      );
    }
  });

  test('a piece catches the light along its top edge', () {
    // The board's own top edge: a straight run of the upper pieces' top
    // outline, with nothing above it to confuse the measurement.
    for (final x in _columns) {
      var brightest = 0.0;
      for (var y = 1; y <= 4; y++) {
        final lighter = _luminance(bevelled, x, y) - _luminance(flat, x, y);
        if (lighter > brightest) brightest = lighter;
        expect(
          lighter,
          greaterThan(-0.01),
          reason: 'a lit edge must not be shaded, at x $x y $y',
        );
      }
      expect(
        brightest,
        greaterThan(0.005),
        reason: 'the top edge of the piece, at x $x',
      );
    }
  });

  testWidgets('the bevel stays inside the piece', (tester) async {
    // On the board a neighbour would cover any spill, so this renders one
    // piece alone on white. Without the clip the shadow stroke — offset up
    // and left — lands *outside* the outline and darkens whatever is
    // there: on the board, the piece next to it (§14).
    tester.view.physicalSize = const Size(400, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    // Its own copy of the picture: the board test's loader lets go of its
    // image when that test ends, and a disposed image cannot be drawn.
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);
    late ui.Image picture;
    await tester.runAsync(() async {
      picture = await loader.load(PuzzleCatalog.v1.byId(_puzzleId).imagePath);
    });

    final piece = _pieces.first;
    final size = CoordinateMapper.pieceSizeOf(
      CoordinateMapper.cellSizeOf(_grid, _board),
    );
    final path = _paths.of(piece.id);

    Future<ByteData> render({required bool bevelled}) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: RepaintBoundary(
              key: key,
              child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: SizedBox(
                  width: size.width,
                  height: size.height,
                  child: CustomPaint(
                    size: size,
                    painter: PuzzlePiecePainter(
                      image: picture,
                      renderPath: path,
                      rects: PieceImageMapper.rectsOf(
                        piece: piece,
                        grid: _grid,
                        boardSize: _board,
                        imageSize: Size(
                          picture.width.toDouble(),
                          picture.height.toDouble(),
                        ),
                      ),
                      bevelDepth: bevelled ? PuzzleConfig.pieceBevelDepth : 0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      late ByteData bytes;
      await tester.runAsync(() async {
        final boundary =
            key.currentContext!.findRenderObject()! as RenderRepaintBoundary;
        final image = await boundary.toImage();
        bytes = (await image.toByteData())!;
        image.dispose();
      });
      return bytes;
    }

    final plain = await render(bevelled: false);
    final withBevel = await render(bevelled: true);
    final width = size.width.round();

    Color pixel(ByteData bytes, int x, int y) {
      final i = (y * width + x) * 4;
      return Color.fromARGB(
        255,
        bytes.getUint8(i),
        bytes.getUint8(i + 1),
        bytes.getUint8(i + 2),
      );
    }

    // Walk down each column until the outline is reached, then look at the
    // pixels just above it — outside the piece.
    var checked = 0;
    for (var x = 10; x < width - 10; x += 7) {
      var edge = -1;
      for (var y = 0; y < size.height.round(); y++) {
        if (path.contains(Offset(x + 0.5, y + 0.5))) {
          edge = y;
          break;
        }
      }
      if (edge < 4) continue;
      for (var y = edge - 4; y < edge - 1; y++) {
        expect(
          pixel(withBevel, x, y),
          pixel(plain, x, y),
          reason: 'outside the outline at ($x, $y)',
        );
      }
      checked++;
    }
    expect(checked, greaterThan(5), reason: 'enough of the edge was looked at');
  });

  test('the finished picture shows its seams', () {
    for (final x in _columns) {
      double contrast(ByteData bytes) {
        var lowest = 1.0;
        var highest = 0.0;
        for (var y = _seamY - 6; y <= _seamY + 6; y++) {
          final value = _luminance(bytes, x, y);
          if (value < lowest) lowest = value;
          if (value > highest) highest = value;
        }
        return highest - lowest;
      }

      expect(
        contrast(bevelled),
        greaterThan(contrast(flat) + 0.05),
        reason: 'a seam the child can see in the whole picture, at x $x',
      );
    }
  });
}
