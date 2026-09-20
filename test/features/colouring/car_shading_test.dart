import 'dart:typed_data' show ByteData;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/car_catalog.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/paint_colours.dart';
import 'package:emoji_puzzle_kids/features/colouring/models/car_model.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/car_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

/// K-17 — a flat fill reads as a sticker, not as a car. Each part carries a
/// light-to-dark veil inside its own outline and the car casts a shadow on
/// the ground, so the wheels look round and the car looks like it is
/// standing on something.
///
/// The child's colour must survive it: the veil is transparent in the middle
/// of the part, so the chosen colour is still on screen exactly as chosen.

const _card = Size(400, 320);
const _blue = 0xFF1E88E5;

final _sedan = CarCatalog.models.first;

/// Design units → card pixels.
Offset _at(double x, double y) => Offset(
      x * _card.width / CarModel.designSize.width,
      y * _card.width / CarModel.designSize.width,
    );

Future<ByteData> _render(WidgetTester tester, {required bool shaded}) async {
  final key = GlobalKey();
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Center(
        child: RepaintBoundary(
          key: key,
          child: ColoredBox(
            color: PaintColours.paper,
            child: SizedBox(
              width: _card.width,
              height: _card.height,
              child: CustomPaint(
                size: _card,
                painter: CarPainter(
                  model: _sedan,
                  fills: const {'body': _blue},
                  shaded: shaded,
                ),
              ),
            ),
          ),
        ),
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

Color _pixel(ByteData bytes, Offset at) {
  final i = (at.dy.floor() * _card.width.toInt() + at.dx.floor()) * 4;
  return Color.fromARGB(
    255,
    bytes.getUint8(i),
    bytes.getUint8(i + 1),
    bytes.getUint8(i + 2),
  );
}

void main() {
  setUp(() {
    // The card is drawn at its design size, one design unit to four pixels.
    expect(_card.width / CarModel.designSize.width, 4);
  });

  testWidgets('a painted part is lit at the top and shaded at the bottom', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final flat = await _render(tester, shaded: false);
    final shaded = await _render(tester, shaded: true);

    // The body runs from y 36 to 66 in design units. Keep clear of what is
    // drawn over it: the wheels (x 10–40 and 59–85) and the door line at
    // x 51. Measured on the render, not guessed — the first attempt sampled
    // the front wheel and read white.
    const x = 45.0;
    final top = _at(x, 39);
    final middle = _at(x, 47.5);
    final bottom = _at(x, 63);

    expect(
      _pixel(flat, top),
      _pixel(flat, bottom),
      reason: 'without the veil the part is one flat colour',
    );

    final lit = _pixel(shaded, top);
    final dim = _pixel(shaded, bottom);
    expect(
      lit.computeLuminance(),
      greaterThan(_pixel(flat, top).computeLuminance() + 0.05),
      reason: 'the top catches the light',
    );
    expect(
      dim.computeLuminance(),
      lessThan(_pixel(flat, bottom).computeLuminance() - 0.02),
      reason: 'the bottom falls into shadow',
    );

    // And the child's own colour is still on the car, untouched, where the
    // veil is transparent (K-9: what the palette shows is what is painted).
    expect(_pixel(shaded, middle), const Color(_blue));
  });

  testWidgets('the outline stays black over the shading', (tester) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final flat = await _render(tester, shaded: false);
    final shaded = await _render(tester, shaded: true);

    // A part's *top* edge is the one at risk: that is where its veil is
    // lightest, so a veil drawn over the line would wash it out. Measured,
    // not guessed: two earlier samples proved nothing — at a bottom edge
    // the veil is black over black, and the body's top edge at x 45 turned
    // out to be the rear window's bottom edge, where the veil is dark too.
    // This is the rear window's top edge, just inside the path (design
    // y 8.15): only the line's inner half is under the veil.
    final top = _at(41, 8.15);
    expect(
      _pixel(shaded, top).computeLuminance(),
      closeTo(_pixel(flat, top).computeLuminance(), 0.01),
      reason: 'the line keeps its ink: the veil goes under it',
    );
    expect(
      _pixel(flat, top).computeLuminance(),
      lessThan(0.05),
      reason: 'the sample really is on the line',
    );
  });

  testWidgets('the car casts a shadow on the ground, and only there', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(500, 400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    final flat = await _render(tester, shaded: false);
    final shaded = await _render(tester, shaded: true);

    // Just below the wheels, under the middle of the car.
    final ground = _at(50, 78.5);
    expect(
      _pixel(flat, ground),
      PaintColours.paper,
      reason: 'without it the paper is clean',
    );
    expect(
      _pixel(shaded, ground).computeLuminance(),
      lessThan(PaintColours.paper.computeLuminance() - 0.05),
      reason: 'the car stands on something',
    );

    // Well away from the car the paper stays paper. Both points are inside
    // the card: the card is 80 design units tall, so y 95 is off it.
    for (final away in [_at(50, 3), _at(1, 78.5)]) {
      expect(_pixel(shaded, away), PaintColours.paper, reason: '$away');
    }
  });

  test('the veil is transparent in the middle and gentle at the ends', () {
    // The stops must keep a band of the pure colour, or the child's choice
    // would never appear on the car exactly as it does in the palette.
    expect(PuzzleConfig.colouringShadeStops, hasLength(4));
    expect(PuzzleConfig.colouringShadeStops.first, 0);
    expect(PuzzleConfig.colouringShadeStops.last, 1);
    expect(
      PuzzleConfig.colouringShadeHighlightAlpha,
      lessThan(0x80),
      reason: 'a veil, not a repaint',
    );
    expect(PuzzleConfig.colouringShadeShadowAlpha, lessThan(0x80));
  });
}
