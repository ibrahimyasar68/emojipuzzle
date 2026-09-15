import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_grid.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

GameProvider _provider({int seed = 1}) => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      random: Random(seed),
    );

void _solve(GameProvider game) {
  for (final piece in [...game.pieces]) {
    game.markPlaced(piece.id);
  }
}

/// A whole stage, the way the screen plays it: solve, the reward is over,
/// and on to the next puzzle unless the game has ended.
Future<void> _playStage(GameProvider game) async {
  _solve(game);
  await game.finishStage();
  if (!game.isGameOver) await game.startNextPuzzle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a game opens on a picture at 2×2 (K-15)', () async {
    final game = _provider();
    addTearDown(game.dispose);

    await game.startNextPuzzle();

    expect(game.stage, 0);
    expect(game.carsFinished, 0);
    expect(game.grid, const PuzzleGrid(rows: 2, columns: 2));
    expect(game.pieces, hasLength(4));
    expect(game.isGameOver, isFalse);
  });

  test('the picture is chosen at random, game to game (K-15)', () async {
    final firsts = <String>{};
    for (var seed = 0; seed < 12; seed++) {
      final game = _provider(seed: seed);
      await game.startNextPuzzle();
      firsts.add(game.puzzle.id);
      game.dispose();
    }
    expect(firsts.length, greaterThanOrEqualTo(5));
  });

  test('each stage is a size bigger: 2×2, 2×3, 3×3, 4×3, 4×4', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    for (var stage = 0; stage < GameRules.stagesPerCar; stage++) {
      expect(game.stage, stage);
      expect(game.grid, GameRules.stageGrids[stage]);
      expect(game.pieces, hasLength(GameRules.stageGrids[stage].pieceCount));
      expect(game.isLastStageOfCar, stage == GameRules.stagesPerCar - 1);
      await _playStage(game);
    }
  });

  test('solving a puzzle does not end its stage: the reward comes first',
      () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    _solve(game);
    expect(game.stage, 0, reason: 'celebration, balloons and paint first');
    expect(game.progress.currentSolved, isTrue);

    await game.finishStage();
    expect(game.stage, 1);
    expect(game.progress.currentSolved, isFalse);
  });

  test('a stage moves on once, however often it is finished', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    await game.finishStage();
    expect(game.stage, 0, reason: 'nothing was solved yet');

    _solve(game);
    await game.finishStage();
    await game.finishStage();
    expect(game.stage, 1);
  });

  test('after the fifth stage the car is done, the next starts at 2×2',
      () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    for (var i = 0; i < GameRules.stagesPerCar; i++) {
      await _playStage(game);
    }

    expect(game.carsFinished, 1);
    expect(game.stage, 0);
    expect(game.grid, GameRules.stageGrids.first);
    expect(game.colouring.carIndex, 1, reason: 'the book is on the next car');
    expect(game.colouring.recentCars, hasLength(1));
  });

  test('no picture comes twice in a game, and three cars end it', () async {
    final game = _provider(seed: 5);
    addTearDown(game.dispose);
    await game.startNextPuzzle();

    final played = <String>[];
    final stages = GameRules.stagesPerCar * GameRules.carsPerGame;
    for (var i = 0; i < stages; i++) {
      expect(game.isGameOver, isFalse, reason: 'stage $i');
      played.add(game.puzzle.id);
      await _playStage(game);
    }

    expect(played, hasLength(15));
    expect(played.toSet(), hasLength(15), reason: 'a fresh picture each time');
    expect(game.isGameOver, isTrue);
    expect(game.carsFinished, GameRules.carsPerGame);
    expect(game.colouring.recentCars, hasLength(3));
  });

  test('a new game starts from the beginning and keeps the stickers', () async {
    final game = _provider(seed: 2);
    addTearDown(game.dispose);
    await game.startNextPuzzle();
    for (var i = 0; i < 15; i++) {
      await _playStage(game);
    }
    final stickers = {...game.progress.completedPuzzleIds};

    await game.startNewGame();

    expect(game.isGameOver, isFalse);
    expect(game.carsFinished, 0);
    expect(game.stage, 0);
    expect(game.grid, GameRules.stageGrids.first);
    expect(game.progress.playedThisGame, {game.puzzle.id});
    expect(game.progress.completedPuzzleIds, stickers);
    expect(
      game.colouring.carIndex,
      3,
      reason: 'the cars carry on in order: the fourth model comes next',
    );
  });

  test('a picture from the album plays at this stage\'s size (K-15)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();
    await _playStage(game);
    await _playStage(game);

    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    expect(game.stage, 2);
    expect(game.grid, const PuzzleGrid(rows: 3, columns: 3));
    expect(game.puzzle.id, 'apple_01');
  });

  test('a size can still be asked for outright', () async {
    final game = _provider();
    addTearDown(game.dispose);

    await game.startPuzzle(
      PuzzleCatalog.v1.byId('lion_01'),
      grid: const PuzzleGrid(rows: 4, columns: 4),
    );

    expect(game.pieces, hasLength(16));
    expect(game.stage, 0);
  });

  test('a sticker is earned once per picture, whatever the stage', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startPuzzle(PuzzleCatalog.v1.byId('cat_01'));
    await _playStage(game);
    expect(game.isPuzzleCompleted('cat_01'), isTrue);

    await game.startPuzzle(PuzzleCatalog.v1.byId('cat_01'));
    _solve(game);

    expect(
      game.progress.completedPuzzleIds.where((id) => id == 'cat_01'),
      hasLength(1),
    );
  });

  test('a new puzzle brings a fresh board and a full tray', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startNextPuzzle();
    _solve(game);
    expect(game.placedCount, 4);

    await game.finishStage();
    await game.startNextPuzzle();

    expect(game.placedCount, 0);
    expect(game.pieces, hasLength(6));
    for (final piece in game.pieces) {
      expect(game.stateOf(piece.id).status, PieceStatus.inTray);
    }
  });
}
