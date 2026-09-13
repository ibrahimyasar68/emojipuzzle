import 'dart:ui' show Offset;

/// Ekranda bir noktada patlayan "işte yerini buldu" kutlaması (§22).
class PlacementBurst {
  const PlacementBurst({required this.id, required this.centre});

  /// Her patlamada artar; böylece aynı yuvaya inen iki parça — ya da
  /// yeniden başlatmadan sonra ikinci kez inen bir parça — animasyonu
  /// baştan tetikler.
  final int id;

  /// Yuvanın ortası, onu çizen katmanın koordinatlarında.
  final Offset centre;

  @override
  bool operator ==(Object other) =>
      other is PlacementBurst && other.id == id && other.centre == centre;

  @override
  int get hashCode => Object.hash(id, centre);

  @override
  String toString() => 'PlacementBurst(#$id at $centre)';
}
