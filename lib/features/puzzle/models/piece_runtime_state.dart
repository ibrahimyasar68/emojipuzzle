import 'dart:ui' show Offset;

import 'piece_status.dart';

/// Bir parçanın çalışma anı durumu: ruhen değişken, kod olarak değişmez
/// (§12).
///
/// Geometri `PuzzlePiece` içindedir ve hiç değişmez; oynarken değişen her
/// şey buradadır.
class PieceRuntimeState {
  const PieceRuntimeState({
    required this.pieceId,
    required this.traySlotIndex,
    this.status = PieceStatus.inTray,
    this.dragOffset,
    this.failedAttempts = 0,
  })  : assert(pieceId >= 0, 'pieceId must be non-negative'),
        assert(traySlotIndex >= 0, 'traySlotIndex must be non-negative'),
        assert(failedAttempts >= 0, 'failedAttempts must be non-negative');

  final int pieceId;

  /// Sabit tepsi yuvası (§16.2). Puzzle başlarken bir kez atanır; parça
  /// ayrıldıktan sonra yuva boş kalır, böylece çocuğun parmağının altında
  /// hiçbir şey yeniden dizilmez.
  final int traySlotIndex;

  final PieceStatus status;

  /// Parça sürüklenirken nerede durduğu (Faz 5), board pikselinde.
  final Offset? dragOffset;

  /// Bu parçanın başarısız bırakma sayısı; assist modunu tetikler (§19).
  /// Yalnızca parça yerleştiğinde ya da puzzle yeniden başladığında sıfırlanır
  /// — asla başka bir parçaya taşınmaz.
  final int failedAttempts;

  PieceRuntimeState copyWith({
    PieceStatus? status,
    Offset? dragOffset,
    bool clearDragOffset = false,
    int? failedAttempts,
  }) {
    return PieceRuntimeState(
      pieceId: pieceId,
      traySlotIndex: traySlotIndex,
      status: status ?? this.status,
      dragOffset: clearDragOffset ? null : (dragOffset ?? this.dragOffset),
      failedAttempts: failedAttempts ?? this.failedAttempts,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is PieceRuntimeState &&
      other.pieceId == pieceId &&
      other.traySlotIndex == traySlotIndex &&
      other.status == status &&
      other.dragOffset == dragOffset &&
      other.failedAttempts == failedAttempts;

  @override
  int get hashCode =>
      Object.hash(pieceId, traySlotIndex, status, dragOffset, failedAttempts);

  @override
  String toString() => 'PieceRuntimeState(#$pieceId slot $traySlotIndex '
      '${status.name} attempts:$failedAttempts)';
}
