import 'dart:math' as math;

import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// WCAG relative luminance.
double _luminance(Color colour) {
  double linear(double channel) => channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
  return 0.2126 * linear(colour.r) +
      0.7152 * linear(colour.g) +
      0.0722 * linear(colour.b);
}

double _contrast(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  test('the dark ground is the first navy, a quarter of the way to white', () {
    const navy = Color(0xFF14213D);
    const white = Color(0xFFFFFFFF);
    final dark = AppPalette.dark.background;

    for (final (name, actual, from, to) in [
      ('red', dark.r, navy.r, white.r),
      ('green', dark.g, navy.g, white.g),
      ('blue', dark.b, navy.b, white.b),
    ]) {
      expect(
        actual * 255,
        closeTo((from + (to - from) * 0.25) * 255, 1),
        reason: name,
      );
    }
  });

  test('the grown-ups can read their corner in both themes', () {
    for (final (name, palette) in [
      ('light', AppPalette.light),
      ('dark', AppPalette.dark),
    ]) {
      // WCAG AA for small text.
      expect(
        _contrast(palette.onBackgroundMuted, palette.background),
        greaterThanOrEqualTo(4.5),
        reason: '$name: muted text',
      );
      expect(
        _contrast(palette.onSubtleSurface, palette.background),
        greaterThanOrEqualTo(4.5),
        reason: '$name: secondary buttons',
      );
      expect(
        _contrast(palette.onButton, palette.button),
        greaterThanOrEqualTo(4.5),
        reason: '$name: round buttons',
      );
      // WCAG 1.4.11: a frame that marks state needs 3:1 against its ground.
      expect(
        _contrast(palette.selectionBorder, palette.background),
        greaterThanOrEqualTo(3),
        reason: '$name: selection frame',
      );
    }
  });

  test('each theme carries its own palette', () {
    expect(AppTheme.light.extension<AppPalette>(), AppPalette.light);
    expect(AppTheme.dark.extension<AppPalette>(), AppPalette.dark);
    expect(AppTheme.light.scaffoldBackgroundColor, AppPalette.light.background);
    expect(AppTheme.dark.scaffoldBackgroundColor, AppPalette.dark.background);
  });
}
