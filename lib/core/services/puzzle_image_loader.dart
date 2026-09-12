import 'dart:ui' as ui;

import 'package:flutter/services.dart' show AssetBundle, rootBundle;

/// Decodes puzzle artwork, once per picture (§14, §39).
///
/// Decoding belongs here rather than in a provider or a widget: one puzzle
/// image is shared by every piece of that puzzle, and it has to be disposed
/// deliberately when the puzzle changes.
class PuzzleImageLoader {
  PuzzleImageLoader({AssetBundle? bundle}) : _bundle = bundle ?? rootBundle;

  final AssetBundle _bundle;
  final Map<String, ui.Image> _cache = <String, ui.Image>{};

  /// Decodes [assetPath], or returns the copy already in memory.
  ///
  /// [cacheWidth] downsamples while decoding, so a board that is 500 px wide
  /// never holds a 1024 px bitmap it cannot show (§34).
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

    // Another caller may have finished first while we were awaiting.
    final raced = _cache[assetPath];
    if (raced != null) {
      frame.image.dispose();
      return raced;
    }
    return _cache[assetPath] = frame.image;
  }

  /// Drops one picture from memory. Safe to call for a path never loaded.
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
