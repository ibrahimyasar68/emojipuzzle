import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter/painting.dart';

import '../../../core/constants/puzzle_config.dart';

/// Paletin iki şeridi: bütün tonlar, ve beyazdan siyaha griler (K-9).
enum PaletteStrip { hues, greys }

/// Çocuğun paletten seçtiği renk: hangi şerit ve şeridin neresi (§24.2, K-9).
///
/// Konum ekrandan bağımsızdır: [hue] tonun çember üzerindeki yeri, [shade]
/// açıktan koyuya yeri, ikisi de `[0, 1]`. Ekranın hangi yönde durduğu
/// yerleşimin işidir.
@immutable
class PaletteChoice {
  const PaletteChoice.hue({required this.hue, required this.shade})
      : strip = PaletteStrip.hues;

  const PaletteChoice.grey({required this.shade})
      : strip = PaletteStrip.greys,
        hue = 0;

  /// Açılışta seçili olan: tam doygun mavi. Tek dokunuş boyamaya yeter.
  static const PaletteChoice initial = PaletteChoice.hue(
    hue: 2 / 3,
    shade: PaintColours.pureShade,
  );

  final PaletteStrip strip;

  /// Tonun çember üzerindeki yeri; 0 ve 1 ikisi de kırmızı.
  final double hue;

  /// 0 en açık, 1 en koyu.
  final double shade;

  /// Bu noktanın rengi — palette çizilen rengin tam kendisi.
  Color get colour => switch (strip) {
        PaletteStrip.hues => HSLColor.fromAHSL(
            1,
            (hue * 360).clamp(0.0, 359.999),
            1,
            PaintColours.lightnessOf(shade),
          ).toColor(),
        PaletteStrip.greys => HSLColor.fromAHSL(1, 0, 0, 1 - shade).toColor(),
      };

  @override
  bool operator ==(Object other) =>
      other is PaletteChoice &&
      other.strip == strip &&
      other.hue == hue &&
      other.shade == shade;

  @override
  int get hashCode => Object.hash(strip, hue, shade);

  @override
  String toString() => 'PaletteChoice(${strip.name}, hue $hue, shade $shade)';
}

/// Boyama ekranının sabit renkleri ve paletin nasıl çizildiği (§24.2).
///
/// Temaya göre değişmez: araba beyaz bir kâğıdın üstündedir.
///
/// Palet iki katmanla çizilir: bir yönde tam doygun tonlar, üstünde öbür
/// yönde beyazdan saydama, saydamdan siyaha bir perde. Tam doygun bir HSL
/// renginde açıklık, rengin beyazla ya da siyahla doğrusal karışımıdır; bu
/// yüzden çizilen her piksel [PaletteChoice.colour] ile aynıdır — çocuk
/// gördüğü rengi boyar. Ölçülerek denetlenir
/// (`colouring_overlay_test.dart`).
abstract final class PaintColours {
  /// Boyanmamış parçanın rengi: kâğıdın kendisi.
  static const Color paper = Color(0xFFFFFFFF);

  /// Çizgilerin rengi.
  static const Color ink = Color(0xFF1B1B1B);

  /// Açıklığın tam 0,5 olduğu, yani rengin saf olduğu yer.
  static const double pureShade = (PuzzleConfig.colouringLightestShade - 0.5) /
      (PuzzleConfig.colouringLightestShade -
          PuzzleConfig.colouringDarkestShade);

  /// [shade] noktasındaki HSL açıklığı.
  static double lightnessOf(double shade) =>
      PuzzleConfig.colouringLightestShade +
      (PuzzleConfig.colouringDarkestShade -
              PuzzleConfig.colouringLightestShade) *
          shade.clamp(0.0, 1.0);

  /// Çember boyunca yedi durak, kırmızıdan kırmızıya. Aralarındaki doğrusal
  /// geçiş, tam doygun tonların kendisidir.
  static final List<Color> hueSweep = [
    for (var i = 0; i <= 6; i++)
      HSLColor.fromAHSL(1, (i * 60 % 360).toDouble(), 1, 0.5).toColor(),
  ];

  /// Tonların üstündeki perde: [begin] ucunda en açık, [end] ucunda en koyu.
  static LinearGradient shadeVeil({
    required Alignment begin,
    required Alignment end,
  }) {
    const white = Color(0xFFFFFFFF);
    const black = Color(0xFF000000);
    return LinearGradient(
      begin: begin,
      end: end,
      colors: [
        white.withValues(alpha: PuzzleConfig.colouringLightestShade * 2 - 1),
        white.withValues(alpha: 0),
        black.withValues(alpha: 0),
        black.withValues(alpha: 1 - PuzzleConfig.colouringDarkestShade * 2),
      ],
      stops: const [0, pureShade, pureShade, 1],
    );
  }

  /// Gri şerit: üstte beyaz, altta siyah.
  static const LinearGradient greys = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFF000000)],
  );
}
