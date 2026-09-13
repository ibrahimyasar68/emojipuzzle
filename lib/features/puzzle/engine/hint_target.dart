import '../models/puzzle_piece.dart';

/// İpucunun hangi parçayı göstereceğini seçer (§21.1).
abstract final class HintTarget {
  /// Kalanlar içinde en kolayı: en çok düz kenarı olan, eşitlikte en küçük
  /// kimlikli parça.
  ///
  /// Düz kenar board sınırı demektir ve kenar parçası, çocuğun gerçekten
  /// akıl yürütebileceği parçadır — "kenar boyunca gidiyor". Eşitlik kuralı,
  /// cevabın hiçbir zaman belirsiz kalmaması için var: 1×3'te ortadaki parça
  /// ile köşe parçasının ikisinin de iki düz kenarı vardır ve seçim
  /// yapamayan kural, kural değildir (§21.1).
  static PuzzlePiece? choose(Iterable<PuzzlePiece> candidates) {
    PuzzlePiece? best;
    for (final piece in candidates) {
      final champion = best;
      if (champion == null ||
          piece.flatEdgeCount > champion.flatEdgeCount ||
          (piece.flatEdgeCount == champion.flatEdgeCount &&
              piece.id < champion.id)) {
        best = piece;
      }
    }
    return best;
  }
}
