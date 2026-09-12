import 'dart:ui' show Offset;

import 'piece_status.dart';

/// Mutable-in-spirit, immutable-in-code runtime state of one piece (§12).
///
/// The geometry lives in `PuzzlePiece` and never changes; everything that
/// changes while playing lives here.
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

  /// Fixed tray slot (§16.2). Set once when the puzzle starts; the slot
  /// stays empty after the piece leaves, so nothing reflows under the
  /// child's fingers.
  final int traySlotIndex;

  final PieceStatus status;

  /// Where the piece sits while being dragged (Faz 5), in board pixels.
  final Offset? dragOffset;

  /// Failed drops for this piece; drives assist mode (§19). Reset only when
  /// the piece is placed or the puzzle restarts — never carried to another
  /// piece.
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
