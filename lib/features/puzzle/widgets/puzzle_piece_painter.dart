import 'dart:typed_data' show Float64List;
import 'dart:ui' as ui;

import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../engine/geometry/piece_image_mapper.dart';

/// Tek bir parçayı çizer: konturuna kırp, sonra paylaşılan puzzle
/// görselinden kendi dilimini bas (§14).
///
/// Pahalı olan her şey önceden hesaplanır: path önbellekten, dikdörtgenler
/// [PieceImageMapper]'dan gelir; `paint` yalnızca kırpar ve çizer.
class PuzzlePiecePainter extends CustomPainter {
  const PuzzlePiecePainter({
    required this.image,
    required this.renderPath,
    required this.rects,
    this.background,
    this.elevation = 0,
    this.bleed = PuzzleConfig.renderBleedPixels,
    this.shadowColour,
  }) : assert(
          elevation == 0 || shadowColour != null,
          'a lifted piece takes its shadow colour from the theme',
        );

  /// Puzzle başına bir kez çözülür ve bütün parçalarca paylaşılır (§14).
  final ui.Image image;

  /// Parçanın konturu, parça-yerel koordinatlarda.
  final Path renderPath;

  final PieceDrawRects rects;

  /// Konturun içine, resmin altına boyanır.
  ///
  /// Görseller tasarım gereği şeffaftır (§34) ve şeffaf bir parça, çocuğun
  /// tepside ne görebildiği ne de nişan alabildiği bir parçadır. Null
  /// verilirse parça boyanmaz; zaten opak olan görseller için.
  final PieceBackground? background;

  /// §17 — sürüklenen parça board'dan kalkar ve gölge düşürür.
  final double elevation;

  /// §14 — parçanın kendi konturunun ne kadar dışına boyandığı.
  ///
  /// İki komşu bir sınırı paylaşır ve yarı örtülü iki yumuşatılmış kenar
  /// bir araya gelip opak bir kenar etmez: bu olmadan aralarında görünür
  /// bir kıl çizgi kalır. Parça önce bir kıl payı büyük, sonra üstüne
  /// gerçek boyutunda çizilir; böylece örtüşme bulanık bir kenar değil,
  /// gerçek resimdir.
  ///
  /// Bu iş eskiden konturun kendisini büyüterek yapılıyordu. Artık burada
  /// yapılıyor, çünkü bu eğrileri boolean path işlemleriyle genişletmek
  /// çalışmıyor — bkz. `PiecePaths`.
  final double bleed;

  /// §17 — kalkan parçanın gölgesi; zemine göre temadan gelir. Yalnızca
  /// [elevation] sıfırdan büyükse gerekir.
  final Color? shadowColour;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = shadowColour;
    if (elevation > 0 && shadow != null) {
      canvas.drawShadow(renderPath, shadow, elevation, false);
    }

    final surface = background;
    if (surface != null) {
      // Gradyan board'un tamamı boyunca uzanır; böylece komşu parçalar
      // yamalı bohça oluşturmak yerine birbirini sürdürür.
      _draw(
        canvas,
        ui.Gradient.linear(
          surface.boardRect.topLeft,
          surface.boardRect.bottomRight,
          [surface.from, surface.to],
        ),
      );
    }
    _draw(canvas, _imageShader());
  }

  /// Konturu [shader] ile doldurur, sonra aynı shader'ı kontur boyunca
  /// çizgi olarak geçirir.
  ///
  /// Bu çizgi taşmadır (§14): `bleed * 2` kalınlığındaki çizginin yarısı
  /// path'in dışında kalır ve boyalı kenarı her yerde tam [bleed] kadar
  /// dışarı iter — sınırın kendi üstüne katlandığı tırnak boynu dahil.
  /// Bunun yerine *path*'i büyütmek bu eğrilerde ayakta kalmıyor — bkz.
  /// `PiecePaths`.
  void _draw(Canvas canvas, ui.Shader shader) {
    canvas.drawPath(
      renderPath,
      Paint()
        ..shader = shader
        ..isAntiAlias = true,
    );
    if (bleed <= 0) return;
    canvas.drawPath(
      renderPath,
      Paint()
        ..shader = shader
        ..isAntiAlias = true
        ..style = PaintingStyle.stroke
        ..strokeWidth = bleed * 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Paylaşılan puzzle görseli; [PieceDrawRects.src], parça-yerel
  /// koordinatlarda [PieceDrawRects.dst] üzerine düşecek şekilde
  /// yerleştirilir — `drawImageRect`'in yapacağı eşlemenin aynısı, ama
  /// shader olarak, böylece doldurmanın yanında çizgi de çekebilir.
  ui.ImageShader _imageShader() {
    final src = rects.src;
    final dst = rects.dst;
    final scaleX = dst.width / src.width;
    final scaleY = dst.height / src.height;

    return ui.ImageShader(
      image,
      TileMode.clamp,
      TileMode.clamp,
      Float64List.fromList(<double>[
        scaleX, 0, 0, 0, //
        0, scaleY, 0, 0, //
        0, 0, 1, 0, //
        dst.left - src.left * scaleX, dst.top - src.top * scaleY, 0, 1,
      ]),
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  bool shouldRepaint(PuzzlePiecePainter oldDelegate) =>
      !identical(oldDelegate.image, image) ||
      !identical(oldDelegate.renderPath, renderPath) ||
      oldDelegate.rects != rects ||
      oldDelegate.background != background ||
      oldDelegate.elevation != elevation ||
      oldDelegate.bleed != bleed;
}
