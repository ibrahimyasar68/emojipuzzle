import 'dart:ui' show Offset, Path, Size;

/// Arabanın boyanabilen tek bir parçası: gövde, bir cam, bir teker (§24.2).
class CarPart {
  const CarPart({required this.id, required this.path});

  /// Model içinde tekil; kalıcılıkta bu anahtarla saklanır.
  final String id;

  /// Parçanın dış çizgisi, [CarModel.designSize] birimlerinde.
  final Path path;
}

/// Boyamaya hazır siyah çizgili bir araba (§24.2, K-7).
///
/// Görsel asset değildir; çizgileri kodda tanımlanır, böylece lisans kaydı
/// gerekmez (§33) ve her parça kendi dokunma alanını bilir. Bütün
/// koordinatlar [designSize] birimindedir; ekrana ölçeklemek çizenin işidir.
class CarModel {
  CarModel({
    required this.id,
    required this.parts,
    this.details = const [],
  }) : assert(parts.isNotEmpty, 'a car with nothing to paint');

  /// Bütün modellerin çizildiği tuval: 100 × 80 birim.
  static const Size designSize = Size(100, 80);

  final String id;

  /// Çizim sırasıyla, alttan üste. Üstteki parça alttakini örter; dokunuş
  /// da en üstteki parçaya gider.
  final List<CarPart> parts;

  /// Boyanmayan süs çizgileri (jant, kapı çizgisi). Dokunmayla ilgisi yok.
  final List<Path> details;

  CarPart? partById(String id) {
    for (final part in parts) {
      if (part.id == id) return part;
    }
    return null;
  }

  /// [point] noktasında görünen parça — üst üste binenlerden en üstteki —
  /// ya da hiçbiri.
  CarPart? partAt(Offset point) {
    for (final part in parts.reversed) {
      if (part.path.contains(point)) return part;
    }
    return null;
  }
}
