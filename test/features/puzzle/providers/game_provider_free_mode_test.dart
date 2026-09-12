import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/app_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

GameProvider _provider({ProgressRepository? repository}) => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      progressRepository: repository,
    );

void _solveCurrentPuzzle(GameProvider game) {
  for (final piece in [...game.pieces]) {
    game.markPlaced(piece.id);
  }
}

/// Plays the whole catalogue through, the way a child eventually would.
Future<void> _finishEverything(GameProvider game) async {
  for (var i = 0; i < 20 && game.nextPuzzle != null; i++) {
    await game.startNextPuzzle();
    _solveCurrentPuzzle(game);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('finishing everything leads into Free Mode, not a blank screen (§4)',
      () async {
    final game = _provider();
    addTearDown(game.dispose);

    await _finishEverything(game);

    expect(game.progress.completedPuzzleIds, hasLength(9));
    expect(game.nextPuzzle, isNull, reason: 'nothing new is left');
    expect(game.isInFreeMode, isTrue);

    // The moment that used to strand the app on an empty screen.
    await game.startNextPuzzle();

    expect(game.appState, AppState.ready);
    expect(game.pieces, isNotEmpty);
  });

  test('Free Mode walks the album instead of repeating one picture (§4)',
      () async {
    final game = _provider();
    addTearDown(game.dispose);
    await _finishEverything(game);

    final played = <String>[];
    for (var i = 0; i < 4; i++) {
      await game.startNextPuzzle();
      played.add(game.puzzle.id);
    }

    expect(played.toSet(), hasLength(4), reason: 'four different pictures');
    expect(played.first, isNot(game.progress.lastPlayedPuzzleId));
  });

  test('replaying does not change what has been earned (§4)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await _finishEverything(game);

    final before = game.progress.completedPuzzleIds;
    final levelBefore = game.progress.unlockedLevel;

    await game.startNextPuzzle();
    _solveCurrentPuzzle(game);

    expect(game.progress.completedPuzzleIds, before);
    expect(game.progress.unlockedLevel, levelBefore);
    expect(game.isInFreeMode, isTrue, reason: 'still nothing new to find');
  });

  test('the pieces are shuffled again on every replay (§16)', () async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      // No seed: a replay is a new arrangement, like tipping the box out.
      shuffler: TrayShuffler(),
    );
    addTearDown(game.dispose);
    await _finishEverything(game);

    final arrangements = <String>{};
    for (var i = 0; i < 8; i++) {
      await game.startPuzzle(PuzzleCatalog.v1.byId('lion_01'));
      arrangements.add(
        game.pieces.map((p) => game.stateOf(p.id).traySlotIndex).join(','),
      );
    }

    expect(
      arrangements.length,
      greaterThan(1),
      reason: 'nine pieces have plenty of arrangements; eight identical '
          'shuffles would mean the tray is not being reshuffled',
    );
  });

  test('replayable puzzles are exactly the stickers earned (§25)', () async {
    final game = _provider();
    addTearDown(game.dispose);

    expect(game.replayablePuzzles, isEmpty);
    expect(game.isInFreeMode, isFalse, reason: 'there is plenty left to do');

    await game.startNextPuzzle();
    _solveCurrentPuzzle(game);

    expect(game.replayablePuzzles.map((p) => p.id), ['apple_01']);
    expect(
      game.replayablePuzzles.map((p) => p.id).toSet(),
      game.progress.unlockedStickerIds,
    );
  });

  test('a finished game comes back in Free Mode after a restart (§25)',
      () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await StorageService.create();
    final repository = ProgressRepository(storage);

    final first = _provider(repository: repository);
    await _finishEverything(first);
    await first.pendingWrite;
    first.dispose();

    final second = _provider(repository: repository);
    addTearDown(second.dispose);
    await second.resume();

    expect(second.isInFreeMode, isTrue);
    expect(second.appState, AppState.ready, reason: 'not a blank screen');
    expect(second.pieces, isNotEmpty);
  });
}
