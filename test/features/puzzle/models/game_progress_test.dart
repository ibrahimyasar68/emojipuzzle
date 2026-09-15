import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameProgress', () {
    test('a new child starts a new game with nothing done (K-15)', () {
      const progress = GameProgress.initial();

      expect(progress.completedPuzzleIds, isEmpty);
      expect(progress.lastPlayedPuzzleId, isNull);
      expect(progress.stage, 0);
      expect(progress.carsFinished, 0);
      expect(progress.playedThisGame, isEmpty);
      expect(progress.currentSolved, isFalse);
      expect(progress.schemaVersion, GameProgress.currentSchemaVersion);
      expect(GameProgress.currentSchemaVersion, 2);
    });

    test('finishing a puzzle records it, and that its stage is not over yet',
        () {
      final progress = const GameProgress.initial().withCompleted('apple_01');

      expect(progress.completedPuzzleIds, {'apple_01'});
      expect(progress.isCompleted('apple_01'), isTrue);
      expect(progress.isCompleted('cat_01'), isFalse);
      expect(progress.lastPlayedPuzzleId, 'apple_01');
      expect(progress.currentSolved, isTrue);
      expect(progress.stage, 0, reason: 'the stage moves on after its reward');
    });

    test('finishing the same picture again changes nothing (§4)', () {
      final once = const GameProgress.initial().withCompleted('apple_01');
      final twice = once.withCompleted('apple_01');

      expect(twice.completedPuzzleIds, {'apple_01'});
      expect(twice, once);
    });

    test('stickers are the completed pictures, not a second list (§25)', () {
      final progress = const GameProgress.initial()
          .withCompleted('apple_01')
          .withCompleted('cat_01');

      expect(progress.unlockedStickerIds, progress.completedPuzzleIds);
      expect(progress.unlockedStickerIds, {'apple_01', 'cat_01'});
    });

    test('copyWith leaves the rest alone', () {
      final progress = const GameProgress.initial()
          .withCompleted('apple_01')
          .copyWith(stage: 3, carsFinished: 1, playedThisGame: {'apple_01'});

      expect(progress.stage, 3);
      expect(progress.carsFinished, 1);
      expect(progress.playedThisGame, {'apple_01'});
      expect(progress.completedPuzzleIds, {'apple_01'});
      expect(progress.lastPlayedPuzzleId, 'apple_01');
      expect(progress.currentSolved, isTrue);
      expect(
        progress.copyWith(clearLastPlayed: true).lastPlayedPuzzleId,
        isNull,
      );
    });

    test('value equality ignores the order things happened in', () {
      final a = const GameProgress.initial()
          .withCompleted('apple_01')
          .withCompleted('cat_01')
          .copyWith(playedThisGame: {'apple_01', 'cat_01'});
      final b = const GameProgress.initial()
          .withCompleted('cat_01')
          .withCompleted('apple_01')
          .copyWith(
        lastPlayedPuzzleId: 'cat_01',
        playedThisGame: {'cat_01', 'apple_01'},
      );

      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a.copyWith(stage: 1), isNot(b), reason: 'the stage matters');
    });

    test('negative stages and cars are not a thing', () {
      int minusOne() => -1;
      expect(
        () => GameProgress(completedPuzzleIds: const {}, stage: minusOne()),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => GameProgress(
          completedPuzzleIds: const {},
          carsFinished: minusOne(),
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
