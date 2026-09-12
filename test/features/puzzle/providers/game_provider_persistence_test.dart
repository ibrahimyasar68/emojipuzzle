import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One device, kept across "app restarts".
late StorageService storage;

GameProvider _newSession() => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      progressRepository: ProgressRepository(storage),
    );

void _solve(GameProvider game) {
  for (final piece in [...game.pieces]) {
    game.markPlaced(piece.id);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    SharedPreferences.setMockInitialValues(const {});
    storage = await StorageService.create();
  });

  test('progress survives closing and opening the app (§25)', () async {
    final first = _newSession();
    await first.resume();
    _solve(first); // apple_01
    await first.pendingWrite;
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.isPuzzleCompleted('apple_01'), isTrue);
    expect(second.progress.completedPuzzleIds, {'apple_01'});
    second.dispose();
  });

  test('two completions keep level 2 open after a restart (§4)', () async {
    final first = _newSession();
    await first.resume();
    _solve(first); // apple_01
    await first.startNextPuzzle(); // cat_01
    _solve(first);
    await first.pendingWrite;
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.unlockedLevelCount, 2);
    expect(second.isLevelUnlocked(2), isTrue);
    second.dispose();
  });

  test('an unfinished puzzle is picked up where it was left (§25)', () async {
    final first = _newSession();
    await first.resume();
    await first.startPuzzle(PuzzleCatalog.v1.byId('cat_01'));
    first.markPlaced(0); // started, not finished
    await first.pendingWrite;
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.puzzle.id, 'cat_01');
    expect(
      second.placedCount,
      0,
      reason: 'a half-solved board is not restored, only which puzzle it was',
    );
    second.dispose();
  });

  test('a finished last puzzle hands over to the next one', () async {
    final first = _newSession();
    await first.resume();
    _solve(first); // apple_01, and it was also the last played
    await first.pendingWrite;
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.puzzle.id, 'cat_01');
    second.dispose();
  });

  test('a stored puzzle id this build no longer has is ignored', () async {
    await ProgressRepository(storage).save(
      const GameProgress.initial().copyWith(lastPlayedPuzzleId: 'dragon_99'),
    );

    final game = _newSession();
    await game.resume();

    expect(game.puzzle.id, 'apple_01');
    game.dispose();
  });

  test('a stored level more generous than the catalogue is corrected',
      () async {
    // Nothing finished, but the file claims level 3 is open.
    await ProgressRepository(storage).save(
      const GameProgress(unlockedLevel: 3, completedPuzzleIds: {}),
    );

    final game = _newSession();
    await game.resume();

    expect(game.unlockedLevelCount, 1);
    expect(game.progress.unlockedLevel, 1);
    expect(game.isLevelUnlocked(2), isFalse);
    game.dispose();
  });

  test('clearProgress wipes the device too (§26)', () async {
    final first = _newSession();
    await first.resume();
    _solve(first);
    await first.pendingWrite;

    await first.clearProgress();
    expect(first.progress, const GameProgress.initial());
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.progress.completedPuzzleIds, isEmpty);
    expect(second.progress.unlockedLevel, 1);
    // Starting a puzzle records where we are again, so the child is back at
    // the very beginning rather than at a blank slate.
    expect(second.puzzle.id, 'apple_01');
    expect(second.progress.lastPlayedPuzzleId, 'apple_01');
    second.dispose();
  });

  test('a session with no storage still plays', () async {
    final game = GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );
    addTearDown(game.dispose);

    await game.resume();
    _solve(game);
    await game.pendingWrite;

    expect(game.isPuzzleCompleted('apple_01'), isTrue);
  });
}
