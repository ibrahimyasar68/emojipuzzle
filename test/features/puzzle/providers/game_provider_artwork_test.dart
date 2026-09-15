import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/puzzle_image_loader.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/app_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter/foundation.dart' show FlutterError;
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A bundle where chosen assets simply are not there.
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

GameProvider _providerMissing(Set<String> missingPaths, {int seed = 1}) =>
    GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      imageLoader: PuzzleImageLoader(bundle: _PartialBundle(missingPaths)),
      random: Random(seed),
    );

const _apple = 'assets/images/puzzles/apple.png';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a puzzle with real artwork becomes playable', () async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);

    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    expect(game.appState, AppState.ready);
    expect(game.image, isNotNull);
    expect(game.image!.width, game.image!.height);
  });

  test('a picture whose artwork is missing is swapped, silently (§14)',
      () async {
    final game = _providerMissing({_apple});
    addTearDown(game.dispose);

    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    // The child simply gets another picture, at the same size.
    expect(game.puzzle.id, isNot('apple_01'));
    expect(game.grid, const PuzzleGrid(rows: 2, columns: 2));
    expect(game.appState, AppState.ready);
    expect(game.image, isNotNull);
  });

  test('a missing picture is never chosen again', () async {
    final game = _providerMissing({_apple}, seed: 3);
    addTearDown(game.dispose);
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    for (var i = 0; i < 30; i++) {
      await game.startNextPuzzle();
      expect(game.puzzle.id, isNot('apple_01'), reason: 'round $i');
    }
  });

  test('a swapped picture earns nothing (§4)', () async {
    final game = _providerMissing({_apple});
    addTearDown(game.dispose);

    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));
    final instead = game.puzzle.id;
    for (final piece in [...game.pieces]) {
      game.markPlaced(piece.id);
    }

    // One real completion. The broken picture must not count as one.
    expect(game.progress.completedPuzzleIds, {instead});
  });

  test('when nothing loads the app fails quietly, not loudly (§2, §14)',
      () async {
    final game = _providerMissing(
      PuzzleCatalog.v1.puzzles.map((p) => p.imagePath).toSet(),
    );
    addTearDown(game.dispose);

    await game.startNextPuzzle();

    expect(game.appState, AppState.error);
    expect(game.image, isNull);
  });

  test('the picture is decoded once per puzzle and released after', () async {
    final loader = PuzzleImageLoader();
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      imageLoader: loader,
    );
    addTearDown(game.dispose);

    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));
    expect(loader.isLoaded(_apple), isTrue);

    await game.startPuzzle(PuzzleCatalog.v1.byId('cat_01'));

    expect(loader.isLoaded('assets/images/puzzles/cat.png'), isTrue);
    expect(
      loader.isLoaded(_apple),
      isFalse,
      reason: 'the previous picture should not sit in memory (§42)',
    );
  });
}
