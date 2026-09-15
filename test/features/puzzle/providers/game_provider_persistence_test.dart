import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/app_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// One device, kept across "app restarts".
late StorageService storage;

GameProvider _newSession({int seed = 1}) => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      progressRepository: ProgressRepository(storage),
      random: Random(seed),
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

  test('a finished stage survives closing and opening the app (§25)', () async {
    final first = _newSession();
    await first.resume();
    final solved = first.puzzle.id;
    _solve(first);
    await first.finishStage();
    await first.pendingWrite;
    first.dispose();

    final second = _newSession(seed: 2);
    await second.resume();

    expect(second.isPuzzleCompleted(solved), isTrue);
    expect(second.stage, 1);
    expect(second.grid, GameRules.stageGrids[1]);
    second.dispose();
  });

  test('an unfinished puzzle is picked up where it was left (§25)', () async {
    final first = _newSession();
    await first.resume();
    _solve(first);
    await first.finishStage();
    await first.startNextPuzzle();
    final halfway = first.puzzle.id;
    first.markPlaced(0); // started, not finished
    await first.pendingWrite;
    first.dispose();

    final second = _newSession(seed: 9);
    await second.resume();

    expect(second.puzzle.id, halfway, reason: 'the same picture');
    expect(second.grid, GameRules.stageGrids[1], reason: 'at the same stage');
    expect(
      second.placedCount,
      0,
      reason: 'a half-solved board is not restored, only which puzzle it was',
    );
    second.dispose();
  });

  test('a puzzle solved but not yet rewarded moves its stage on (K-15)',
      () async {
    final first = _newSession();
    await first.resume();
    final solved = first.puzzle.id;
    _solve(first); // the app is closed during the celebration
    await first.pendingWrite;
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.stage, 1, reason: 'no going back to a solved board');
    expect(second.puzzle.id, isNot(solved));
    expect(second.progress.currentSolved, isFalse);
    expect(second.appState, AppState.ready);
    second.dispose();
  });

  test('a game left at its end opens as a new game', () async {
    await ProgressRepository(storage).save(
      const GameProgress(
        completedPuzzleIds: {'apple_01'},
        carsFinished: GameRules.carsPerGame,
      ),
    );

    final game = _newSession();
    await game.resume();

    expect(game.isGameOver, isFalse);
    expect(game.carsFinished, 0);
    expect(game.stage, 0);
    expect(game.progress.completedPuzzleIds, {'apple_01'});
    game.dispose();
  });

  test('a stored picture this build no longer has is ignored', () async {
    await ProgressRepository(storage).save(
      const GameProgress.initial().copyWith(lastPlayedPuzzleId: 'dragon_99'),
    );

    final game = _newSession();
    await game.resume();

    expect(game.appState, AppState.ready);
    expect(PuzzleCatalog.v1.findById(game.puzzle.id), isNotNull);
    game.dispose();
  });

  test('a stored stage beyond these rules starts the car again', () async {
    await ProgressRepository(storage).save(
      const GameProgress(completedPuzzleIds: {}, stage: 9),
    );

    final game = _newSession();
    await game.resume();

    expect(game.stage, 0);
    expect(game.grid, GameRules.stageGrids.first);
    game.dispose();
  });

  test('clearProgress wipes the device too (§26)', () async {
    final first = _newSession();
    await first.resume();
    _solve(first);
    await first.finishStage();
    await first.pendingWrite;

    await first.clearProgress();
    expect(first.progress, const GameProgress.initial());
    first.dispose();

    final second = _newSession();
    await second.resume();

    expect(second.progress.completedPuzzleIds, isEmpty);
    expect(second.stage, 0);
    expect(second.progress.lastPlayedPuzzleId, second.puzzle.id);
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

    expect(game.isPuzzleCompleted(game.puzzle.id), isTrue);
  });
}
