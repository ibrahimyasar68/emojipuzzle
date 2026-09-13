/// Bir puzzle'ın ait olabileceği içerik grupları (§4).
///
/// v1'de tam olarak bu beşi var. `colors`, `numbers` ve benzerleri §47
/// kapsamındadır ve buraya gelişigüzel eklenmez: albüm kategoriye göre
/// gruplanır, yani her yeni değer çocuğun öğrendiği bir ekranı değiştirir.
enum PuzzleCategory {
  fruits,
  animals,
  vehicles,
  nature,
  shapes,
}
