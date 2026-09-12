import 'package:emoji_puzzle_kids/core/services/puzzle_image_loader.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _apple = 'assets/images/puzzles/apple.png';

/// Lets a test say "this one file is missing" while every other asset keeps
/// loading for real.
class _PartialBundle extends CachingAssetBundle {
  _PartialBundle(this.missing);

  final Set<String> missing;

  @override
  Future<ByteData> load(String key) {
    if (missing.contains(key)) {
      throw FlutterError('asset not found: $key');
    }
    return rootBundle.load(key);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('decodes a real catalogue asset', () async {
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);

    final image = await loader.load(_apple);

    expect(image.width, greaterThan(0));
    expect(image.height, image.width, reason: 'the artwork is 1:1 (§34)');
    expect(loader.isLoaded(_apple), isTrue);
  });

  test('every puzzle in the catalogue has a picture that loads', () async {
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);

    for (final puzzle in PuzzleCatalog.v1.puzzles) {
      final image = await loader.load(puzzle.imagePath);
      expect(image.width, image.height, reason: puzzle.id);
    }
  });

  test('decodes once and shares the picture (§14)', () async {
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);

    final first = await loader.load(_apple);
    final second = await loader.load(_apple);

    expect(identical(first, second), isTrue);
  });

  test('cacheWidth decodes smaller (§34)', () async {
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);

    final image = await loader.load(_apple, cacheWidth: 128);

    expect(image.width, 128);
  });

  test('evict forgets one picture, and is safe for unknown paths', () async {
    final loader = PuzzleImageLoader();
    addTearDown(loader.evictAll);

    await loader.load(_apple);
    loader.evict(_apple);

    expect(loader.isLoaded(_apple), isFalse);
    expect(
        () => loader.evict('assets/images/puzzles/nope.png'), returnsNormally);
  });

  test('a missing asset throws instead of returning something broken', () {
    final loader = PuzzleImageLoader(bundle: _PartialBundle({_apple}));
    addTearDown(loader.evictAll);

    expect(loader.load(_apple), throwsA(isA<FlutterError>()));
  });
}
