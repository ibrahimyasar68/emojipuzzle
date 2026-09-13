/// Oyunun yardımı ne kadar yüksek sesle önerdiği (§21).
///
/// Merdiven yalnızca çocuk hiçbir şey yapmazken tırmanır ve herhangi bir
/// dokunuş onu [none]'a geri gönderir. Buradaki hiçbir şey çocuğa bir şeye
/// mal olmaz: ipucu bir tekliftir, asla bir düzeltme değil (§20).
enum HintStage {
  /// Çocuk oynuyor. Hiçbir şey söyleme.
  none,

  /// 8 sn — en kolay yerleşecek parça iki kez nabız atar.
  pulsePiece,

  /// 16 sn — parça ve ait olduğu yuva birlikte nabız atar.
  pulseBoth,

  /// 24 sn — parçanın hayaleti tepsiden yuvaya doğru süzülür.
  ghostMove,

  /// 32 sn — oyun parçayı kendisi yerleştirir ve sessizlikten başlar.
  autoPlace,
}
