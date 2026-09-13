/// Oyunun en üst düzey hazırlık durumu (§38).
enum AppState {
  /// Puzzle kuruluyor ve görseli hazırlanıyor.
  loading,

  /// Oynanabilir.
  ready,

  /// Hiçbir şey yüklenemedi. Çocuğa asla hata gösterilmez (§14); bu durum
  /// yalnızca uygulamanın sessizce geri çekilebilmesi için var.
  error,
}
