import 'dart:io';
import 'dart:math' show Random;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_board_preview.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../../support/test_artwork.dart';

/// Faz 3 acceptance: the pieces must assemble into the original picture
/// with no visible seam between them.
///
/// "No seam" is measured, not eyeballed: the assembled board is rendered to
/// a bitmap and every interior pixel must be fully opaque. A hairline gap
/// between two pieces shows up as a partially transparent pixel.

const _grid = PuzzleGrid(rows: 2, columns: 2);
const _board = Size(300, 300);
const _imageEdge = 512;

/// Ignore a 2px frame: the board's own outer edge is anti-aliased against
/// nothing, which is correct.
const _margin = 2;

/// Per-channel difference that still counts as "the same pixel".
const _channelTolerance = 24;

void main() {
  testWidgets('the assembled board has no transparent seams', (tester) async {
    late ui.Image source;
    await tester.runAsync(() async {
      source = await TestArtwork.create(size: _imageEdge);
    });

    final pieces = PuzzleGenerator(random: Random(3)).generate(_grid);
    final paths = PiecePaths.build(
      pieces: pieces,
      grid: _grid,
      boardSize: _board,
    );
    final boundaryKey = GlobalKey();

    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: RepaintBoundary(
            key: boundaryKey,
            child: PuzzleBoardPreview(
              image: source,
              pieces: pieces,
              grid: _grid,
              paths: paths,
              boardSize: _board,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    late ByteData rendered;
    late ByteData reference;
    late ByteData sourceBytes;
    await tester.runAsync(() async {
      sourceBytes = (await source.toByteData(
        format: ui.ImageByteFormat.rawRgba,
      ))!;
      final boundary = boundaryKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final board = await boundary.toImage();
      rendered = (await board.toByteData(format: ui.ImageByteFormat.rawRgba))!;
      reference = await _referenceBytes(source);

      // Leave the picture behind so the result can be looked at.
      final png = await board.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/preview_2x2.png').writeAsBytesSync(png!.buffer.asUint8List());
    });

    final width = _board.width.toInt();
    final height = _board.height.toInt();
    var translucent = 0;
    var mismatched = 0;
    var compared = 0;
    var worstAlpha = 255;
    final gaps = <Offset>[];

    for (var y = _margin; y < height - _margin; y++) {
      for (var x = _margin; x < width - _margin; x++) {
        final i = (y * width + x) * 4;
        final alpha = rendered.getUint8(i + 3);
        if (alpha < 255) {
          translucent++;
          worstAlpha = alpha < worstAlpha ? alpha : worstAlpha;
          if (gaps.length < 400) {
            gaps.add(Offset(x.toDouble(), y.toDouble()));
          }
        }

        var diff = 0;
        for (var channel = 0; channel < 3; channel++) {
          final d =
              (rendered.getUint8(i + channel) - reference.getUint8(i + channel))
                  .abs();
          if (d > diff) diff = d;
        }
        if (diff > _channelTolerance) mismatched++;
        compared++;
      }
    }

    // ignore: avoid_print
    print('seam check: $compared px, translucent=$translucent '
        '(worst alpha $worstAlpha), mismatched=$mismatched '
        '(${(100 * mismatched / compared).toStringAsFixed(2)}%)');
    if (gaps.isNotEmpty) {
      // Which piece should have covered each gap pixel? If no piece's exact
      // path contains it, the outlines really do leave a hole; if one does,
      // the hole is in the painting, not in the geometry.
      final exactPaths = {
        for (final piece in pieces)
          piece.id: paths.of(piece.id).shift(
                CoordinateMapper.pieceOriginOf(
                  normalizedPosition: piece.normalizedPosition,
                  grid: _grid,
                  boardSize: _board,
                ),
              ),
      };
      final paintedPaths = {
        for (final piece in pieces)
          piece.id: paths.of(piece.id).shift(
                CoordinateMapper.pieceOriginOf(
                  normalizedPosition: piece.normalizedPosition,
                  grid: _grid,
                  boardSize: _board,
                ),
              ),
      };
      final sourceScale = source.width / _board.width;

      for (final gap in gaps.take(8)) {
        final centre = gap + const Offset(0.5, 0.5);
        final i = (gap.dy.toInt() * width + gap.dx.toInt()) * 4;
        final sx = (centre.dx * sourceScale).toInt();
        final sy = (centre.dy * sourceScale).toInt();
        final sourceAlpha =
            sourceBytes.getUint8((sy * source.width + sx) * 4 + 3);
        // ignore: avoid_print
        print('gap $gap alpha=${rendered.getUint8(i + 3)} '
            'sourceAlpha=$sourceAlpha '
            'exact=${exactPaths.keys.where((id) => exactPaths[id]!.contains(centre)).toList()} '
            'painted=${paintedPaths.keys.where((id) => paintedPaths[id]!.contains(centre)).toList()}');
      }
    }

    // A real seam is not subtle. With the outline merely scaled about its
    // centre — which fails to push the knob's neck outward at all — this
    // same board measured 281 gap pixels with alpha down to 62, and this
    // assertion caught it. What survives is a handful of pixels 1–2 units
    // short of opaque where two anti-aliased coverages round down.
    expect(
      worstAlpha,
      greaterThanOrEqualTo(250),
      reason: 'alpha well below opaque = a hole the eye can see',
    );
    expect(
      translucent / compared,
      lessThan(0.001),
      reason: 'rounding artefacts are isolated; a seam is a continuous line',
    );
    expect(
      mismatched / compared,
      lessThan(0.02),
      reason: 'assembled board should match the original picture',
    );
  });

  testWidgets('draws one painter per piece', (tester) async {
    late ui.Image source;
    await tester.runAsync(() async {
      source = await TestArtwork.create(size: _imageEdge);
    });

    final pieces = PuzzleGenerator(random: Random(0)).generate(_grid);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PuzzleBoardPreview(
            image: source,
            pieces: pieces,
            grid: _grid,
            paths: PiecePaths.build(
              pieces: pieces,
              grid: _grid,
              boardSize: _board,
            ),
            boardSize: _board,
          ),
        ),
      ),
    );

    expect(find.byType(CustomPaint), findsNWidgets(_grid.pieceCount));
  });

  testWidgets('rejects a path cache built for another board size', (
    tester,
  ) async {
    late ui.Image source;
    await tester.runAsync(() async {
      source = await TestArtwork.create(size: _imageEdge);
    });

    final pieces = PuzzleGenerator(random: Random(0)).generate(_grid);
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: PuzzleBoardPreview(
            image: source,
            pieces: pieces,
            grid: _grid,
            paths: PiecePaths.build(
              pieces: pieces,
              grid: _grid,
              boardSize: const Size(200, 200),
            ),
            boardSize: _board,
          ),
        ),
      ),
    );

    expect(tester.takeException(), isA<AssertionError>());
  });
}

/// The same picture drawn straight into the board rectangle — what the
/// assembled pieces are supposed to look like.
Future<ByteData> _referenceBytes(ui.Image source) async {
  final recorder = ui.PictureRecorder();
  final canvas = ui.Canvas(recorder, Offset.zero & _board);
  canvas.drawImageRect(
    source,
    Rect.fromLTWH(0, 0, source.width.toDouble(), source.height.toDouble()),
    Offset.zero & _board,
    Paint()
      ..filterQuality = FilterQuality.medium
      ..isAntiAlias = true,
  );
  final picture = recorder.endRecording();
  final image = await picture.toImage(
    _board.width.toInt(),
    _board.height.toInt(),
  );
  picture.dispose();
  return (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
}
