import 'dart:ui' as ui;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Puzzle görsellerini çözer, resim başına bir kez (§14, §39).
///
/// Çözme işi provider'a ya da widget'a değil buraya aittir: bir puzzle
/// görselini o puzzle'ın bütün parçaları paylaşır ve puzzle değiştiğinde
/// bilerek serbest bırakılması gerekir.
class PuzzleImageLoader {
  PuzzleImageLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, ui.Image> _cache = <String, ui.Image>{};

  /// [assetPath]'i çözer ya da bellekteki kopyayı döndürür.
  ///
  /// [cacheWidth] çözerken küçültür; böylece 500 px genişliğindeki bir board
  /// asla gösteremeyeceği 1024 px'lik bir bitmap tutmaz (§34).
  Future<ui.Image> load(String assetPath, {int? cacheWidth}) async {
    final cached = _cache[assetPath];
    if (cached != null) return cached;

    final data = await _bundle.load(assetPath);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: cacheWidth,
    );
    final frame = await codec.getNextFrame();
    codec.dispose();

    // Biz beklerken başka bir çağıran önce bitirmiş olabilir.
    final raced = _cache[assetPath];
    if (raced != null) {
      frame.image.dispose();
      return raced;
    }
    return _cache[assetPath] = frame.image;
  }

  /// Bir resmi bellekten düşürür. Hiç yüklenmemiş bir yol için de güvenlidir.
  void evict(String assetPath) {
    _cache.remove(assetPath)?.dispose();
  }

  void evictAll() {
    for (final image in _cache.values) {
      image.dispose();
    }
    _cache.clear();
  }

  bool isLoaded(String assetPath) => _cache.containsKey(assetPath);
}
