import 'dart:ui' show Offset;

import '../engine/geometry/coordinate_mapper.dart';

/// One in-flight drag (§9, §17).
///
/// This deliberately does not live in the provider: it changes on every
/// pointer move, and waking the whole widget tree that often is exactly
/// what §17 forbids. It travels through a `ValueNotifier` instead.
class DragState {
  const DragState({
    required this.pieceId,
    required this.grabOffset,
    required this.pointerBoardLocal,
    required this.fromScale,
  });

  final int pieceId;

  /// Where inside the piece the finger landed, at board scale. Fixed for
  /// the whole drag, so the piece never jumps to the finger's centre (§9).
  final Offset grabOffset;

  /// Current pointer position in board coordinates.
  final Offset pointerBoardLocal;

  /// Scale the piece had in the tray, where the lift animation starts.
  final double fromScale;

  /// Top-left of the piece, in board coordinates (§9).
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
