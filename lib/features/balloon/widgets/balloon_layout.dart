import 'dart:math' as math;
import 'dart:ui' show Offset, Rect, Size;

import '../../../core/constants/puzzle_config.dart';
import '../models/balloon.dart';

/// Bir balonun belirli bir anda piksel olarak nerede olduğu (§24).
///
/// Saf fonksiyonlar; widget'ın dışında tutulur ki 72 px kuralı ve yukarı
/// süzülme doğrudan denetlenebilsin.
abstract final class BalloonLayout {
  /// Bir balon her zaman en az [PuzzleConfig.balloonTouchTargetSize]
  /// genişliğindedir (§2) ve ekranla birlikte büyür; böylece tablette de
  /// kolay vurulur.
  static double diameterFor(Size playArea) => math.max(
        PuzzleConfig.balloonTouchTargetSize,
        playArea.shortestSide * 0.18,
      );

  /// Bir balonun kapladığı kare, boyut çeşitliliği dahil.
  ///
  /// [elapsed], oyunun açılmasından bu yana geçen süredir; balon kendi
  /// yerinin biraz altından durma yüksekliğine süzülür, sonra yerinde
  /// salınır.
  /// Bu balonun tam olarak ne kadar büyük olduğu.
  ///
  /// Alt sınır, boyut çeşitliliğinden önce değil sonra uygulanır:
  /// komşularından %10 küçük bir balon da üç yaşındaki birinin vurabilmesi
  /// gereken bir balondur (§2).
  ///
  /// Widget'lar en ve boyu [rectOf] yerine buradan alır, çünkü bir
  /// dikdörtgenin genişliği sağ kenarından sol kenarının çıkarılmasıdır ve
  /// bu ikisi her zaman tam 72 vermez.
  static double diameterOf(Balloon balloon, Size playArea) => math.max(
        PuzzleConfig.balloonTouchTargetSize,
        diameterFor(playArea) * balloon.sizeFactor,
      );

  static Rect rectOf(Balloon balloon, Size playArea, Duration elapsed) {
    final diameter = diameterOf(balloon, playArea);
    final age = elapsed - balloon.bornAt;

    final rise =
        (age.inMilliseconds / PuzzleConfig.balloonRiseDuration.inMilliseconds)
            .clamp(0.0, 1.0);
    // Yaklaşırken yavaşlar; suda yüzen bir şeyin yaptığı gibi.
    final eased = 1 - math.pow(1 - rise, 3).toDouble();

    final restTop = balloon.restY * math.max(0, playArea.height - diameter);
    final top =
        restTop + diameter * PuzzleConfig.balloonRiseDistance * (1 - eased);

    final bob = rise < 1
        ? 0.0
        : math.sin(
              (age.inMilliseconds /
                          PuzzleConfig.balloonBobPeriod.inMilliseconds +
                      balloon.bobPhase) *
                  2 *
                  math.pi,
            ) *
            PuzzleConfig.balloonBobAmplitude;

    final left = balloon.x * math.max(0, playArea.width - diameter);
    return Rect.fromLTWH(left, top + bob, diameter, diameter);
  }

  /// Bir balonun ne kadar belirgin olduğu: süzülürken yavaşça belirir,
  /// böylece birden ortaya çıkmaz, gelir.
  static double opacityOf(Balloon balloon, Duration elapsed) {
    final age = elapsed - balloon.bornAt;
    return (age.inMilliseconds /
            (PuzzleConfig.balloonRiseDuration.inMilliseconds * 0.6))
        .clamp(0.0, 1.0);
  }

  /// Balonun ortası: patlaması buradan çıkar.
  static Offset centreOf(Balloon balloon, Size playArea, Duration elapsed) =>
      rectOf(balloon, playArea, elapsed).center;
}
