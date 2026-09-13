/// Bir parçanın şu anda nerede olduğu (§12, §38).
enum PieceStatus {
  /// Tepsideki sabit yuvasında bekliyor (§16.2).
  inTray,

  /// Çocuğun parmağının altında (Faz 5).
  dragging,

  /// Başarılı bir bırakmanın ardından yuvasına doğru uçuyor (Faz 6).
  snapping,

  /// Yerleşti. Yerleşen parça kilitlenir, tekrar alınamaz (§10).
  placed,
}
