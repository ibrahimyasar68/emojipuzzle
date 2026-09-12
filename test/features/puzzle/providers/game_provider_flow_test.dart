import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_session_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

GameProvider _provider() => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );

/// Solves whatever puzzle is running, the way the screen does once every
/// piece has snapped home.
void _solveCurrentPuzzle(GameProvider game) {
  for (final piece in [...game.pieces]) {
    game.markPlaced(piece.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('the game opens on the first puzzle of the catalogue', () async {
    final game = _provider();
    addTearDown(game.dispose);

    expect(game.nextPuzzle?.id, 'apple_01');
    await game.startNextPuzzle();

    expect(game.puzzle.id, 'apple_01');
    expect(game.grid.pieceCount, 4);
    expect(game.progress.lastPlayedPuzzleId, 'apple_01');
  });

  test('finishing a puzzle records it and points at the next', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    _solveCurrentPuzzle(game);

    expect(game.sessionState, PuzzleSessionState.completed);
    expect(game.progress.completedPuzzleIds, {'apple_01'});
    expect(game.isPuzzleCompleted('apple_01'), isTrue);
    expect(game.nextPuzzle?.id, 'cat_01');
    // One puzzle is not enough to open level 2 (§4).
    expect(game.unlockedLevelCount, 1);
  });

  test('two completions open the next level (§4)', () async {
    final game = _provider();
    addTearDown(game.dispose);

    await game.startNextPuzzle(); // apple_01
    _solveCurrentPuzzle(game);
    await game.startNextPuzzle(); // cat_01
    _solveCurrentPuzzle(game);

    expect(game.unlockedLevelCount, 2);
    expect(game.isLevelUnlocked(2), isTrue);
    expect(game.isLevelUnlocked(3), isFalse);
    expect(game.progress.unlockedLevel, 2);
    expect(game.unlockedLevels.map((level) => level.index), [1, 2]);
    // The last level 1 puzzle is still the next one on the path.
    expect(game.nextPuzzle?.id, 'ball_01');
  });

  test('playing through the whole catalogue works', () async {
    final game = _provider();
    addTearDown(game.dispose);

    final played = <String>[];
    while (game.nextPuzzle != null) {
      await game.startNextPuzzle();
      played.add(game.puzzle.id);
      _solveCurrentPuzzle(game);
    }

    expect(played, PuzzleCatalog.v1.puzzles.map((p) => p.id).toList());
    expect(game.progress.completedPuzzleIds, hasLength(9));
    expect(game.unlockedLevelCount, 3);
    expect(game.nextPuzzle, isNull);
  });

  test('with nothing new left the game moves into Free Mode (§4)', () async {
    final game = _provider();
    addTearDown(game.dispose);

    while (game.nextPuzzle != null) {
      await game.startNextPuzzle();
      _solveCurrentPuzzle(game);
    }
    final last = game.puzzle.id;

    await game.startNextPuzzle();

    // This test used to assert the opposite — that the game stood still —
    // which is exactly what stranded a finished game on a blank screen.
    // Free Mode is what §4 asks for once every level is open.
    expect(game.isInFreeMode, isTrue);
    expect(game.puzzle.id, isNot(last), reason: 'a different picture');
    expect(game.progress.completedPuzzleIds, hasLength(9));
  });

  test('a new puzzle brings a fresh board and a full tray', () async {
    final game = _provider();
    addTearDown(game.dispose);

    await game.startNextPuzzle(); // apple_01, 2×2
    _solveCurrentPuzzle(game);
    expect(game.placedCount, 4);

    await game.startNextPuzzle(); // cat_01, also 2×2
    expect(game.placedCount, 0);
    expect(game.trayPieces, hasLength(4));
    expect(game.isComplete, isFalse);
    expect(game.sessionState, PuzzleSessionState.idle);
    // The finished one is still finished.
    expect(game.isPuzzleCompleted('apple_01'), isTrue);
  });

  test('a level 2 puzzle really is six pieces', () async {
    final game = _provider();
    addTearDown(game.dispose);

    await game.startPuzzle(PuzzleCatalog.v1.byId('banana_01'));

    expect(game.grid.rows, 2);
    expect(game.grid.columns, 3);
    expect(game.pieces, hasLength(6));
    expect(game.trayPieces, hasLength(6));
  });
}
