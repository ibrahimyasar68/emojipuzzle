import 'dart:convert';

import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<ProgressRepository> _repository([String? stored]) async {
  SharedPreferences.setMockInitialValues(
    stored == null ? const {} : {ProgressRepository.storageKey: stored},
  );
  return ProgressRepository(await StorageService.create());
}

/// A stored value with one field bent out of shape.
String _storedJson({
  Object? schemaVersion = GameProgress.currentSchemaVersion,
  Object? unlockedLevel = 2,
  Object? completedPuzzleIds = const ['apple_01', 'cat_01'],
  Object? lastPlayedPuzzleId = 'ball_01',
}) =>
    jsonEncode(<String, Object?>{
      'schemaVersion': schemaVersion,
      'unlockedLevel': unlockedLevel,
      'completedPuzzleIds': completedPuzzleIds,
      'lastPlayedPuzzleId': lastPlayedPuzzleId,
    });

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a device with nothing stored starts fresh', () async {
    final repository = await _repository();

    expect(await repository.load(), const GameProgress.initial());
  });

  test('what is saved is what comes back', () async {
    final repository = await _repository();
    final progress = const GameProgress.initial()
        .withCompleted('apple_01')
        .withCompleted('cat_01')
        .copyWith(unlockedLevel: 2);

    await repository.save(progress);

    expect(await repository.load(), progress);
  });

  test('the stored shape is one JSON object with named fields', () async {
    final repository = await _repository();
    SharedPreferences.setMockInitialValues(const {});
    final storage = await StorageService.create();
    final withStorage = ProgressRepository(storage);

    await withStorage.save(
      const GameProgress.initial().withCompleted('apple_01'),
    );
    final raw = storage.readString(ProgressRepository.storageKey);
    final decoded = jsonDecode(raw!) as Map<String, Object?>;

    expect(decoded['schemaVersion'], GameProgress.currentSchemaVersion);
    expect(decoded['completedPuzzleIds'], ['apple_01']);
    expect(decoded['lastPlayedPuzzleId'], 'apple_01');
    expect(repository, isNotNull);
  });

  test('a readable, current value loads', () async {
    final repository = await _repository(_storedJson());

    final progress = await repository.load();

    expect(progress.unlockedLevel, 2);
    expect(progress.completedPuzzleIds, {'apple_01', 'cat_01'});
    expect(progress.lastPlayedPuzzleId, 'ball_01');
  });

  group('§25.1 — an unusable value never reaches the child', () {
    test('a newer schema is left alone and the game starts fresh', () async {
      final repository = await _repository(
        _storedJson(schemaVersion: GameProgress.currentSchemaVersion + 1),
      );

      expect(await repository.load(), const GameProgress.initial());
    });

    test('an older schema with no migration starts fresh', () async {
      final repository = await _repository(_storedJson(schemaVersion: 0));

      expect(await repository.load(), const GameProgress.initial());
    });

    test('a missing schema version starts fresh', () async {
      final repository = await _repository(_storedJson(schemaVersion: null));

      expect(await repository.load(), const GameProgress.initial());
    });

    test('text that is not JSON starts fresh', () async {
      final repository = await _repository('half-written {');

      expect(await repository.load(), const GameProgress.initial());
    });

    test('JSON that is not an object starts fresh', () async {
      final repository = await _repository('[1, 2, 3]');

      expect(await repository.load(), const GameProgress.initial());
    });

    test('fields of the wrong type start fresh', () async {
      for (final broken in [
        _storedJson(unlockedLevel: 'two'),
        _storedJson(unlockedLevel: 0),
        _storedJson(completedPuzzleIds: 'apple_01'),
        _storedJson(completedPuzzleIds: [1, 2]),
        _storedJson(lastPlayedPuzzleId: 7),
      ]) {
        final repository = await _repository(broken);
        expect(
          await repository.load(),
          const GameProgress.initial(),
          reason: broken,
        );
      }
    });

    test('a null last-played puzzle is fine, not broken', () async {
      final repository = await _repository(
        _storedJson(lastPlayedPuzzleId: null),
      );

      final progress = await repository.load();

      expect(progress.lastPlayedPuzzleId, isNull);
      expect(progress.completedPuzzleIds, {'apple_01', 'cat_01'});
    });
  });

  test('clear wipes it (§26)', () async {
    final repository = await _repository(_storedJson());

    await repository.clear();

    expect(await repository.load(), const GameProgress.initial());
  });
}
