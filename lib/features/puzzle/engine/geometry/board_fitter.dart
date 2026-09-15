import 'dart:math' show max, min;
import 'dart:ui' show Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';
import 'coordinate_mapper.dart';
import 'tray_layout_calculator.dart';

/// Bir ekranda board ile tepsinin birlikte nasıl durduğu (§40, K-15).
class BoardFit {
  const BoardFit({required this.boardEdge, required this.tray});

  /// Kare board'un kenarı.
  final double boardEdge;

  /// Board'un altında kalan yerdeki tepsi dizilimi.
  final TrayLayout tray;
}

/// Board'u önce §40'ın formülüyle boyutlandırır; tepsi o zaman her parçayı
/// 64 px'in üstünde tutamıyorsa board'u, tutabileceği en büyük boya kadar
/// küçültür (K-15).
///
/// 4 × 3 ve 4 × 4 puzzle'lar (12 ve 16 parça) küçük telefonlarda ancak böyle
/// sığar: 320 × 568'de board 304'ten 276'ya iner ve parçalar yine 64 px'tir.
/// Kural bozulmaz, yalnızca ödün sırası uzar: dokunma hedefi (asla) >
/// kaymayan tepsi (asla) > board'un boyu (§2, §16).
///
/// Tepsinin raf biçimi burada ayrıca aranmaz: ölçüldüğünde board'u küçültmek
/// hiçbir ekranda rafı kurtarmadı. 320 dp'de 4 × 3'ün parçaları dört sütuna
/// hiçbir board boyunda sığmaz; orada tepsi hesabının kendi ödün sırası
/// (dokunma hedefi > raf) geçerlidir.
///
/// Küçülen board, en uzun kenarındaki hücre dokunma hedefinden küçük olacak
/// kadar küçülmez; o noktada da sığmıyorsa §40'ın boyuna dönülür ve tepsi
/// hesabının kendi geri çekilmesi devreye girer.
abstract final class BoardFitter {
  static BoardFit fit({required Size area, required PuzzleGrid grid}) {
    final preferred = min(
      min(
        area.width - 2 * PuzzleConfig.boardMargin,
        area.height * PuzzleConfig.boardHeightFactor,
      ),
      PuzzleConfig.maxBoardSize,
    );

    // §40'ın boyu her zaman önce denenir; çoğu ekranda sonuç budur.
    final atPreferred = _trayFor(area, grid, preferred);
    if (atPreferred != null) {
      return BoardFit(boardEdge: preferred, tray: atPreferred);
    }

    final smallest =
        max(grid.rows, grid.columns) * PuzzleConfig.minTouchTargetSize;
    for (var edge = preferred - PuzzleConfig.boardFitStep;
        edge >= smallest;
        edge -= PuzzleConfig.boardFitStep) {
      final tray = _trayFor(area, grid, edge);
      if (tray != null) return BoardFit(boardEdge: edge, tray: tray);
    }

    return BoardFit(
      boardEdge: preferred,
      tray: TrayLayoutCalculator.calculate(
        traySize: Size(area.width, area.height - preferred),
        pieceCount: grid.pieceCount,
        boardPieceSize: _pieceSize(grid, preferred),
      ),
    );
  }

  static TrayLayout? _trayFor(Size area, PuzzleGrid grid, double edge) =>
      TrayLayoutCalculator.tryCalculate(
        traySize: Size(area.width, area.height - edge),
        pieceCount: grid.pieceCount,
        boardPieceSize: _pieceSize(grid, edge),
      );

  static Size _pieceSize(PuzzleGrid grid, double edge) =>
      CoordinateMapper.pieceSizeOf(
        CoordinateMapper.cellSizeOf(grid, Size(edge, edge)),
      );
}
