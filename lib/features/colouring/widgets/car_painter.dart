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
class CarPainter extends CustomPainter {
  const CarPainter({
    required this.model,
    required this.fills,
    this.freshPart,
    this.freshFrom,
    this.freshProgress = 1,
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

  @override
  void paint(Canvas canvas, Size size) {
    canvas
      ..save()
      ..scale(size.width / CarModel.designSize.width);

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = PuzzleConfig.colouringOutlineWidth
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round
      ..color = PaintColours.ink
      ..isAntiAlias = true;

    for (final part in model.parts) {
      canvas
        ..drawPath(part.path, Paint()..color = _colourOf(part))
        ..drawPath(part.path, outline);
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
      oldDelegate.freshProgress != freshProgress;
}
