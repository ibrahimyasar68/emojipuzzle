import 'package:flutter/foundation.dart';

import 'sound_player.dart';
import 'storage_service.dart';

/// Asset yolları; `audioplayers`'ın istediği gibi `assets/`'e göreli.
abstract final class Sfx {
  static const String pieceSnap = 'audio/sfx/piece_snap.wav';
  static const String puzzleComplete = 'audio/sfx/puzzle_complete.wav';
  static const String balloonPop = 'audio/sfx/balloon_pop.wav';
  static const String hint = 'audio/sfx/hint.wav';
}

/// Ses çıkaran tek yer (§27).
///
/// Widget'lar asla kendi çalıcılarını oluşturmaz; efekti adıyla isterler.
/// Bu, canlı çalıcı sayısını sabit tutar ve sesi kapatmayı tek bir
/// anahtara indirger (K-2).
class AudioService extends ChangeNotifier {
  /// [player] verilmezse servis sessizdir (bkz. [SilentSoundPlayer]).
  /// Gerçek olanı `main` verir; başka hiçbir yerin sesi düşünmesi gerekmez.
  AudioService({SoundPlayer? player, StorageService? storage})
      : _player = player ?? const SilentSoundPlayer(),
        _storage = storage;

  static const String mutedKey = 'emoji_puzzle.muted';

  final SoundPlayer _player;
  final StorageService? _storage;

  bool _muted = false;

  /// Ses efektlerini susturur. Haptik etkilenmez: o ayrı bir kanaldır ve
  /// telefonu sessize alan bir ebeveyn titreşimin de kesilmesini istemiş
  /// olmaz (§27).
  bool get muted => _muted;

  /// Kayıtlı ayarı okur. Açılışta bir kez çağrılır.
  void loadSettings() {
    final stored = _storage?.readBool(mutedKey);
    if (stored == null || stored == _muted) return;
    _muted = stored;
    notifyListeners();
  }

  Future<void> setMuted({required bool muted}) async {
    if (_muted == muted) return;
    _muted = muted;
    notifyListeners();
    await _storage?.writeBool(mutedKey, value: muted);
  }

  Future<void> toggleMuted() => setMuted(muted: !_muted);

  /// §22 — parça yerine oturduğundaki kısa 'pop' sesi.
  Future<void> playPieceSnap() => _play(Sfx.pieceSnap);

  /// §23 — resim tamamlandı.
  Future<void> playPuzzleComplete() => _play(Sfx.puzzleComplete);

  /// §24 — bir balon pes ediyor.
  Future<void> playBalloonPop() => _play(Sfx.balloonPop);

  /// §21 — "şuna bak". Asla uyarı sesi değil.
  Future<void> playHint() => _play(Sfx.hint);

  Future<void> _play(String asset) async {
    if (_muted) return;
    await _player.play(asset);
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}
