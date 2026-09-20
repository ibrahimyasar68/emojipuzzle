import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/puzzle_image_loader.dart';
import '../../puzzle/data/puzzle_palette.dart';
import '../../puzzle/engine/geometry/coordinate_mapper.dart';
import '../../puzzle/engine/geometry/piece_image_mapper.dart';
import '../../puzzle/engine/geometry/puzzle_generator.dart';
import '../../puzzle/engine/path/piece_paths.dart';
import '../../puzzle/models/puzzle_grid.dart';
import '../../puzzle/models/puzzle_piece.dart';
import '../../puzzle/widgets/puzzle_piece_painter.dart';

/// Giriş ekranının oyna düğmesi: gülen surat, **dört parçalı bitmiş bir
/// yapboz** olarak, sağ alt köşesinde küçük kırmızı bir oynat işaretiyle
/// (K-21, kullanıcı istedi).
///
/// Yüz bir asset'tir (`assets/images/ui/smile.png`, kodla çizildi, K-16 ile
/// aynı betik); parçalara ayıran şey oyunun kendi motorudur — düğme
/// çocuğa bir dakika sonra yapacağı şeyin resmidir.
///
/// Görsel yüklenene kadar yerinde aynı boyutta bir sarı kare durur: düğme
/// hiç yer değiştirmez, dokunma hedefi ilk kareden itibaren tam boyuttadır
/// (§2).
class PlayPuzzleButton extends StatefulWidget {
  const PlayPuzzleButton({
    super.key,
    required this.size,
    required this.onTap,
    this.semanticLabel = 'Oyna',
  });

  /// Karenin kenarı; dokunma hedefi de budur.
  final double size;

  final VoidCallback onTap;
  final String semanticLabel;

  /// Yüzün yolu. Havuzdaki resimlerle aynı üslupta ama puzzle değil: bu
  /// yüzden `assets/images/ui/` altında durur.
  static const String facePath = 'assets/images/ui/smile.png';

  /// Dört parça: §4'ün en küçük ebadı, çocuğun ilk oynayacağı boy.
  static const PuzzleGrid grid = PuzzleGrid(rows: 2, columns: 2);

  @override
  State<PlayPuzzleButton> createState() => _PlayPuzzleButtonState();
}

class _PlayPuzzleButtonState extends State<PlayPuzzleButton> {
  /// Tek bir yükleyici: aynı görseli her yeniden kurulumda çözmemek için
  /// (§14).
  static final PuzzleImageLoader _loader = PuzzleImageLoader();

  late Future<ui.Image> _faceImage;

  /// Parçaların şekli zarla üretilir, ama düğmenin yüzü her açılışta aynı
  /// görünmeli: sabit tohum.
  late final List<PuzzlePiece> _pieces =
      PuzzleGenerator(random: Random(11)).generate(PlayPuzzleButton.grid);

  @override
  void initState() {
    super.initState();
    _faceImage = _loader.load(PlayPuzzleButton.facePath);
  }

  @override
  Widget build(BuildContext context) {
    final badge = widget.size * PuzzleConfig.homePlayBadgeFraction;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(child: _buildFace()),
              Positioned(
                right: -badge * 0.18,
                bottom: -badge * 0.18,
                child: _PlayBadge(size: badge),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFace() {
    return FutureBuilder<ui.Image>(
      future: _faceImage,
      builder: (context, snapshot) {
        final image = snapshot.data;
        if (image == null) {
          // Yükleniyor: yüzün kendi sarısından bir kare. Hata durumunda da
          // burası kalır — düğme her hâlükârda basılabilir olmalı (§14).
          return DecoratedBox(
            decoration: BoxDecoration(
              color: PuzzleConfig.homePlayFallbackColour,
              borderRadius: BorderRadius.circular(widget.size * 0.12),
            ),
          );
        }
        return CustomPaint(
          painter: _FinishedPuzzlePainter(
            image: image,
            pieces: _pieces,
            side: widget.size,
          ),
        );
      },
    );
  }
}

/// Bitmiş yapbozu tek bir tuvale çizer: dört parça, board'daki gibi
/// kabartmalı (K-19), aralarında gerçek dikişler.
class _FinishedPuzzlePainter extends CustomPainter {
  _FinishedPuzzlePainter({
    required this.image,
    required this.pieces,
    required this.side,
  })  : _paths = PiecePaths.build(
          pieces: pieces,
          grid: PlayPuzzleButton.grid,
          boardSize: Size(side, side),
        ),
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());

  final ui.Image image;
  final List<PuzzlePiece> pieces;
  final double side;

  final PiecePaths _paths;
  final Size _imageSize;

  @override
  void paint(Canvas canvas, Size size) {
    final board = Size(side, side);
    for (final piece in pieces) {
      final origin = CoordinateMapper.pieceOriginOf(
        normalizedPosition: piece.normalizedPosition,
        grid: PlayPuzzleButton.grid,
        boardSize: board,
      );
      canvas.save();
      canvas.translate(origin.dx, origin.dy);
      PuzzlePiecePainter(
        image: image,
        renderPath: _paths.of(piece.id),
        rects: PieceImageMapper.rectsOf(
          piece: piece,
          grid: PlayPuzzleButton.grid,
          boardSize: board,
          imageSize: _imageSize,
        ),
        background: PieceBackground(
          from: PuzzleConfig.homePlayBackgroundFrom,
          to: PuzzleConfig.homePlayBackgroundTo,
          boardRect: Rect.fromLTWH(-origin.dx, -origin.dy, side, side),
        ),
        bevelDepth: PuzzleConfig.pieceBevelDepth,
      ).paint(canvas, board);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(_FinishedPuzzlePainter oldDelegate) =>
      !identical(oldDelegate.image, image) || oldDelegate.side != side;
}

/// Sağ alt köşedeki küçük kırmızı oynat işareti (K-21). Beyaz halka onu
/// yapbozun üstünde de zeminde de görünür kılar.
class _PlayBadge extends StatelessWidget {
  const _PlayBadge({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: PuzzleConfig.homePlayBadgeColour,
        shape: BoxShape.circle,
        border: Border.all(
          color: const Color(0xFFFFFFFF),
          width: size * 0.08,
        ),
      ),
      alignment: Alignment.center,
      child: Icon(
        Icons.play_arrow_rounded,
        size: size * 0.6,
        color: const Color(0xFFFFFFFF),
      ),
    );
  }
}
