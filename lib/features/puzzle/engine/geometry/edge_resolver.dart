import 'dart:math' show Random;

import '../../models/edge_type.dart';
import '../../models/puzzle_grid.dart';

/// Bir hücrenin dört kenarı; [EdgeResolver] bunu üretir.
typedef PieceEdges = ({
  EdgeType top,
  EdgeType right,
  EdgeType bottom,
  EdgeType left,
});

/// Bir gridin her hücresine kenar biçimlerini atar (§11).
abstract final class EdgeResolver {
  /// Her hücrenin kenarlarını, parça kimliğine göre sıralı döndürür (§8.6).
  ///
  /// Hücreler satır satır, soldan sağa gezilir. `top` ve `left`, daha önce
  /// gezilmiş komşulardan tümleyeni olarak devralınır; `right` ve `bottom`
  /// [random]'dan çekilir. Board sınırları düzdür.
  ///
  /// Çekim sırası (hücre başına önce sağ, sonra alt) determinizm
  /// sözleşmesinin parçasıdır: aynı seed her zaman aynı puzzle'ı verir.
  static List<PieceEdges> resolve(PuzzleGrid grid, Random random) {
    final edges = <PieceEdges>[];

    for (var row = 0; row < grid.rows; row++) {
      for (var column = 0; column < grid.columns; column++) {
        final top = row == 0
            ? EdgeType.flat
            : edges[grid.idOf(row - 1, column)].bottom.complement;
        final left = column == 0
            ? EdgeType.flat
            : edges[grid.idOf(row, column - 1)].right.complement;
        final right =
            column == grid.columns - 1 ? EdgeType.flat : _randomInner(random);
        final bottom =
            row == grid.rows - 1 ? EdgeType.flat : _randomInner(random);

        edges.add((top: top, right: right, bottom: bottom, left: left));
      }
    }

    return List.unmodifiable(edges);
  }

  static EdgeType _randomInner(Random random) =>
      random.nextBool() ? EdgeType.tab : EdgeType.blank;
}
