import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GameProgress', () {
    test('a new child starts at level 1 with nothing done', () {
      const progress = GameProgress.initial();

      expect(progress.unlockedLevel, 1);
      expect(progress.completedPuzzleIds, isEmpty);
      expect(progress.lastPlayedPuzzleId, isNull);
      expect(progress.schemaVersion, GameProgress.currentSchemaVersion);
    });

    test('finishing a puzzle records it and where we were', () {
      final progress = const GameProgress.initial().withCompleted('apple_01');

      expect(progress.completedPuzzleIds, {'apple_01'});
      expect(progress.isCompleted('apple_01'), isTrue);
      expect(progress.isCompleted('cat_01'), isFalse);
      expect(progress.lastPlayedPuzzleId, 'apple_01');
    });

    test('finishing the same puzzle again changes nothing (§4)', () {
      final once = const GameProgress.initial().withCompleted('apple_01');
      final twice = once.withCompleted('apple_01');

      expect(twice.completedPuzzleIds, {'apple_01'});
      expect(twice, once);
    });

    test('stickers are the completed puzzles, not a second list (§25)', () {
      final progress = const GameProgress.initial()
          .withCompleted('apple_01')
          .withCompleted('cat_01');

      expect(progress.unlockedStickerIds, progress.completedPuzzleIds);
      expect(progress.unlockedStickerIds, {'apple_01', 'cat_01'});
    });

    test('copyWith leaves the rest alone', () {
      final progress = const GameProgress.initial()
          .withCompleted('apple_01')
          .copyWith(unlockedLevel: 2);

      expect(progress.unlockedLevel, 2);
      expect(progress.completedPuzzleIds, {'apple_01'});
      expect(progress.lastPlayedPuzzleId, 'apple_01');
      expect(
          progress.copyWith(clearLastPlayed: true).lastPlayedPuzzleId, isNull);
    });

    test('value equality ignores the order things were finished in', () {
      final a = const GameProgress.initial()
          .withCompleted('apple_01')
          .withCompleted('cat_01')
          .copyWith(lastPlayedPuzzleId: 'cat_01');
      final b = const GameProgress.initial()
          .withCompleted('cat_01')
          .withCompleted('apple_01')
          .copyWith(lastPlayedPuzzleId: 'cat_01');

      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('level 0 is not a thing', () {
      int zero() => 0;
      expect(
        () => GameProgress(unlockedLevel: zero(), completedPuzzleIds: const {}),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
