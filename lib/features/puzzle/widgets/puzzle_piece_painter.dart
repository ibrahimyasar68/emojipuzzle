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
    this.outlineColour,
    this.outlineWidth = 0,
    this.bevelDepth = 0,
  })  : assert(
          elevation == 0 || shadowColour != null,
          'a lifted piece takes its shadow colour from the theme',
        ),
        assert(
          outlineWidth == 0 || outlineColour != null,
          'an outlined piece takes its outline colour from the theme',
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

  /// Parçanın kenar çizgisi; zeminden ayrılsın diye (tepsi, sürükleme).
  /// Board'daki parça çizgisizdir, yoksa dikişler görünürdü.
  final Color? outlineColour;

  /// K-19 — kabartma derinliği, parça-yerel birimde; sıfırsa parça düz
  /// boyanır. Parçayı ölçekleyen widget ekranda sabit derinlik için ölçeğe
  /// böler.
  ///
  /// Kabartma konturun **içine** çizilir: yumuşatılmış iki çizgi, biri sol
  /// üste kaydırılmış ışık, diğeri sağ alta kaydırılmış gölge. Parçanın
  /// dışına taşmaz, böylece komşusunun üstüne binmez.
  final double bevelDepth;

  /// Çizgi kalınlığı, **parça-yerel** birimde. Parçayı ölçekleyen widget
  /// ekranda sabit kalınlık için ölçeğe böler. Sıfırsa çizilmez.
  final double outlineWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final shadow = shadowColour;
    if (elevation > 0 && shadow != null) {
      canvas.drawShadow(renderPath, shadow, elevation, false);
    }

    // Parça önce kendi katmanında bütünüyle bestelenir, sonra tuvale tek
    // seferde basılır: şeklin yumuşatılmış kenar örtüsü yalnızca bir kez
    // uygulanır.
    //
    // Eskiden gradyan ve resim ayrı ayrı, her biri kendi yumuşatılmış
    // kenarıyla boyanıyordu. Komşunun taşma çizgisinin dış kenarında (örtü
    // c) önce gradyan c kadar, sonra resim c kadar biniyordu; gradyan opak
    // resmin altından c·(1−c) kadar — en çok %25 — görünüyordu. Parça
    // sınırları boyunca bir piksellik açık bir çizgi: aslanın siyah
    // konturunda 64 birim (ölçüldü, bkz. `piece_seam_tone_test.dart`).
    final bounds = renderPath.getBounds().inflate(bleed + 1);
    canvas.saveLayer(bounds, Paint());
    _drawCoverage(canvas);

    final image = _imageShader();
    final surface = background;
    if (surface != null) {
      // Gradyan board'un tamamı boyunca uzanır; böylece komşu parçalar
      // yamalı bohça oluşturmak yerine birbirini sürdürür.
      canvas
        ..drawRect(
          bounds,
          Paint()
            ..shader = ui.Gradient.linear(
              surface.boardRect.topLeft,
              surface.boardRect.bottomRight,
              [surface.from, surface.to],
            )
            ..blendMode = BlendMode.srcIn,
        )
        ..drawRect(
          bounds,
          Paint()
            ..shader = image
            ..blendMode = BlendMode.srcATop,
        );
    } else {
      canvas.drawRect(
        bounds,
        Paint()
          ..shader = image
          ..blendMode = BlendMode.srcIn,
      );
    }
    canvas.restore();

    if (bevelDepth > 0) _drawBevel(canvas);

    final outline = outlineColour;
    if (outline != null && outlineWidth > 0) {
      // Katmanın dışında, en üstte: resmin koyu konturu da açık gradyanı
      // da örtmeden kenarı izler.
      canvas.drawPath(
        renderPath,
        Paint()
          ..color = outline
          ..style = PaintingStyle.stroke
          ..strokeWidth = outlineWidth
          ..strokeJoin = StrokeJoin.round
          ..isAntiAlias = true,
      );
    }
  }

  /// K-19 — parçaya kalınlık hissi veren ışık ve gölge.
  ///
  /// Kırpma konturun kendisidir: çizginin yalnızca içeride kalan yarısı
  /// görünür, dışarıdaki yarısı komşunun alanına girmez.
  ///
  /// Kaydırma yönleri sezgiye terstir ve ölçülerek bulundu: ışık **sağ
  /// alta** kaydırılır, çünkü kırpıldıktan sonra yalnızca üst ve sol
  /// kenarların iç tarafında kalır; gölge sol üste kaydırılınca alt ve sağ
  /// kenarların içinde kalır. Ters yazılınca parçanın üst kenarı koyulaşıp
  /// alt kenarı açılıyordu — ışık yukarıdan gelmiyormuş gibi.
  void _drawBevel(Canvas canvas) {
    // Kaydırma çizgi kalınlığı kadardır, daha azı değil: ölçüldü, 0,35
    // kalınlıkta iki çizgi kenarda üst üste biniyor ve koyu olan kazanıyor
    // — üst kenar da gölgeli çıkıyordu. Bu kaydırmayla ışığın çizgisi tam
    // olarak konturun içine, gölgeninki dışına (kırpılacak yere) düşer.
    final blur = ui.MaskFilter.blur(ui.BlurStyle.normal, bevelDepth * 0.4);
    final offset = bevelDepth;
    canvas
      ..save()
      ..clipPath(renderPath)
      ..translate(offset, offset)
      ..drawPath(
        renderPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bevelDepth
          ..color = const Color(0xFFFFFFFF)
              .withAlpha(PuzzleConfig.pieceBevelLightAlpha)
          ..maskFilter = blur,
      )
      ..translate(-offset * 2, -offset * 2)
      ..drawPath(
        renderPath,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = bevelDepth
          ..color = const Color(0xFF000000)
              .withAlpha(PuzzleConfig.pieceBevelShadowAlpha)
          ..maskFilter = blur,
      )
      ..restore();
  }

  /// Parçanın örtüsünü katmana opak olarak basar: kontur dolgusu, üstüne
  /// kontur boyunca çizgi. Renk önemsizdir; ardından gelen boyamalar
  /// yalnızca buranın saydamlığını kullanır.
  ///
  /// Çizgi taşmadır (§14): `bleed * 2` kalınlığındaki çizginin yarısı
  /// path'in dışında kalır ve boyalı kenarı her yerde tam [bleed] kadar
  /// dışarı iter — sınırın kendi üstüne katlandığı tırnak boynu dahil.
  /// Bunun yerine *path*'i büyütmek bu eğrilerde ayakta kalmıyor — bkz.
  /// `PiecePaths`.
  void _drawCoverage(Canvas canvas) {
    final paint = Paint()
      ..color = const Color(0xFFFFFFFF)
      ..isAntiAlias = true;
    canvas.drawPath(renderPath, paint);
    if (bleed <= 0) return;
    canvas.drawPath(
      renderPath,
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = bleed * 2
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round,
    );
  }

  /// Paylaşılan puzzle görseli; [PieceDrawRects.src], parça-yerel
  /// koordinatlarda [PieceDrawRects.dst] üzerine düşecek şekilde
  /// yerleştirilir — `drawImageRect`'in yapacağı eşlemenin aynısı, ama
  /// shader olarak, böylece katmanın örtüsüne göre kırpılabilir.
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
      oldDelegate.bleed != bleed ||
      oldDelegate.outlineColour != outlineColour ||
      oldDelegate.outlineWidth != outlineWidth ||
      oldDelegate.bevelDepth != bevelDepth;
}
