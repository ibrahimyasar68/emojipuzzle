/// Bir puzzle'ın ait olabileceği içerik grupları (§4).
///
/// v1 beşle başladı; K-14 ile altıncısı [objects] geldi (kitap, mikroskop,
/// dürbün — hiçbiri öbür beşine uymuyordu). `colors`, `numbers` ve
/// benzerleri §47 kapsamındadır ve buraya gelişigüzel eklenmez: albüm
/// kategoriye göre gruplanır, yani her yeni değer çocuğun öğrendiği bir
/// ekranı değiştirir.
enum PuzzleCategory {
  fruits,
  animals,
  vehicles,
  nature,
  shapes,

  /// Eşyalar (K-14).
  objects,
}
