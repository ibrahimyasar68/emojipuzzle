import 'dart:ui' show Color, Rect;

import '../models/puzzle_category.dart';

/// Puzzle parçalarının üzerine boyandığı yüzey, parça-yerel koordinatlarda.
class PieceBackground {
  const PieceBackground({
    required this.from,
    required this.to,
    required this.boardRect,
  });

  final Color from;
  final Color to;

  /// Board'un tamamının bu parçanın kendi koordinatlarındaki yeri; böylece
  /// gradyan her parçada baştan başlamak yerine board boyunca bir kez
  /// serilir.
  final Rect boardRect;

  @override
  bool operator ==(Object other) =>
      other is PieceBackground &&
      other.from == from &&
      other.to == to &&
      other.boardRect == boardRect;

  @override
  int get hashCode => Object.hash(from, to, boardRect);
}

/// Parçaların üzerinde durduğu renkler.
///
/// Görseller tasarım gereği şeffaftır (§34) ve şeffaf bir yapboz parçası,
/// çocuğun tepside ne görebildiği ne de nişan alabildiği bir parçadır. Bu
/// yüzden resim çalışma anında bestelenir: önce bu yüzey, üstüne emoji.
/// Asset dosyalarına dokunulmaz; bu aynı zamanda lisansı da basit tutar
/// (§33).
///
/// Yüzey düz bir dolgu değil, board boyunca uzanan bir gradyandır ve asıl
/// mesele budur: bir emoji bazı parçaları tamamen boş bırakır — 3×3 bir
/// arabanın köşelerinde hiç araba yoktur — ve birbirinin aynı dokuz boş
/// kare, çocuğun ayırt edemeyeceği dokuz karedir. Gradyan her parçaya kendi
/// tonunu verir ve yine de tek bir temiz resimde birleşir.
abstract final class PuzzlePalette {
  static const _fallback = (Color(0xFFFDF7EF), Color(0xFFF3E4D0));

  static const _byCategory = <PuzzleCategory, (Color, Color)>{
    PuzzleCategory.fruits: (Color(0xFFFFF6E3), Color(0xFFFFD9A8)),
    PuzzleCategory.animals: (Color(0xFFEFF8EF), Color(0xFFBFE3C4)),
    PuzzleCategory.vehicles: (Color(0xFFEAF4FD), Color(0xFFB6D8F2)),
    PuzzleCategory.nature: (Color(0xFFFFFDEB), Color(0xFFDCEBA6)),
    PuzzleCategory.shapes: (Color(0xFFF8EEFA), Color(0xFFD8BFE4)),
    // K-14 — öbür beşinden ayrılan yumuşak bir pembe.
    PuzzleCategory.objects: (Color(0xFFFDEFF2), Color(0xFFF3C1CC)),
  };

  /// Bir kategorinin gradyanının iki ucu.
  static (Color, Color) gradientOf(PuzzleCategory category) =>
      _byCategory[category] ?? _fallback;

  static PieceBackground backgroundFor(
    PuzzleCategory category, {
    required Rect boardRect,
  }) {
    final (from, to) = gradientOf(category);
    return PieceBackground(from: from, to: to, boardRect: boardRect);
  }
}
