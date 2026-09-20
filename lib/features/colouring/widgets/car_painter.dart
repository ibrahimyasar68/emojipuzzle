import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/paint_colours.dart';
import '../models/car_model.dart';

/// Arabayı kâğıda çizer: her parça kendi rengiyle (ya da beyaz), üstüne siyah
/// çizgisi, en üstte boyanmayan süs çizgileri (§24.2).
///
/// Parçalar alttan üste çizildiği için üstteki parçanın dolgusu alttakinin
/// çizgisini örter; tekerin gövdeyi kesen çizgisi görünmez.
///
/// K-17 — parça düz boyanmaz: dolgunun üstüne, parçanın kendi sınırına
/// kırpılmış bir açıktan koyuya perde çekilir ve arabanın altına yere bir
/// gölge düşer. Perde dolgudan sonra, **çizgiden önce** gelir; yoksa siyah
/// çizgi de solar.
class CarPainter extends CustomPainter {
  const CarPainter({
    required this.model,
    required this.fills,
    this.freshPart,
    this.freshFrom,
    this.freshProgress = 1,
    this.shaded = true,
  });

  final CarModel model;

  /// Parça kimliği → opak ARGB rengi.
  final Map<String, int> fills;

  /// Az önce boyanan parça; rengi [freshFrom]'dan yeni rengine akar.
  final String? freshPart;

  /// Boyanmadan önceki rengi; null ise kâğıt.
  final int? freshFrom;

  /// `0` eski renk, `1` yeni renk.
  final double freshProgress;

  /// K-17 — hacim gölgesi ve yere düşen gölge. Kapatılabilir: kanıt
  /// görselleri ve testler düz hâliyle de ölçebilsin.
  final bool shaded;

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / CarModel.designSize.width);

    if (shaded) _drawGroundShadow(canvas);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = PuzzleConfig.colouringOutlineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = PaintColours.ink
      ..isAntiAlias = true;

    for (final part in model.parts) {
      canvas.drawPath(part.path, Paint()..color = _colourOf(part));
      if (shaded) _drawVolume(canvas, part);
      canvas.drawPath(part.path, outline);
    }

    final detail = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = PuzzleConfig.colouringDetailWidth
      ..strokeCap = StrokeCap.round
      ..color = PaintColours.ink
      ..isAntiAlias = true;
    for (final path in model.details) {
      canvas.drawPath(path, detail);
    }

    canvas.restore();
  }

  /// Parçanın içine, kendi sınırına kırpılmış açıktan koyuya perde.
  void _drawVolume(Canvas canvas, CarPart part) {
    final bounds = part.path.getBounds();
    canvas
      ..save()
      ..clipPath(part.path)
      ..drawRect(
        bounds,
        Paint()
          ..shader = ui.Gradient.linear(
            bounds.topCenter,
            bounds.bottomCenter,
            [
              const Color(0xFFFFFFFF)
                  .withAlpha(PuzzleConfig.colouringShadeHighlightAlpha),
              const Color(0x00FFFFFF),
              const Color(0xFF000000)
                  .withAlpha(PuzzleConfig.colouringShadeMidShadowAlpha),
              const Color(0xFF000000)
                  .withAlpha(PuzzleConfig.colouringShadeShadowAlpha),
            ],
            PuzzleConfig.colouringShadeStops,
          ),
      )
      ..restore();
  }

  /// Arabanın yere düşen gölgesi: parçaların hepsini kapsayan kutunun
  /// altında yatık bir elips. Modelden bağımsızdır, traktör de kamyon da
  /// kendi genişliğinde gölge bırakır.
  void _drawGroundShadow(Canvas canvas) {
    var bounds = model.parts.first.path.getBounds();
    for (final part in model.parts.skip(1)) {
      bounds = bounds.expandToInclude(part.path.getBounds());
    }
    final inset = PuzzleConfig.colouringGroundShadowInset;
    final height = PuzzleConfig.colouringGroundShadowHeight;
    canvas.drawOval(
      Rect.fromLTRB(
        bounds.left + inset,
        bounds.bottom - height / 2,
        bounds.right - inset,
        bounds.bottom + height / 2,
      ),
      Paint()
        ..color = const Color(0xFF000000)
            .withAlpha(PuzzleConfig.colouringGroundShadowAlpha)
        ..maskFilter = const ui.MaskFilter.blur(
          ui.BlurStyle.normal,
          PuzzleConfig.colouringGroundShadowBlur,
        ),
    );
  }

  Color _colourOf(CarPart part) {
    final target = _paintOf(fills[part.id]);
    if (part.id != freshPart) return target;
    return Color.lerp(_paintOf(freshFrom), target, freshProgress)!;
  }

  static Color _paintOf(int? argb) =>
      argb == null ? PaintColours.paper : Color(argb);

  @override
  bool shouldRepaint(CarPainter oldDelegate) =>
      !identical(oldDelegate.model, model) ||
      !mapEquals(oldDelegate.fills, fills) ||
      oldDelegate.freshPart != freshPart ||
      oldDelegate.freshFrom != freshFrom ||
      oldDelegate.freshProgress != freshProgress ||
      oldDelegate.shaded != shaded;
}
