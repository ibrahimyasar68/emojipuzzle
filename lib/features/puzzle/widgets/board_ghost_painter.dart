import 'dart:ui' as ui;

import 'package:flutter/foundation.dart' show setEquals;
import 'package:flutter/widgets.dart';

import '../../../core/constants/puzzle_config.dart';
import '../data/puzzle_palette.dart';
import '../models/puzzle_grid.dart';

/// Boş board: silik silik görünen resim ve her yuvanın etrafındaki kesikli
/// kontur (§15).
///
/// İki ipucu da okuma bilmeyen bir çocuk için var: hayalet buraya *ne*
/// geleceğini söyler, kontur buraya *bir şey* geleceğini.
class BoardGhostPainter extends CustomPainter {
  const BoardGhostPainter({
    required this.image,
    required this.grid,
    this.background,
    this.slotOutlines = const <int, Path>{},
    this.filledPieceIds = const <int>{},
  });

  final ui.Image image;
  final PuzzleGrid grid;

  /// Her yuvanın kesikli konturu, parça kimliğine göre, board
  /// koordinatlarında (§15). [PiecePaths] bir kez kurar; bu boyayıcı
  /// yalnızca çizer.
  final Map<int, Path> slotOutlines;

  /// Board'da çoktan yerleşmiş parçalar.
  ///
  /// Dolan bir yuva doldurulmayı istemekten vazgeçer: kesikli konturu artık
  /// çizilmez. Parça opaktır ve kendi konturunu örter, ama tırnakları yan
  /// yuvalara uzanır; bu yüzden geride bırakılan bir kontur tamamlanmış
  /// resmin içinden görünürdü (§15).
  final Set<int> filledPieceIds;

  /// Parçaların kendilerinin boyandığı yüzey; böylece boş board gelecek
  /// olan resmi vaat eder (§15, §34).
  final PieceBackground? background;

  // Açık kanal değerleriyle yazılır ki boyayıcı, yalnızca Flutter 3.27'den
  // itibaren var olan Color.withValues'a bağlı olmasın (§0 3.24'e izin
  // veriyor).
  static const _ghostVeil = Color.fromRGBO(0, 0, 0, PuzzleConfig.ghostOpacity);
  static const _outlineColour = Color.fromRGBO(141, 110, 99, 0.45);

  @override
  void paint(Canvas canvas, Size size) {
    final board = Offset.zero & size;

    canvas.saveLayer(board, Paint()..color = _ghostVeil);
    final surface = background;
    if (surface != null) {
      canvas.drawRect(
        board,
        Paint()
          ..shader = ui.Gradient.linear(
            surface.boardRect.topLeft,
            surface.boardRect.bottomRight,
            [surface.from, surface.to],
          ),
      );
    }
    canvas.drawImageRect(
      image,
      Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
      board,
      Paint()
        ..filterQuality = FilterQuality.medium
        ..isAntiAlias = true,
    );
    canvas.restore();

    final outline = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = PuzzleConfig.slotOutlineStrokeWidth
      ..color = _outlineColour
      ..isAntiAlias = true;

    for (final entry in slotOutlines.entries) {
      if (filledPieceIds.contains(entry.key)) continue;
      canvas.drawPath(entry.value, outline);
    }
  }

  @override
  bool shouldRepaint(BoardGhostPainter oldDelegate) =>
      !setEquals(oldDelegate.filledPieceIds, filledPieceIds) ||
      !identical(oldDelegate.slotOutlines, slotOutlines) ||
      !identical(oldDelegate.image, image) ||
      oldDelegate.grid != grid ||
      oldDelegate.background != background;
}
