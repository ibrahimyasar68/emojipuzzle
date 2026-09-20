import 'dart:math' show Random, max;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/services/puzzle_image_loader.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_palette.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/path/piece_paths.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_category.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

/// A finished board must look like the picture on its gradient, right up
/// to the edges of the pieces — not just be free of holes (§14).
///
/// The seam check in `puzzle_board_preview_test.dart` only proves there is
/// no transparent gap, and it uses opaque test artwork with no gradient. The
/// real boards are a transparent emoji over a gradient, and there the pieces
/// used to paint the gradient and the picture as two separately
/// anti-aliased layers: where a neighbour's bleed stroke only partly covered
/// a pixel, the gradient showed through the picture by up to c·(1−c) = 25%.
/// No hole, but a light line along every piece border — 64 units on the
/// lion's black outline, 75 at worst.
///
/// So this compares every pixel near a border against the same picture
/// drawn straight onto the same gradient — with the piece's bevel turned
/// off, since that is light on the surface, not the picture (K-19).

const _board = Size(344, 344);

/// The finest grid these pictures were checked at before K-15.
const _grid = PuzzleGrid(rows: 3, columns: 3);

/// A pixel within this many pixels of another piece counts as "border".
const _band = 2;

/// Stay clear of the board's own outer edge, which is anti-aliased against
/// the screen behind it, as it should be.
const _frame = 3;

void main() {
  for (final puzzleId in ['lion_01', 'car_01']) {
    testWidgets('piece borders keep the picture\'s tone, $puzzleId', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final puzzle = PuzzleCatalog.v1.byId(puzzleId);
      final loader = PuzzleImageLoader();
      addTearDown(loader.evictAll);
      late ui.Image image;
      await tester.runAsync(() async {
        image = await loader.load(puzzle.imagePath);
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
              child: PuzzleBoard(
                image: image,
                grid: _grid,
                paths: paths,
                placedPieces: pieces,
                boardSize: _board,
                backgroundCategory: puzzle.category,
                // The surface light of K-19 is deliberately off here: this
                // test is about how a piece composes the gradient and the
                // picture (§14), and the bevel would darken and lighten
                // exactly the band it measures. The bevel has its own test.
                bevelled: false,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      late ByteData rendered;
      late ByteData reference;
      await tester.runAsync(() async {
        final boundary = boundaryKey.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final board = await boundary.toImage();
        rendered =
            (await board.toByteData(format: ui.ImageByteFormat.rawRgba))!;
        reference = await _referenceBytes(image, puzzle.category);
      });

      // Which piece's exact outline each pixel centre falls in.
      final width = _board.width.toInt();
      final owner = List<int>.filled(width * width, -1);
      final outlines = {
        for (final piece in pieces)
          piece.id: paths.of(piece.id).shift(
                CoordinateMapper.pieceOriginOf(
                  normalizedPosition: piece.normalizedPosition,
                  grid: _grid,
                  boardSize: _board,
                ),
              ),
      };
      for (var y = 0; y < width; y++) {
        for (var x = 0; x < width; x++) {
          final centre = Offset(x + 0.5, y + 0.5);
          for (final entry in outlines.entries) {
            if (entry.value.contains(centre)) {
              owner[y * width + x] = entry.key;
              break;
            }
          }
        }
      }

      bool nearAnotherPiece(int x, int y) {
        final own = owner[y * width + x];
        for (var dy = -_band; dy <= _band; dy++) {
          for (var dx = -_band; dx <= _band; dx++) {
            if (owner[(y + dy) * width + x + dx] != own) return true;
          }
        }
        return false;
      }

      var borderPixels = 0;
      var total = 0;
      var worst = 0;
      for (var y = _frame; y < width - _frame; y++) {
        for (var x = _frame; x < width - _frame; x++) {
          if (!nearAnotherPiece(x, y)) continue;
          final i = (y * width + x) * 4;
          var diff = 0;
          for (var channel = 0; channel < 3; channel++) {
            diff = max(
              diff,
              (rendered.getUint8(i + channel) - reference.getUint8(i + channel))
                  .abs(),
            );
          }
          borderPixels++;
          total += diff;
          worst = max(worst, diff);
        }
      }

      final mean = total / borderPixels;
      // ignore: avoid_print
      print('border tone $puzzleId: $borderPixels px, '
          'mean ${mean.toStringAsFixed(2)}, worst $worst');

      // Measured after the fix: worst 2, mean under 0.5 — the same as the
      // interior, i.e. filtering and rounding. Before it: worst 64–75,
      // mean 2.7–4.9.
      expect(worst, lessThanOrEqualTo(8), reason: 'a visible line');
      expect(mean, lessThan(1), reason: 'a faint line all the way round');
    });
  }
}

/// The picture drawn straight onto the board's gradient — what the
/// assembled pieces are supposed to look like.
Future<ByteData> _referenceBytes(
  ui.Image image,
  PuzzleCategory category,
) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder, Offset.zero & _board);
  final (from, to) = PuzzlePalette.gradientOf(category);
  canvas
    ..drawRect(
      Offset.zero & _board,
      Paint()
        ..shader = ui.Gradient.linear(
          Offset.zero,
          _board.bottomRight(Offset.zero),
          [from, to],
        ),
    )
    ..drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      Offset.zero & _board,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true,
    );
  final picture = recorder.endRecording();
  final bitmap = await picture.toImage(
    _board.width.toInt(),
    _board.height.toInt(),
  );
  picture.dispose();
  return (await bitmap.toByteData(format: ui.ImageByteFormat.rawRgba))!;
}
