import 'dart:math' show min;
import 'dart:ui' show Rect, Size;

import '../../../../core/constants/puzzle_config.dart';

/// Bir tepsi dizilimi: kaç satır, kaç sütun ve her parçanın boyu.
class TrayLayout {
  const TrayLayout({
    required this.traySize,
    required this.rows,
    required this.columns,
    required this.itemSize,
    required this.spacing,
    required this.meetsTouchTarget,
  });

  final Size traySize;
  final int rows;
  final int columns;
  final Size itemSize;
  final double spacing;

  /// Her öğenin [PuzzleConfig.minTouchTargetSize] sınırını geçip geçmediği
  /// (§2).
  final bool meetsTouchTarget;

  int get slotCount => rows * columns;

  /// Bir yuvanın tepsi içindeki yeri. Yuvalar satır önceliklidir ve puzzle
  /// boyunca sabit kalır (§16.2).
  Rect slotRect(int slotIndex) {
    assert(
      slotIndex >= 0 && slotIndex < slotCount,
      'slot $slotIndex out of range 0..${slotCount - 1}',
    );
    final row = slotIndex ~/ columns;
    final column = slotIndex % columns;

    final contentWidth = columns * itemSize.width + (columns - 1) * spacing;
    final contentHeight = rows * itemSize.height + (rows - 1) * spacing;

    return Rect.fromLTWH(
      (traySize.width - contentWidth) / 2 + column * (itemSize.width + spacing),
      (traySize.height - contentHeight) / 2 + row * (itemSize.height + spacing),
      itemSize.width,
      itemSize.height,
    );
  }

  @override
  String toString() => 'TrayLayout(${rows}x$columns, item $itemSize)';
}

/// Parçaları kaydırma olmadan tepsiye sığdırır (§16.1).
///
/// Parça boyu türetilir, asla sabitlenmez: sabit bir ölçek küçük telefonda
/// 64 px'lik dokunma hedefini kırar ve eğilmeyen kural odur.
abstract final class TrayLayoutCalculator {
  static TrayLayout calculate({
    required Size traySize,
    required int pieceCount,
    required Size boardPieceSize,
    double spacing = PuzzleConfig.trayItemSpacing,
    double minTouchTarget = PuzzleConfig.minTouchTargetSize,
    double preferredScale = PuzzleConfig.trayPreferredPieceScale,
  }) {
    assert(pieceCount > 0, 'pieceCount must be positive');
    assert(!boardPieceSize.isEmpty, 'boardPieceSize must be non-empty');

    final aspectRatio = boardPieceSize.width / boardPieceSize.height;

    // Tepsi bir raftır: boyunca bakılır, aşağı doğru değil. Önce eninden
    // yüksek olmayan dizilimler değerlendirilir; geri kalanlar ancak
    // bunların hiçbiri parçaları tam boyda tutamazsa devreye girer.
    //
    // Bu kural olmadan uzun bir tepside — tablette board 500 px'te durur ve
    // altındaki her şey artar — parçalar ekranın ortasında tek bir sütun
    // halinde dizilir. Her parça hâlâ dokunulabilecek kadar büyüktür, yani
    // hiçbir şey başarısız olmaz; sadece tepsiye benzemekten çıkar
    // (§16.1, §40).
    //
    // Yer daraldığında ilk feda edilen dış kenar boşluğudur — yatay tutulan
    // bir telefonda dokuz parça için hiç pay yoktur — ikinci sırada raf
    // biçimi gelir. Dokunma hedefinden asla vazgeçilmez (§2).
    for (final (shelvesOnly, outerMargin) in const [
      (true, true),
      (true, false),
      (false, true),
      (false, false),
    ]) {
      final layout = _bestFit(
        traySize: traySize,
        pieceCount: pieceCount,
        boardPieceSize: boardPieceSize,
        aspectRatio: aspectRatio,
        spacing: spacing,
        minTouchTarget: minTouchTarget,
        preferredScale: preferredScale,
        shelvesOnly: shelvesOnly,
        outerMargin: outerMargin,
      );
      if (layout != null) return layout;
    }

    return _fallback(
      traySize: traySize,
      pieceCount: pieceCount,
      aspectRatio: aspectRatio,
      spacing: spacing,
      minTouchTarget: minTouchTarget,
    );
  }

  /// Parçaları [preferredScale]'e en yakın düşen dizilim; hiçbiri her parçayı
  /// dokunma hedefinin üstünde tutamıyorsa null.
  static TrayLayout? _bestFit({
    required Size traySize,
    required int pieceCount,
    required Size boardPieceSize,
    required double aspectRatio,
    required double spacing,
    required double minTouchTarget,
    required double preferredScale,
    required bool shelvesOnly,
    required bool outerMargin,
  }) {
    final edges = outerMargin ? 1 : -1;
    TrayLayout? best;
    var bestDistance = double.infinity;

    for (var rows = 1; rows <= pieceCount; rows++) {
      final columns = (pieceCount / rows).ceil();
      // Boşluk yalnızca parçalar arasında değil, dış kenarlarda da sayılır:
      // içeriği tam tepsi genişliğinde olan bir tepsi, en dıştaki parçaları
      // ekran kenarına dayar ve orada yapboz tırnağının taşacak yeri kalmaz
      // (§16.1).
      final widthCap = (traySize.width - (columns + edges) * spacing) / columns;
      final heightCap = (traySize.height - (rows + edges) * spacing) / rows;
      if (widthCap <= 0 || heightCap <= 0) continue;

      final itemWidth = min(widthCap, heightCap * aspectRatio);
      final itemHeight = itemWidth / aspectRatio;

      if (shelvesOnly && columns < rows) continue;

      final candidate = TrayLayout(
        traySize: traySize,
        rows: rows,
        columns: columns,
        itemSize: Size(itemWidth, itemHeight),
        spacing: spacing,
        // §16.1 yalnızca genişliği söyler; eninden uzun bir parça aksi
        // halde diğer ekseninde hedefin altına sızardı.
        meetsTouchTarget:
            itemWidth >= minTouchTarget && itemHeight >= minTouchTarget,
      );
      if (!candidate.meetsTouchTarget) continue;

      final distance =
          (itemWidth / boardPieceSize.width - preferredScale).abs();
      if (distance < bestDistance) {
        bestDistance = distance;
        best = candidate;
      }
    }

    return best;
  }

  /// Hiçbiri tam boyda sığmıyor. Yayın derlemesi yine de bir şey göstermek
  /// zorunda; bu yüzden çocuğun oyununu çökertmek yerine en yassı dizilim
  /// kullanılır. Debug derlemesi önce bunu söyler.
  static TrayLayout _fallback({
    required Size traySize,
    required int pieceCount,
    required double aspectRatio,
    required double spacing,
    required double minTouchTarget,
  }) {
    assert(
      false,
      'no tray layout keeps $pieceCount pieces at ${minTouchTarget}px in '
      '$traySize — this grid cannot be played on this screen (§2, §16.1)',
    );

    for (var rows = 1; rows <= pieceCount; rows++) {
      final columns = (pieceCount / rows).ceil();
      final widthCap = (traySize.width - (columns + 1) * spacing) / columns;
      final heightCap = (traySize.height - (rows + 1) * spacing) / rows;
      if (widthCap <= 0 || heightCap <= 0) continue;

      final itemWidth = min(widthCap, heightCap * aspectRatio);
      return TrayLayout(
        traySize: traySize,
        rows: rows,
        columns: columns,
        itemSize: Size(itemWidth, itemWidth / aspectRatio),
        spacing: spacing,
        meetsTouchTarget: false,
      );
    }
    throw StateError('tray $traySize is too small for any layout');
  }
}
