import 'dart:ui' show Offset;

/// Parmak bırakıldıktan sonra parçanın ne yaptığı.
enum PieceFlightKind {
  /// Doğru bırakma: parça yuvasına yerleşiyor (§3).
  settle,

  /// Yanlış bırakma: parça sallanarak tepsiye dönüyor (§20).
  snapBack,
}

/// Bırakma sonrası tek bir animasyon (§3, §20).
///
/// [DragState] gibi bu da provider'ın dışında yaşar: her karede değişir.
/// Uçuş bitene kadar parça sürükleme katmanına ait kalır; böylece hiçbir an
/// iki kez çizilmez — bir uçarken, bir dururken.
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

  /// İkisi de sürükleme katmanının kendi koordinat uzayında.
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
