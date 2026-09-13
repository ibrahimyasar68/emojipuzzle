import 'dart:math' show Random;

/// Her parçanın hangi tepsi yuvasında başlayacağını belirler (§16.3).
///
/// Rastgelelik dışarıdan verilir; böylece bir test dizilimi sabitleyebilir
/// ve Serbest Mod aynı puzzle'ı her oturumda yeniden karıştırabilir.
class TrayShuffler {
  TrayShuffler({Random? random}) : _random = random ?? Random();

  final Random _random;

  /// Parça kimliği başına bir yuva indeksi döndürür:
  /// `result[pieceId] == slotIndex`.
  ///
  /// Sonuç `0 .. pieceCount - 1` aralığının bir permütasyonudur; yani iki
  /// parça aynı yuvayı paylaşmaz ve hiçbir yuva atlanmaz.
  List<int> assignSlots(int pieceCount) {
    assert(pieceCount > 0, 'pieceCount must be positive');
    final slots = List<int>.generate(pieceCount, (i) => i);

    // Fisher–Yates.
    for (var i = slots.length - 1; i > 0; i--) {
      final j = _random.nextInt(i + 1);
      final temp = slots[i];
      slots[i] = slots[j];
      slots[j] = temp;
    }

    return List.unmodifiable(slots);
  }
}
