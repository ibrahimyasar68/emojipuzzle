import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../models/game_progress.dart';

/// Reads and writes the child's progress (§25).
///
/// Everything is one JSON string under one key: nine puzzles do not need a
/// database, and a single value can never be half-written.
///
/// Nothing here ever throws at the caller. A child cannot act on a storage
/// error, so the worst case is starting over with a clean slate — which
/// looks like a new game, not like a failure (§2, §25.1).
class ProgressRepository {
  const ProgressRepository(this._storage);

  static const String storageKey = 'emoji_puzzle.progress';

  final StorageService _storage;

  /// Loads progress, falling back to a fresh start whenever the stored
  /// value cannot be trusted (§25.1).
  Future<GameProgress> load() async {
    final raw = _storage.readString(storageKey);
    if (raw == null) return const GameProgress.initial();

    try {
      final decoded = _decode(raw);
      if (decoded != null) return decoded;
    } on Object catch (error) {
      debugPrint('Progress could not be read ($error) — starting fresh.');
    }
    return const GameProgress.initial();
  }

  Future<void> save(GameProgress progress) async {
    await _storage.writeString(storageKey, _encode(progress));
  }

  /// §26 — wipes progress. Not wired to anything a child can reach; the
  /// parent area will use it.
  Future<void> clear() async {
    await _storage.remove(storageKey);
  }

  String _encode(GameProgress progress) => jsonEncode(<String, Object?>{
        'schemaVersion': progress.schemaVersion,
        'unlockedLevel': progress.unlockedLevel,
        'completedPuzzleIds': progress.completedPuzzleIds.toList(),
        'lastPlayedPuzzleId': progress.lastPlayedPuzzleId,
      });

  /// Returns null when the stored value is readable but not usable, so the
  /// caller starts fresh (§25.1).
  GameProgress? _decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) {
      debugPrint('Progress is not an object — starting fresh.');
      return null;
    }

    final version = decoded['schemaVersion'];
    if (version is! int) {
      debugPrint('Progress has no schema version — starting fresh.');
      return null;
    }
    if (version > GameProgress.currentSchemaVersion) {
      // Written by a newer build of the app: this one cannot know what the
      // fields mean, and guessing would corrupt them (§25.1).
      debugPrint('Progress is from a newer version ($version) — '
          'starting fresh.');
      return null;
    }
    if (version < GameProgress.currentSchemaVersion) {
      final migrated = _migrate(decoded, from: version);
      if (migrated == null) {
        debugPrint('No migration from schema $version — starting fresh.');
      }
      return migrated;
    }

    return _read(decoded);
  }

  /// No older schema exists yet. When one does, this is where it is brought
  /// forward; returning null keeps the honest fallback (§25.1).
  GameProgress? _migrate(Map<String, Object?> stored, {required int from}) =>
      null;

  GameProgress? _read(Map<String, Object?> stored) {
    final unlockedLevel = stored['unlockedLevel'];
    final completed = stored['completedPuzzleIds'];
    final lastPlayed = stored['lastPlayedPuzzleId'];

    if (unlockedLevel is! int || unlockedLevel < 1) return null;
    if (completed is! List) return null;
    if (lastPlayed != null && lastPlayed is! String) return null;

    final ids = <String>{};
    for (final id in completed) {
      if (id is! String) return null;
      ids.add(id);
    }

    return GameProgress(
      unlockedLevel: unlockedLevel,
      completedPuzzleIds: ids,
      lastPlayedPuzzleId: lastPlayed as String?,
    );
  }
}
