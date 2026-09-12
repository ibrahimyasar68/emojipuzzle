import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/puzzle_image_loader.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/app_state.dart';
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

GameProvider _providerMissing(Set<String> missingPaths) => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      imageLoader: PuzzleImageLoader(bundle: _PartialBundle(missingPaths)),
    );

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

  test('a puzzle whose picture is missing is skipped, silently (§14)',
      () async {
    final game = _providerMissing({'assets/images/puzzles/apple.png'});
    addTearDown(game.dispose);

    await game.startNextPuzzle();

    // apple_01 was first in line; the child simply gets cat_01 instead.
    expect(game.puzzle.id, 'cat_01');
    expect(game.appState, AppState.ready);
    expect(game.image, isNotNull);
  });

  test('a skipped puzzle unlocks nothing (§4)', () async {
    final game = _providerMissing({'assets/images/puzzles/apple.png'});
    addTearDown(game.dispose);

    await game.startNextPuzzle(); // cat_01
    for (final piece in [...game.pieces]) {
      game.markPlaced(piece.id);
    }

    // One real completion. The broken puzzle must not count as a second.
    expect(game.progress.completedPuzzleIds, {'cat_01'});
    expect(game.unlockedLevelCount, 1);
    expect(game.nextPuzzle?.id, 'ball_01');
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
    expect(game.nextPuzzle, isNull, reason: 'nothing is playable');
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
    expect(loader.isLoaded('assets/images/puzzles/apple.png'), isTrue);

    await game.startPuzzle(PuzzleCatalog.v1.byId('cat_01'));

    expect(loader.isLoaded('assets/images/puzzles/cat.png'), isTrue);
    expect(
      loader.isLoaded('assets/images/puzzles/apple.png'),
      isFalse,
      reason: 'the previous picture should not sit in memory (§42)',
    );
  });
}
