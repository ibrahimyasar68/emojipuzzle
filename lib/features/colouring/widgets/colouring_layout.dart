import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import '../../../core/constants/puzzle_config.dart';
import '../data/paint_colours.dart';
import '../models/car_model.dart';

/// Boyama ekranında her şeyin nerede durduğu, ve palette dokunulan bir
/// noktanın hangi renk olduğu (§24.2, §40, K-9).
///
/// Saf hesap; widget'ın dışında tutulur ki "palet 64 px'in üstünde",
/// "hiçbir şey üst üste binmez" ve "işaret dokunulan noktada durur" ekransız
/// denetlenebilsin.
///
/// Her iki yönde de sol üst köşede seçilen rengin karesi durur (K-10).
///
/// Dikey ekranda: üstte solda renk karesi, sağda geç düğmesi, ortada araba
/// kartı, altta palet (tonlar enine, açıklık boyuna) ve sağında gri şerit.
/// Yatay ekranda: solda üstte renk karesi, altında geç düğmesi, ortada kart,
/// sağda palet sütunu (tonlar boyuna, açıklık enine) ve sağında gri şerit. Kart kalan yerin tamamını alır —
/// kartın her birimi, bir parçanın dokunma alanıdır (K-8).
class ColouringLayout {
  const ColouringLayout._({
    required this.card,
    required this.hues,
    required this.greys,
    required this.skip,
    required this.preview,
    required this.huesAlongWidth,
  });

  factory ColouringLayout.of(Size area) {
    const margin = PuzzleConfig.colouringMargin;
    const gap = PuzzleConfig.colouringGap;
    const button = PuzzleConfig.colouringSkipButtonSize;
    const inset = PuzzleConfig.colouringCardInset;
    final aspect = CarModel.designSize.width / CarModel.designSize.height;

    final portrait = area.height >= area.width;
    final preview = Rect.fromLTWH(
      margin,
      margin,
      PuzzleConfig.colouringPreviewSize,
      PuzzleConfig.colouringPreviewSize,
    );
    late final Rect skip;
    late final Rect palette;
    late final Rect cardSpace;

    if (portrait) {
      skip =
          Rect.fromLTWH(area.width - margin - button, margin, button, button);
      palette = Rect.fromLTWH(
        margin,
        area.height - margin - PuzzleConfig.colouringPaletteHeight,
        area.width - 2 * margin,
        PuzzleConfig.colouringPaletteHeight,
      );
      cardSpace = Rect.fromLTRB(
        inset,
        math.max(skip.bottom, preview.bottom) + gap,
        area.width - inset,
        palette.top - gap,
      );
    } else {
      skip = Rect.fromLTWH(margin, preview.bottom + gap, button, button);
      palette = Rect.fromLTWH(
        area.width - margin - PuzzleConfig.colouringPaletteColumnWidth,
        margin,
        PuzzleConfig.colouringPaletteColumnWidth,
        area.height - 2 * margin,
      );
      cardSpace = Rect.fromLTRB(
        math.max(skip.right, preview.right) + gap,
        inset,
        palette.left - gap,
        area.height - inset,
      );
    }

    final greys = Rect.fromLTRB(
      palette.right - PuzzleConfig.colouringGreyStripWidth,
      palette.top,
      palette.right,
      palette.bottom,
    );
    final hues = Rect.fromLTRB(
      palette.left,
      palette.top,
      greys.left - gap,
      palette.bottom,
    );

    final cardWidth = math.max(
      0.0,
      math.min(
        PuzzleConfig.colouringMaxCardWidth,
        math.min(cardSpace.width, cardSpace.height * aspect),
      ),
    );
    final card = Rect.fromCenter(
      center: cardSpace.center,
      width: cardWidth,
      height: cardWidth / aspect,
    );

    return ColouringLayout._(
      card: card,
      hues: hues,
      greys: greys,
      skip: skip,
      preview: preview,
      huesAlongWidth: portrait,
    );
  }

  /// Arabanın çizildiği beyaz kart.
  final Rect card;

  /// Bütün tonların şeridi.
  final Rect hues;

  /// Beyazdan siyaha gri şerit; her zaman üstte beyaz.
  final Rect greys;

  /// "Geç" düğmesi.
  final Rect skip;

  /// Seçilen rengin karesi, sol üst köşede (K-10).
  final Rect preview;

  /// Tonlar şeridin uzun kenarı boyunca dizilir: dikey ekranda enine, yatay
  /// ekranda boyuna. Açıklık öbür yönde, açıktan koyuya.
  final bool huesAlongWidth;

  /// Bir çizim biriminin kaç piksel olduğu.
  double get scale => card.width / CarModel.designSize.width;

  /// [strip] şeridinde [point] noktasının seçimi. Şeridin dışındaki bir
  /// nokta en yakın kenara kıstırılır: parmak sürüklenirken şeritten taşsa
  /// da seçim şeritte kalır.
  PaletteChoice choiceIn(PaletteStrip strip, Offset point) {
    final rect = strip == PaletteStrip.hues ? hues : greys;
    final across = ((point.dx - rect.left) / rect.width).clamp(0.0, 1.0);
    final down = ((point.dy - rect.top) / rect.height).clamp(0.0, 1.0);
    return switch (strip) {
      PaletteStrip.hues => PaletteChoice.hue(
          hue: huesAlongWidth ? across : down,
          shade: huesAlongWidth ? down : across,
        ),
      PaletteStrip.greys => PaletteChoice.grey(shade: down),
    };
  }

  /// [choice] seçiminin ekrandaki yeri; işaret burada durur.
  Offset pointOf(PaletteChoice choice) {
    switch (choice.strip) {
      case PaletteStrip.hues:
        final across = huesAlongWidth ? choice.hue : choice.shade;
        final down = huesAlongWidth ? choice.shade : choice.hue;
        return Offset(
          hues.left + across * hues.width,
          hues.top + down * hues.height,
        );
      case PaletteStrip.greys:
        return Offset(greys.center.dx, greys.top + choice.shade * greys.height);
    }
  }
}
