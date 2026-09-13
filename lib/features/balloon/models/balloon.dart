/// Mini oyundaki tek bir balon (§24).
///
/// Hiç piksel taşımaz. Buradaki her şey bir oran ya da bir fazdır; böylece
/// aynı balon telefonda da tablette de doğru görünür ve kurallar ekransız
/// test edilebilir.
class Balloon {
  const Balloon({
    required this.id,
    required this.x,
    required this.restY,
    required this.colourIndex,
    required this.sizeFactor,
    required this.bobPhase,
    required this.bornAt,
  });

  /// Doğuş sırası, 0'dan başlar. Aynı zamanda widget anahtarıdır.
  final int id;

  /// Oyun alanı boyunca nerede durduğu, `[0, 1]`.
  final double x;

  /// Nerede durakladığı, oyun alanının üstünden itibaren `[0, 1]`.
  final double restY;

  /// Balon paletinin hangi rengini giydiği.
  final int colourIndex;

  /// Boyutta 1 civarında küçük bir çeşitlilik.
  final double sizeFactor;

  /// Salınım döngüsündeki kayma; böylece hepsi birlikte sallanmaz.
  final double bobPhase;

  /// Belirdiği andaki oyun saati; yukarı süzülme bunu kullanır.
  final Duration bornAt;

  @override
  String toString() => 'Balloon($id, x: $x, restY: $restY)';
}
