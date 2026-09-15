import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data' show ByteData;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/paint_colours.dart';
import 'package:emoji_puzzle_kids/features/colouring/models/car_model.dart';
import 'package:emoji_puzzle_kids/features/colouring/providers/colouring_book.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/car_painter.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/colouring_layout.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/colouring_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';

import '../../support/recording_sound_player.dart';

const _phone = Size(360, 640);

/// Points on the sedan, in design units.
const _sedanBody = Offset(50, 50);
const _sedanRearWheel = Offset(25, 66);
const _sedanFrontWheel = Offset(75, 66);
const _paper = Offset(2, 2);

/// A frame's worth of time: an animation only counts as done once its
/// duration has been passed, not merely reached.
const _frame = Duration(milliseconds: 20);

class _Harness {
  _Harness(this.book, this.player, this.finished, this.layout);

  final ColouringBook book;
  final RecordingSoundPlayer player;
  final int Function() finished;

  /// The overlay fills the whole test screen, so this is its layout.
  final ColouringLayout layout;
}

final _captureKey = GlobalKey();

Future<_Harness> _pump(
  WidgetTester tester, {
  Size screen = _phone,
  Future<void> Function(ColouringBook book)? prepare,
  bool finishesCar = false,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final player = RecordingSoundPlayer();
  final audio = AudioService(player: player);
  addTearDown(audio.dispose);
  final book = ColouringBook();
  addTearDown(book.dispose);
  await prepare?.call(book);

  var finished = 0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: RepaintBoundary(
        key: _captureKey,
        child: Stack(
          children: [
            Positioned.fill(
              child: ColoredBox(color: AppPalette.light.background),
            ),
            ColouringOverlay(
              book: book,
              audio: audio,
              haptics: null,
              finishesCar: finishesCar,
              onFinished: () => finished++,
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  return _Harness(book, player, () => finished, ColouringLayout.of(screen));
}

final _card = find.byKey(const ValueKey('colouring-card'));
final _skip = find.byKey(const ValueKey('colouring-skip'));
final _hues = find.byKey(const ValueKey('colouring-hues'));
final _greys = find.byKey(const ValueKey('colouring-greys'));
final _marker = find.byKey(const ValueKey('colouring-marker'));
final _preview = find.byKey(const ValueKey('colouring-preview'));

/// The colour filling the square in the corner right now.
Color _previewColour(WidgetTester tester) =>
    (tester.widget<Container>(_preview).decoration! as BoxDecoration).color!;

Future<void> _tapDesign(WidgetTester tester, Offset design) async {
  final card = tester.getRect(_card);
  await tester.tapAt(
    card.topLeft + design * (card.width / CarModel.designSize.width),
  );
  await tester.pump();
}

/// The colour inside the marker right now.
Color _markerColour(WidgetTester tester) {
  final inner = tester.widget<DecoratedBox>(
    find.descendant(of: _marker, matching: find.byType(DecoratedBox)).last,
  );
  return (inner.decoration as BoxDecoration).color!;
}

CarPainter _painter(WidgetTester tester) => tester
    .widget<CustomPaint>(
      find.descendant(of: _card, matching: find.byType(CustomPaint)),
    )
    .painter! as CarPainter;

/// Lets the paint settle: the first tick happens in the frame that starts
/// the animation, so it gets its own pump.
Future<void> _settle(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(PuzzleConfig.colouringSettleDuration);
  await tester.pump(_frame);
}

Future<ByteData> _screenshot(WidgetTester tester) async {
  late ByteData bytes;
  await tester.runAsync(() async {
    final boundary = _captureKey.currentContext!.findRenderObject()!
        as RenderRepaintBoundary;
    final image = await boundary.toImage();
    bytes = (await image.toByteData(format: ui.ImageByteFormat.rawRgba))!;
  });
  return bytes;
}

void main() {
  testWidgets('a car, a palette and a way past, all big enough (§2, K-9)', (
    tester,
  ) async {
    final harness = await _pump(tester);

    expect(_card, findsOneWidget);
    expect(_painter(tester).model.id, harness.book.car.id);
    for (final finder in [_skip, _hues, _greys]) {
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize));
      expect(
        size.height,
        greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('a colour is ready from the start, and the marker shows it', (
    tester,
  ) async {
    final harness = await _pump(tester);

    expect(_markerColour(tester), PaletteChoice.initial.colour);
    expect(
      tester.getCenter(_marker),
      harness.layout.pointOf(PaletteChoice.initial),
      reason: 'the choice is shown by a ring in place, not by colour alone',
    );
  });

  testWidgets(
      'the square in the top-left corner shows the chosen colour '
      '(K-10)', (tester) async {
    final harness = await _pump(tester);
    final layout = harness.layout;

    final corner = tester.getRect(_preview);
    expect(corner, layout.preview);
    expect(corner.center.dx, lessThan(_phone.width / 2), reason: 'left');
    expect(corner.center.dy, lessThan(_phone.height / 2), reason: 'top');
    expect(_previewColour(tester), PaletteChoice.initial.colour);

    // It follows a finger sliding along the palette, frame by frame.
    final hues = layout.hues;
    final gesture = await tester.startGesture(
      Offset(hues.left + 20, hues.center.dy),
    );
    await tester.pump();
    for (final fraction in const [0.3, 0.55, 0.8]) {
      final point = Offset(hues.left + hues.width * fraction, hues.center.dy);
      await gesture.moveTo(point);
      await tester.pump();
      expect(
        _previewColour(tester),
        layout.choiceIn(PaletteStrip.hues, point).colour,
        reason: 'at $fraction along the palette',
      );
      expect(_previewColour(tester), _markerColour(tester));
    }
    await gesture.up();
    await tester.pump();

    await tester.tapAt(Offset(layout.greys.center.dx, layout.greys.top + 2));
    await tester.pump();
    expect(
      _previewColour(tester).computeLuminance(),
      greaterThan(0.95),
      reason: 'white shows too: the square has a frame',
    );

    // And what it shows on screen is that colour, not merely told so.
    final shot = await _screenshot(tester);
    final centre = corner.center;
    final i =
        (centre.dy.floor() * _phone.width.toInt() + centre.dx.floor()) * 4;
    final chosen = _previewColour(tester);
    expect(shot.getUint8(i), (chosen.r * 255).round());
    expect(shot.getUint8(i + 1), (chosen.g * 255).round());
    expect(shot.getUint8(i + 2), (chosen.b * 255).round());
  });

  testWidgets('the corner square does not get in the way of a finger', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tapAt(harness.layout.preview.center);
    await tester.pump(const Duration(seconds: 2));

    expect(harness.finished(), 0);
    expect(harness.book.fills, isEmpty);
    expect(_previewColour(tester), PaletteChoice.initial.colour);
  });

  testWidgets('touching the palette chooses the colour under the finger', (
    tester,
  ) async {
    final harness = await _pump(tester);
    final layout = harness.layout;

    final point = Offset(
      layout.hues.left + layout.hues.width * 0.3,
      layout.hues.top + layout.hues.height * 0.7,
    );
    await tester.tapAt(point);
    await tester.pump();

    final expected = layout.choiceIn(PaletteStrip.hues, point);
    expect(_markerColour(tester), expected.colour);
    expect(tester.getCenter(_marker), layout.pointOf(expected));

    final greyPoint = Offset(layout.greys.center.dx, layout.greys.bottom - 2);
    await tester.tapAt(greyPoint);
    await tester.pump();
    expect(
      _markerColour(tester).computeLuminance(),
      lessThan(0.01),
      reason: 'the bottom of the grey strip is black, for tyres',
    );
  });

  testWidgets(
      'sliding a finger across the palette changes the colour as it '
      'goes', (tester) async {
    final harness = await _pump(tester);
    final hues = harness.layout.hues;

    final start = Offset(hues.left + 12, hues.center.dy);
    final gesture = await tester.startGesture(start);
    await tester.pump();
    final first = _markerColour(tester);

    final end = Offset(hues.right - 12, hues.center.dy);
    await gesture.moveTo(Offset(hues.center.dx, hues.center.dy));
    await tester.pump();
    final middle = _markerColour(tester);
    await gesture.moveTo(end);
    await tester.pump();
    await gesture.up();
    await tester.pump();

    expect(middle, isNot(first));
    expect(
      _markerColour(tester),
      harness.layout.choiceIn(PaletteStrip.hues, end).colour,
    );

    // A finger that runs off the edge keeps the colour at the edge.
    final off = await tester.startGesture(end);
    await off.moveTo(Offset(hues.right + 30, hues.center.dy));
    await tester.pump();
    await off.up();
    expect(
      _markerColour(tester),
      harness.layout
          .choiceIn(PaletteStrip.hues, Offset(hues.right, hues.center.dy))
          .colour,
    );
  });

  testWidgets('the palette shows exactly the colour it paints (K-9)', (
    tester,
  ) async {
    final harness = await _pump(tester);
    final layout = harness.layout;
    final shot = await _screenshot(tester);
    final width = _phone.width.toInt();

    Color pixelAt(Offset point) {
      final i = (point.dy.floor() * width + point.dx.floor()) * 4;
      return Color.fromARGB(
        255,
        shot.getUint8(i),
        shot.getUint8(i + 1),
        shot.getUint8(i + 2),
      );
    }

    var worst = 0;
    var samples = 0;
    for (final strip in PaletteStrip.values) {
      final rect = strip == PaletteStrip.hues ? layout.hues : layout.greys;
      // Stay clear of the rounded corners and of where the marker sits.
      for (var fy = 0.15; fy <= 0.85; fy += 0.1) {
        for (var fx = 0.12; fx <= 0.88; fx += 0.08) {
          final point = Offset(
            (rect.left + rect.width * fx).floorToDouble() + 0.5,
            (rect.top + rect.height * fy).floorToDouble() + 0.5,
          );
          if ((point - layout.pointOf(PaletteChoice.initial)).distance <
              PuzzleConfig.colouringMarkerSize) {
            continue;
          }
          final drawn = pixelAt(point);
          final chosen = layout.choiceIn(strip, point).colour;
          for (final (a, b) in [
            (drawn.r, chosen.r),
            (drawn.g, chosen.g),
            (drawn.b, chosen.b),
          ]) {
            worst = math.max(worst, ((a - b).abs() * 255).round());
          }
          samples++;
        }
      }
    }

    // ignore: avoid_print
    print('palette: $samples samples, worst channel difference $worst');
    expect(samples, greaterThan(50));
    expect(
      worst,
      lessThanOrEqualTo(6),
      reason: 'the child paints the colour they saw',
    );
  });

  testWidgets('a tapped part takes the chosen colour, then it moves on', (
    tester,
  ) async {
    final harness = await _pump(tester);
    final layout = harness.layout;

    final point = Offset(
      layout.hues.left + layout.hues.width * 0.1,
      layout.hues.center.dy,
    );
    await tester.tapAt(point);
    await tester.pump();
    final chosen = layout.choiceIn(PaletteStrip.hues, point).colour;

    await _tapDesign(tester, _sedanBody);

    expect(harness.book.colourOf('body'), chosen.toARGB32());
    expect(harness.player.played, [Sfx.pieceSnap]);
    expect(harness.finished(), 0, reason: 'the child sees the paint first');

    await tester.pump(PuzzleConfig.colouringFillDuration);
    expect(_painter(tester).fills['body'], chosen.toARGB32());
    expect(_painter(tester).freshProgress, 1);

    await _settle(tester);
    expect(harness.finished(), 1);
  });

  testWidgets('the wheel on top gets the paint, not the body under it', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await _tapDesign(tester, _sedanRearWheel);

    expect(harness.book.fills.keys, ['rear-wheel']);
    await _settle(tester);
  });

  testWidgets('one part per finished puzzle (§24.2)', (tester) async {
    final harness = await _pump(tester);

    await _tapDesign(tester, _sedanBody);
    await tester.tapAt(harness.layout.greys.center);
    await _tapDesign(tester, _sedanFrontWheel);

    expect(
      harness.book.fills,
      {'body': PaletteChoice.initial.colour.toARGB32()},
    );
    expect(harness.player.played, [Sfx.pieceSnap]);
    await _settle(tester);
    expect(harness.finished(), 1);
  });

  testWidgets('paper, and the space around the card, paint nothing (§20)', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await _tapDesign(tester, _paper);
    await tester.tapAt(const Offset(4, 80));
    await tester.pump(const Duration(seconds: 5));

    expect(harness.book.fills, isEmpty);
    expect(harness.player.played, isEmpty);
    expect(harness.finished(), 0, reason: 'it waits for the child');
  });

  testWidgets('the arrow skips at once and paints nothing (§23, K-6)', (
    tester,
  ) async {
    final harness = await _pump(tester);

    await tester.tap(_skip);
    await tester.pump();

    expect(harness.finished(), 1);
    expect(harness.book.fills, isEmpty);
    expect(harness.player.played, isEmpty);

    await tester.tap(_skip, warnIfMissed: false);
    await tester.pump(const Duration(seconds: 3));
    expect(harness.finished(), 1, reason: 'it hands back exactly once');
  });

  testWidgets(
      'on a car\'s last stage it drives off after its paint, white parts '
      'and all (K-15)', (tester) async {
    final harness = await _pump(
      tester,
      finishesCar: true,
      prepare: (book) => book.paint('body', 0xFF43A047),
    );
    final car = harness.book.car.id;

    await _tapDesign(tester, _sedanFrontWheel);
    await _settle(tester);

    expect(harness.player.played, [Sfx.pieceSnap, Sfx.puzzleComplete]);
    expect(harness.finished(), 0, reason: 'the car leaves first');

    await tester.pump(PuzzleConfig.colouringDriveOffDuration * 0.5);
    final shift = tester
        .widget<Transform>(
          find.descendant(of: _card, matching: find.byType(Transform)),
        )
        .transform
        .getTranslation()
        .x;
    expect(shift, greaterThan(0), reason: 'driving away to the right');

    await tester.pump(PuzzleConfig.colouringDriveOffDuration * 0.5);
    await tester.pump(_frame);

    expect(harness.finished(), 1);
    expect(harness.book.fills, hasLength(2), reason: 'three parts stay white');
    expect(
      harness.book.car.id,
      car,
      reason: 'moving on to the next car is the game\'s business',
    );
  });

  testWidgets('a painted part is locked: tapping it paints nothing (K-15)', (
    tester,
  ) async {
    final harness = await _pump(
      tester,
      prepare: (book) => book.paint('body', 0xFF1E88E5),
    );
    await tester.tapAt(harness.layout.greys.center);
    await tester.pump();

    await _tapDesign(tester, _sedanBody);
    await tester.pump(const Duration(seconds: 2));

    expect(harness.book.colourOf('body'), 0xFF1E88E5, reason: 'unchanged');
    expect(harness.player.played, isEmpty);
    expect(harness.finished(), 0, reason: 'it waits for a white part');

    await _tapDesign(tester, _sedanRearWheel);
    expect(harness.book.fills.keys, containsAll(['body', 'rear-wheel']));
    await _settle(tester);
    expect(harness.finished(), 1);
  });

  testWidgets('sideways, it still fits and still paints (§40)', (
    tester,
  ) async {
    const sideways = Size(640, 360);
    final harness = await _pump(tester, screen: sideways);
    final hues = harness.layout.hues;
    expect(
      tester.getRect(_preview).topLeft,
      const Offset(16, 16),
      reason: 'the corner square stays in the corner when turned (K-10)',
    );

    final point = Offset(hues.center.dx, hues.top + hues.height * 0.4);
    await tester.tapAt(point);
    await tester.pump();
    await _tapDesign(tester, _sedanBody);

    expect(
      harness.book.colourOf('body'),
      harness.layout.choiceIn(PaletteStrip.hues, point).colour.toARGB32(),
    );
    expect(tester.takeException(), isNull);
    await _settle(tester);
  });

  testWidgets('the palette and the arrow say what they are (§31)', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await _pump(tester);

    expect(find.bySemanticsLabel('Renk paleti'), findsOneWidget);
    expect(find.bySemanticsLabel('Gri tonları'), findsOneWidget);
    expect(find.bySemanticsLabel('Seçilen renk'), findsOneWidget);
    expect(find.bySemanticsLabel('Geç'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('it leaves a picture of a car half painted', (tester) async {
    final harness = await _pump(
      tester,
      prepare: (book) async {
        await book.paint('body', 0xFF1E88E5);
        await book.paint('rear-window', 0xFFFDD835);
        await book.paint('front-wheel', 0xFF212121);
      },
    );
    final hues = harness.layout.hues;
    await tester.tapAt(Offset(hues.left + hues.width * 0.3, hues.center.dy));
    await tester.pump();

    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/colouring.png').writeAsBytesSync(png!.buffer.asUint8List());
    });
    expect(File('build/colouring.png').existsSync(), isTrue);
  });
}
