import 'dart:ui' show Offset;

import '../engine/geometry/coordinate_mapper.dart';

/// Süren tek bir sürükleme (§9, §17).
///
/// Bilerek provider'da tutulmaz: her işaretçi hareketinde değişir ve tüm
/// widget ağacını bu sıklıkta uyandırmak §17'nin yasakladığı şeyin ta
/// kendisidir. Bunun yerine bir `ValueNotifier` üzerinden taşınır.
class DragState {
  const DragState({
    required this.pieceId,
    required this.grabOffset,
    required this.pointerBoardLocal,
    required this.fromScale,
  });

  final int pieceId;

  /// Parmağın parçanın neresine bastığı, board ölçeğinde. Sürükleme boyunca
  /// sabittir; böylece parça parmağın ortasına zıplamaz (§9).
  final Offset grabOffset;

  /// İşaretçinin board koordinatlarındaki güncel konumu.
  final Offset pointerBoardLocal;

  /// Parçanın tepsideki ölçeği; kaldırma animasyonu buradan başlar.
  final double fromScale;

  /// Parçanın sol üstü, board koordinatlarında (§9).
  Offset get pieceOriginBoardLocal => CoordinateMapper.pieceOriginFromPointer(
        pointerBoardLocal: pointerBoardLocal,
        grabOffset: grabOffset,
      );

  DragState movedTo(Offset pointerBoardLocal) => DragState(
        pieceId: pieceId,
        grabOffset: grabOffset,
        pointerBoardLocal: pointerBoardLocal,
        fromScale: fromScale,
      );

  @override
  bool operator ==(Object other) =>
      other is DragState &&
      other.pieceId == pieceId &&
      other.grabOffset == grabOffset &&
      other.pointerBoardLocal == pointerBoardLocal &&
      other.fromScale == fromScale;

  @override
  int get hashCode =>
      Object.hash(pieceId, grabOffset, pointerBoardLocal, fromScale);

  @override
  String toString() =>
      'DragState(#$pieceId pointer $pointerBoardLocal grab $grabOffset)';
}
