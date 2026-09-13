import 'dart:ui' show Offset, Path, Size;

import '../../models/edge_type.dart';
import '../../models/puzzle_piece.dart';
import '../geometry/coordinate_mapper.dart';

/// Tırnağın tek bir kübik parçası, kenar uzayında ifade edilmiş.
class _KnobCubic {
  const _KnobCubic(this.control1, this.control2, this.end);

  final Offset control1;
  final Offset control2;
  final Offset end;
}

/// Kenar uzayında tırnak profili (§7).
///
/// `dx` = u, kenar boyunca alınan yolun oranı (0 → 1).
/// `dy` = v, tabSize biriminde dik uzaklık; pozitif değer hücreden dışarı
/// bakar, yani tırnak `+v`, oyuk ise aynalanmış `-v` kullanır.
///
/// Bu tablonun iki özelliği yük taşır:
///
/// 1. `u = 0.5` etrafında simetriktir. Bir tırnak ile komşusundaki oyuk
///    aynı kenarı ters yönlerde çizer, böylece iki parça boşluk ya da
///    üst üste binme olmadan buluşur.
/// 2. Hiçbir kontrol noktası `v = 1.0`'ı aşmaz; tırnak parçanın sınır
///    kutusuna tam olarak değer ve dışına taşmaz (§7).
const _knobLeadInU = 0.35;

const _knobCurves = <_KnobCubic>[
  // Boyun: dışarı savrulur, sonra başın altını oymak için geri döner.
  _KnobCubic(Offset(0.45, 0.00), Offset(0.27, 0.45), Offset(0.31, 0.72)),
  // Baş, sol yarı, tepe noktasına kadar.
  _KnobCubic(Offset(0.35, 1.00), Offset(0.44, 1.00), Offset(0.50, 1.00)),
  // Baş, sağ yarı (solun aynası).
  _KnobCubic(Offset(0.56, 1.00), Offset(0.65, 1.00), Offset(0.69, 0.72)),
  // Boyun, aynalanmış.
  _KnobCubic(Offset(0.73, 0.45), Offset(0.55, 0.00), Offset(0.65, 0.00)),
];

/// Bir kenarın hücrenin hangi tarafında olduğu.
enum PieceSide { top, right, bottom, left }

/// Tek bir parçanın konturunu kurar (§5, §7).
///
/// Path **parça-yerel koordinattadır**: `(0,0)` parçanın sınır kutusunun sol
/// üstüdür ve hücre gövdesi `(tabSize, tabSize)` noktasında başlar. Tırnaklar
/// sınır kutusunun kenarına ulaşır; oyuklar hücrenin içine ısırır.
abstract final class JigsawPathGenerator {
  /// Hücreyi saat yönünde gezer: üst, sağ, alt, sol.
  static Path build({required PuzzlePiece piece, required Size cellSize}) {
    assert(!cellSize.isEmpty, 'cellSize must be non-empty');
    final corners = _cornersOf(cellSize);
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);

    final path = Path()..moveTo(corners.topLeft.dx, corners.topLeft.dy);
    _addEdge(
      path,
      corners.topLeft,
      corners.topRight,
      const Offset(0, -1),
      piece.top,
      tabSize,
    );
    _addEdge(
      path,
      corners.topRight,
      corners.bottomRight,
      const Offset(1, 0),
      piece.right,
      tabSize,
    );
    _addEdge(
      path,
      corners.bottomRight,
      corners.bottomLeft,
      const Offset(0, 1),
      piece.bottom,
      tabSize,
    );
    _addEdge(
      path,
      corners.bottomLeft,
      corners.topLeft,
      const Offset(-1, 0),
      piece.left,
      tabSize,
    );

    return path..close();
  }

  /// Tek bir kenar, her zaman soldan sağa ya da yukarıdan aşağı çizilir.
  ///
  /// Yön bilerek sabitlenmiştir. İki komşu bir kenarı paylaşır — birinin
  /// tırnağı diğerinin oyuğudur ve aynı eğriyi çizerler — bu yüzden iki
  /// taraftan da aynı şekilde yürümek *aynı path'i* noktası noktasına
  /// üretir. Ondan türeyen her şey, özellikle kesikler, o zaman üst üste
  /// oturur; iç içe geçip düz çizgiye dönmez (§15).
  static Path edgePath({
    required PuzzlePiece piece,
    required PieceSide side,
    required Size cellSize,
  }) {
    assert(!cellSize.isEmpty, 'cellSize must be non-empty');
    final corners = _cornersOf(cellSize);
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);

    final (start, end, outward, type) = switch (side) {
      PieceSide.top => (
          corners.topLeft,
          corners.topRight,
          const Offset(0, -1),
          piece.top,
        ),
      PieceSide.bottom => (
          corners.bottomLeft,
          corners.bottomRight,
          const Offset(0, 1),
          piece.bottom,
        ),
      PieceSide.left => (
          corners.topLeft,
          corners.bottomLeft,
          const Offset(-1, 0),
          piece.left,
        ),
      PieceSide.right => (
          corners.topRight,
          corners.bottomRight,
          const Offset(1, 0),
          piece.right,
        ),
    };

    final path = Path()..moveTo(start.dx, start.dy);
    _addEdge(path, start, end, outward, type, tabSize);
    return path;
  }

  static ({
    Offset topLeft,
    Offset topRight,
    Offset bottomRight,
    Offset bottomLeft,
  }) _cornersOf(Size cellSize) {
    final tabSize = CoordinateMapper.tabSizeOf(cellSize);
    final topLeft = Offset(tabSize, tabSize);
    return (
      topLeft: topLeft,
      topRight: topLeft + Offset(cellSize.width, 0),
      bottomRight: topLeft + Offset(cellSize.width, cellSize.height),
      bottomLeft: topLeft + Offset(0, cellSize.height),
    );
  }

  /// [outward] kenar hangi yönde yürünürse yürünsün hücreden dışarı bakar.
  /// Artık yürüme yönünden türetilemez: [edgePath] alt ve sol kenarları
  /// [build]'in tersi yönde gezer.
  static void _addEdge(
    Path path,
    Offset start,
    Offset end,
    Offset outward,
    EdgeType type,
    double tabSize,
  ) {
    if (type == EdgeType.flat) {
      path.lineTo(end.dx, end.dy);
      return;
    }

    final along = end - start;
    final length = along.distance;
    final unit = along / length;
    final direction = type == EdgeType.tab ? 1.0 : -1.0;

    Offset at(Offset uv) =>
        start +
        unit * (uv.dx * length) +
        outward * (uv.dy * tabSize * direction);

    final leadIn = at(const Offset(_knobLeadInU, 0));
    path.lineTo(leadIn.dx, leadIn.dy);

    for (final curve in _knobCurves) {
      final c1 = at(curve.control1);
      final c2 = at(curve.control2);
      final e = at(curve.end);
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, e.dx, e.dy);
    }

    path.lineTo(end.dx, end.dy);
  }
}
