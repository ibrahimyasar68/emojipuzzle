import 'dart:ui' show Offset, Path, Size;

import '../../../../core/constants/puzzle_config.dart';
import '../../models/puzzle_grid.dart';
import '../../models/puzzle_piece.dart';
import '../geometry/coordinate_mapper.dart';
import 'jigsaw_path_generator.dart';

/// Tek bir board boyutu için değişmez path önbelleği (§14, §42).
///
/// Path'ler puzzle başına bir kez kurulur ve her karede yeniden kullanılır;
/// `build()` ya da `paint()` içinde hiçbir [Path] üretilmez.
///
/// Parça başına tek path; hit-test, snap, kırpma ve boyama aynı path'i
/// kullanır.
///
/// Eskiden her konturun bir de biraz büyütülmüş ikinci kopyası vardı;
/// komşular bir kıl payı örtüşsün ve kenar yumuşatma aralarında görünür bir
/// dikiş bırakmasın diye (§14). Bu eğrileri boolean path işlemleriyle
/// büyütmenin hiç çalışmadığı ortaya çıktı — knob'un boynu kendi başının
/// altını keser ve birleşim, sınır kutusu birebir doğru görünürken bambaşka
/// bir şekil döndürür. Taşma artık konturu çizgiyle boyayan
/// `PuzzlePiecePainter`'a ait.
///
/// Path'ler board boyutuna bağlıdır, bu yüzden yeniden boyutlandırma tüm
/// kümeyi geçersiz kılar. Çağıranlar [matches]'e bakar ve yalnızca false
/// dönerse yeniden kurar.
class PiecePaths {
  PiecePaths._(this.boardSize, this._paths, this._dashedSlots);

  factory PiecePaths.build({
    required List<PuzzlePiece> pieces,
    required PuzzleGrid grid,
    required Size boardSize,
  }) {
    final cellSize = CoordinateMapper.cellSizeOf(grid, boardSize);

    final paths = <int, Path>{
      for (final piece in pieces)
        piece.id: JigsawPathGenerator.build(piece: piece, cellSize: cellSize),
    };
    // §15 — çocuğun boş bir yuvanın etrafında gördüğü kesikli kontur;
    // `paint` hiçbir zaman path yürütmesin diye burada kurulur (§42).
    final slots = <int, Path>{
      for (final piece in pieces)
        piece.id: _dashedSlot(
          piece: piece,
          grid: grid,
          boardSize: boardSize,
          cellSize: cellSize,
        ),
    };

    return PiecePaths._(
      boardSize,
      Map.unmodifiable(paths),
      Map.unmodifiable(slots),
    );
  }

  /// Bu path'lerin hangi board boyutu için kurulduğu.
  final Size boardSize;

  final Map<int, Path> _paths;
  final Map<int, Path> _dashedSlots;

  /// Parçanın tam konturu, parça-yerel koordinatlarda.
  Path of(int pieceId) => _pathFrom(_paths, pieceId);

  /// Her yuvanın kesikli konturu, parça kimliğine göre (§15).
  ///
  /// **Bunlar board koordinatındadır**, parça-yerel olan [of]'un aksine:
  /// board'un hayalet katmanı tarafından çizilirler ve o katmanın yerel
  /// olacağı bir parça yoktur. Dönüşüm bir kez, burada yapılır.
  Map<int, Path> get dashedSlots => _dashedSlots;

  int get length => _paths.length;

  /// Bu önbelleğin [candidate] için hâlâ geçerli olup olmadığı.
  bool matches(Size candidate) => boardSize == candidate;

  /// Bir yuvanın dört kenarı, kesikli, board koordinatlarında.
  ///
  /// Kapalı kontur yerine kenar kenar kurulur, çünkü her kenarın sabit bir
  /// yönde yürünmesi gerekir: bir parçanın sağ kenarı ile komşusunun sol
  /// kenarı aynı eğridir ve yalnızca birebir aynı yürüyüş birebir aynı
  /// kesikleri üretir. Kapalı konturu kesikleştirmek her parçayı kendi
  /// köşesinden başlatır; böylece her dikişin iki yakası fazdan çıkar ve
  /// birbirinin boşluklarını doldurur — kesikli olması gereken dikiş düz
  /// çıkar.
  static Path _dashedSlot({
    required PuzzlePiece piece,
    required PuzzleGrid grid,
    required Size boardSize,
    required Size cellSize,
  }) {
    final origin = CoordinateMapper.pieceOriginOf(
      normalizedPosition: piece.normalizedPosition,
      grid: grid,
      boardSize: boardSize,
    );

    final dashed = Path();
    for (final side in PieceSide.values) {
      final edge = JigsawPathGenerator.edgePath(
        piece: piece,
        side: side,
        cellSize: cellSize,
      );
      for (final metric in edge.computeMetrics()) {
        var travelled = 0.0;
        while (travelled < metric.length) {
          final end = (travelled + PuzzleConfig.slotOutlineDashLength)
              .clamp(0.0, metric.length);
          dashed.addPath(
            metric.extractPath(travelled, end),
            Offset.zero,
          );
          travelled = end + PuzzleConfig.slotOutlineDashGap;
        }
      }
    }
    return dashed.shift(origin);
  }

  Path _pathFrom(Map<int, Path> source, int pieceId) =>
      source[pieceId] ??
      (throw ArgumentError.value(pieceId, 'pieceId', 'no path for this piece'));
}
