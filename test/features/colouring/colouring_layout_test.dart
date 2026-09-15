import 'dart:ui' show Offset, Rect, Size;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/paint_colours.dart';
import 'package:emoji_puzzle_kids/features/colouring/models/car_model.dart';
import 'package:emoji_puzzle_kids/features/colouring/widgets/colouring_layout.dart';
import 'package:flutter/painting.dart' show Color;
import 'package:flutter_test/flutter_test.dart';

/// The screens the rest of the game is tested on (§40), plus the smallest
/// sideways phone.
const colouringScreens = <String, Size>{
  'small phone': Size(320, 568),
  'reference phone': Size(360, 640),
  'normal phone': Size(414, 896),
  'tablet': Size(768, 1024),
  'big tablet': Size(1024, 1366),
  'phone, turned sideways': Size(640, 360),
  'small phone, turned sideways': Size(568, 320),
  'tablet, turned sideways': Size(1024, 768),
};

void main() {
  for (final screen in colouringScreens.entries) {
    test('${screen.key}: everything fits and nothing overlaps (§2, §40)', () {
      final layout = ColouringLayout.of(screen.value);
      final area = Offset.zero & screen.value;
      final everything = <String, Rect>{
        'card': layout.card,
        'skip': layout.skip,
        'preview': layout.preview,
        'hues': layout.hues,
        'greys': layout.greys,
      };

      for (final entry in everything.entries) {
        expect(
          area.intersect(entry.value),
          entry.value,
          reason: '${entry.key} is on screen',
        );
      }
      final names = everything.keys.toList();
      for (var a = 0; a < names.length; a++) {
        for (var b = a + 1; b < names.length; b++) {
          expect(
            everything[names[a]]!.overlaps(everything[names[b]]!),
            isFalse,
            reason: '${names[a]} and ${names[b]}',
          );
        }
      }

      for (final rect in [layout.skip, layout.hues, layout.greys]) {
        expect(
          rect.width,
          greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
        );
        expect(
          rect.height,
          greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
        );
      }

      // The chosen colour sits in the top-left corner, square (K-10).
      expect(layout.preview.topLeft, const Offset(16, 16));
      expect(layout.preview.width, layout.preview.height);
      expect(
        layout.preview.width,
        greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
        reason: 'big enough to see at a glance',
      );

      expect(
        layout.card.width / layout.card.height,
        closeTo(CarModel.designSize.width / CarModel.designSize.height, 1e-9),
      );
      expect(
        layout.card.width,
        lessThanOrEqualTo(PuzzleConfig.colouringMaxCardWidth),
      );
    });

    test('${screen.key}: the marker lands where the finger did (K-9)', () {
      final layout = ColouringLayout.of(screen.value);
      for (final strip in PaletteStrip.values) {
        final rect = strip == PaletteStrip.hues ? layout.hues : layout.greys;
        for (final fraction in const [
          Offset(0.1, 0.2),
          Offset(0.5, 0.5),
          Offset(0.9, 0.8),
        ]) {
          final point = Offset(
            rect.left + rect.width * fraction.dx,
            strip == PaletteStrip.greys
                ? rect.top + rect.height * fraction.dy
                : rect.top + rect.height * fraction.dy,
          );
          final back = layout.pointOf(layout.choiceIn(strip, point));
          expect(back.dy, closeTo(point.dy, 1e-9), reason: '$strip $fraction');
          if (strip == PaletteStrip.hues) {
            expect(back.dx, closeTo(point.dx, 1e-9));
          } else {
            expect(back.dx, rect.center.dx, reason: 'greys only go down');
          }
        }
      }
    });
  }

  test('hues run along the long side, light to dark across it', () {
    final phone = ColouringLayout.of(const Size(360, 640));
    final left = phone.choiceIn(
      PaletteStrip.hues,
      Offset(phone.hues.left + 10, phone.hues.center.dy),
    );
    final right = phone.choiceIn(
      PaletteStrip.hues,
      Offset(phone.hues.right - 10, phone.hues.center.dy),
    );
    expect(right.hue, greaterThan(left.hue));
    expect(right.shade, left.shade);

    final sideways = ColouringLayout.of(const Size(640, 360));
    final top = sideways.choiceIn(
      PaletteStrip.hues,
      Offset(sideways.hues.center.dx, sideways.hues.top + 10),
    );
    final bottom = sideways.choiceIn(
      PaletteStrip.hues,
      Offset(sideways.hues.center.dx, sideways.hues.bottom - 10),
    );
    expect(bottom.hue, greaterThan(top.hue));
    expect(bottom.shade, top.shade);
  });

  test('a finger that slides off the palette keeps choosing from its edge', () {
    final layout = ColouringLayout.of(const Size(360, 640));
    final choice = layout.choiceIn(
      PaletteStrip.hues,
      layout.hues.topLeft - const Offset(40, 40),
    );
    expect(choice, const PaletteChoice.hue(hue: 0, shade: 0));
  });

  group('the colours on the palette (K-9)', () {
    Color hue(double h) =>
        PaletteChoice.hue(hue: h, shade: PaintColours.pureShade).colour;

    test('full-strength hues around the wheel', () {
      expect(hue(0), const Color(0xFFFF0000));
      expect(hue(1 / 3), const Color(0xFF00FF00));
      expect(hue(2 / 3), const Color(0xFF0000FF));
      expect(hue(1), const Color(0xFFFF0000), reason: 'round again to red');
    });

    test('light at one end, dark at the other', () {
      final light = const PaletteChoice.hue(hue: 0, shade: 0).colour;
      final dark = const PaletteChoice.hue(hue: 0, shade: 1).colour;
      expect(light.computeLuminance(), greaterThan(0.8));
      expect(dark.computeLuminance(), lessThan(0.05));
    });

    test('the greys go all the way from white to black', () {
      expect(
        const PaletteChoice.grey(shade: 0).colour,
        const Color(0xFFFFFFFF),
      );
      expect(
        const PaletteChoice.grey(shade: 1).colour,
        const Color(0xFF000000),
      );
    });

    test('the colour ready at the start is a full-strength blue', () {
      expect(PaletteChoice.initial.colour, const Color(0xFF0000FF));
    });
  });

  test('the card grows into what the screen has to spare', () {
    final phone = ColouringLayout.of(const Size(360, 640));
    expect(phone.card.width, 360 - 2 * PuzzleConfig.colouringCardInset);

    final tablet = ColouringLayout.of(const Size(768, 1024));
    expect(tablet.card.width, PuzzleConfig.colouringMaxCardWidth);
  });
}
