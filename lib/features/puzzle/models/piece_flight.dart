import 'dart:ui' show Offset;

/// What a piece is doing after the finger let go.
enum PieceFlightKind {
  /// A correct drop settling into its slot (§3).
  settle,

  /// A wrong drop wobbling home to the tray (§20).
  snapBack,
}

/// One post-drop animation (§3, §20).
///
/// Like [DragState] this lives outside the provider: it changes every
/// frame. The piece keeps belonging to the drag layer until the flight
/// ends, so it is never drawn twice — once in flight and once at rest.
class PieceFlight {
  const PieceFlight({
    required this.pieceId,
    required this.from,
    required this.to,
    required this.fromScale,
    required this.toScale,
    required this.kind,
  });

  final int pieceId;

  /// Both in the drag layer's own coordinate space.
  final Offset from;
  final Offset to;

  final double fromScale;
  final double toScale;

  final PieceFlightKind kind;

  @override
  bool operator ==(Object other) =>
      other is PieceFlight &&
      other.pieceId == pieceId &&
      other.from == from &&
      other.to == to &&
      other.fromScale == fromScale &&
      other.toScale == toScale &&
      other.kind == kind;

  @override
  int get hashCode => Object.hash(pieceId, from, to, fromScale, toScale, kind);

  @override
  String toString() => 'PieceFlight(#$pieceId ${kind.name} $from → $to)';
}
