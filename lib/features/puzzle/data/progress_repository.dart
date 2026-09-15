import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../models/game_progress.dart';

/// Çocuğun ilerlemesini okur ve yazar (§25).
///
/// Her şey tek bir anahtarın altında tek bir JSON metnidir: on sekiz puzzle'ın
/// veritabanına ihtiyacı yoktur ve tek bir değer hiçbir zaman yarım
/// yazılamaz.
///
/// Burada hiçbir şey çağırana hata fırlatmaz. Çocuk bir depolama hatasıyla
/// bir şey yapamaz; bu yüzden en kötü durum temiz bir sayfadan başlamaktır
/// — ki bu, başarısızlık gibi değil, yeni bir oyun gibi görünür
/// (§2, §25.1).
class ProgressRepository {
  const ProgressRepository(this._storage);

  static const String storageKey = 'emoji_puzzle.progress';

  final StorageService _storage;

  /// İlerlemeyi yükler; saklanan değere güvenilemediği her durumda temiz
  /// bir başlangıca döner (§25.1).
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

  /// §26 — ilerlemeyi siler. Çocuğun ulaşabileceği hiçbir yere bağlı
  /// değildir; ebeveyn alanı kullanır.
  Future<void> clear() async {
    await _storage.remove(storageKey);
  }

  String _encode(GameProgress progress) => jsonEncode(<String, Object?>{
        'schemaVersion': progress.schemaVersion,
        'unlockedLevel': progress.unlockedLevel,
        'completedPuzzleIds': progress.completedPuzzleIds.toList(),
        'lastPlayedPuzzleId': progress.lastPlayedPuzzleId,
      });

  /// Saklanan değer okunabilir ama kullanılabilir değilse null döner;
  /// böylece çağıran temizden başlar (§25.1).
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
      // Uygulamanın daha yeni bir sürümü yazmış: bu sürüm alanların ne
      // anlama geldiğini bilemez ve tahmin etmek onları bozar (§25.1).
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

  /// Henüz daha eski bir şema yok. Olduğunda ileri taşıma işi burada
  /// yapılır; null döndürmek dürüst geri çekilmeyi korur (§25.1).
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
