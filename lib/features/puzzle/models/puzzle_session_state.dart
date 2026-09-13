/// Şu anki puzzle oturumunun ne yaptığı (§38).
enum PuzzleSessionState {
  /// Çocuğun bir parça almasını bekliyor.
  idle,

  /// Bir parça sürükleniyor (Faz 5).
  dragging,

  /// Bir parça yerine doğru uçuyor (Faz 6).
  snapping,

  /// Bütün parçalar yerleşti (§23).
  completed,
}
