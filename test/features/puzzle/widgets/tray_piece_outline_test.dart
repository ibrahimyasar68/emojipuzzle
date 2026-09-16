import 'dart:math' show Random;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/piece_image_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_board.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_piece_painter.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_tray.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// A light piece on a light gradient is almost the colour of the screen
/// behind the tray; the child could not make it out (user request). Tray
/// and hand pieces carry a thin line in the colour opposite the background.
/// Pieces on the board do not: there they must join into one picture.

Future<GameProvider> _started(WidgetTester tester) async {
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  await tester.runAsync(
    () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
  );
  return game;
}

Future<void> _pumpScreen(
  WidgetTester tester,
  GameProvider game,
  ThemeData theme,
) async {
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: theme,
        home: const PuzzleScreen(),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Iterable<PuzzlePiecePainter> _paintersIn(WidgetTester tester, Type owner) {
  return tester
      .widgetList<CustomPaint>(
        find.descendant(
          of: find.byType(owner),
          matching: find.byType(CustomPaint),
        ),
      )
      .map((paint) => paint.painter)
      .whereType<PuzzlePiecePainter>();
}

/// The on-screen scale of a tray piece: its slot over its painted size.
double _trayScale(WidgetTester tester, int pieceId) {
  final slot = tester.getSize(find.byKey(ValueKey('tray-piece-$pieceId')));
  final painted = tester
      .widget<CustomPaint>(
        find.descendant(
          of: find.byKey(ValueKey('tray-piece-$pieceId')),
          matching: find.byType(CustomPaint),
        ),
      )
      .size;
  return slot.width / painted.width;
}

void main() {
  for (final (name, theme, palette) in [
    ('light', AppTheme.light, AppPalette.light),
    ('dark', AppTheme.dark, AppPalette.dark),
  ]) {
    testWidgets('$name theme: tray pieces are outlined, board pieces are not',
        (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final game = await _started(tester);
      addTearDown(game.dispose);
      game.markPlaced(game.pieces.first.id);
      await _pumpScreen(tester, game, theme);

      final tray = _paintersIn(tester, PuzzleTray).toList();
      expect(tray, hasLength(game.pieces.length - 1));
      for (final painter in tray) {
        expect(painter.outlineColour, palette.pieceOutline);
      }
      for (final piece in game.pieces.skip(1)) {
        final painter = tester
            .widget<CustomPaint>(
              find.descendant(
                of: find.byKey(ValueKey('tray-piece-${piece.id}')),
                matching: find.byType(CustomPaint),
              ),
            )
            .painter! as PuzzlePiecePainter;
        expect(
          painter.outlineWidth * _trayScale(tester, piece.id),
          moreOrLessEquals(PuzzleConfig.pieceOutlineWidth),
          reason: 'the line is the same width on screen at any tray scale',
        );
      }

      final board = _paintersIn(tester, PuzzleBoard).toList();
      expect(board, hasLength(1));
      expect(board.single.outlineWidth, 0);
      expect(board.single.outlineColour, isNull);
    });
  }

  test('the outline stands out against the background in both themes', () {
    for (final palette in [AppPalette.light, AppPalette.dark]) {
      final line = palette.pieceOutline;
      final behind = palette.background;
      final shown = Color.alphaBlend(line, behind);
      final lighter = [
        shown.computeLuminance(),
        behind.computeLuminance(),
      ]..sort();
      final contrast = (lighter[1] + 0.05) / (lighter[0] + 0.05);
      // §31 — a graphical object needs 3:1 against what is next to it.
      expect(contrast, greaterThanOrEqualTo(3), reason: '$palette');
    }
  });

  testWidgets('a piece in the hand keeps its outline', (tester) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = await _started(tester);
    addTearDown(game.dispose);
    await _pumpScreen(tester, game, AppTheme.light);

    final piece = game.pieces.first;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-piece-${piece.id}'))),
    );
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump(const Duration(milliseconds: 200));

    final held = tester
        .widget<CustomPaint>(
          find.descendant(
            of: find.byKey(ValueKey('drag-piece-${piece.id}')),
            matching: find.byType(CustomPaint),
          ),
        )
        .painter! as PuzzlePiecePainter;
    expect(held.outlineColour, AppPalette.light.pieceOutline);
    expect(held.outlineWidth, PuzzleConfig.pieceOutlineWidth);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the line is actually drawn along the piece edge', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(200, 200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    // A white picture: the case the user saw, a piece as light as the
    // screen behind it.
    late ui.Image white;
    await tester.runAsync(() async {
      final recorder = ui.PictureRecorder();
      Canvas(recorder).drawRect(
        const Rect.fromLTWH(0, 0, 100, 100),
        Paint()..color = const Color(0xFFFFFFFF),
      );
      white = await recorder.endRecording().toImage(100, 100);
    });
    addTearDown(white.dispose);

    final path = Path()..addOval(const Rect.fromLTWH(40, 40, 120, 120));
    const PieceDrawRects rects = (
      src: Rect.fromLTWH(0, 0, 100, 100),
      dst: Rect.fromLTWH(0, 0, 200, 200),
    );

    Future<ByteData> render({required bool outlined}) async {
      final key = GlobalKey();
      await tester.pumpWidget(
        Center(
          child: RepaintBoundary(
            key: key,
            // Opaque and as light as the piece, like the tray behind it; a
            // transparent backdrop would leave the plain edge half-covered
            // and already dark in the premultiplied bytes.
            child: ColoredBox(
                color: const Color(0xFFFFFFFF),
                child: CustomPaint(
                  size: const Size(200, 200),
                  painter: PuzzlePiecePainter(
                    image: white,
                    renderPath: path,
                    rects: rects,
                    outlineColour:
                        outlined ? AppPalette.light.pieceOutline : null,
                    outlineWidth: outlined ? PuzzleConfig.pieceOutlineWidth : 0,
                  ),
                )),
          ),
        ),
      );
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

    final plain = await render(outlined: false);
    final outlined = await render(outlined: true);

    int red(ByteData bytes, int x, int y) => bytes.getUint8((y * 200 + x) * 4);

    // The darkest pixel around a point: a 1.5 px line lands on one pixel or
    // straddles two, so the pixel a rounded coordinate names may be its
    // neighbour.
    int darkest(ByteData bytes, Offset at) {
      var result = 255;
      for (var dy = -1; dy <= 1; dy++) {
        for (var dx = -1; dx <= 1; dx++) {
          final value = red(bytes, at.dx.floor() + dx, at.dy.floor() + dy);
          if (value < result) result = value;
        }
      }
      return result;
    }

    // Without the line the edge vanishes into the backdrop; with it every
    // stretch of edge is clearly darker. The middle is untouched.
    final metric = path.computeMetrics().single;
    var darker = 0;
    const samples = 72;
    for (var i = 0; i < samples; i++) {
      final at = metric.getTangentForOffset(metric.length * i / samples)!;
      if (darkest(plain, at.position) - darkest(outlined, at.position) >= 60) {
        darker++;
      }
    }
    expect(darker, samples, reason: 'edge pixels darkened by the line');
    expect(red(outlined, 100, 100), red(plain, 100, 100));
  });
}
