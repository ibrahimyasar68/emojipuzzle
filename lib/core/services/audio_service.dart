import 'package:flutter/foundation.dart';

import 'sound_player.dart';
import 'storage_service.dart';

/// Asset paths, relative to `assets/` the way `audioplayers` wants them.
abstract final class Sfx {
  static const String pieceSnap = 'audio/sfx/piece_snap.wav';
  static const String puzzleComplete = 'audio/sfx/puzzle_complete.wav';
  static const String balloonPop = 'audio/sfx/balloon_pop.wav';
  static const String hint = 'audio/sfx/hint.wav';
}

/// The one place that makes a sound (§27).
///
/// Widgets never create a player of their own; they ask for an effect by
/// name. That keeps the number of live players fixed, and makes muting a
/// single switch (K-2).
class AudioService extends ChangeNotifier {
  /// Without a [player] the service is silent (see [SilentSoundPlayer]).
  /// `main` gives it a real one; nothing else has to think about audio.
  AudioService({SoundPlayer? player, StorageService? storage})
      : _player = player ?? const SilentSoundPlayer(),
        _storage = storage;

  static const String mutedKey = 'emoji_puzzle.muted';

  final SoundPlayer _player;
  final StorageService? _storage;

  bool _muted = false;

  /// Silences sound effects. Haptics are not affected: they are a separate
  /// channel, and a parent silencing a phone is not asking for the buzz to
  /// stop as well (§27).
  bool get muted => _muted;

  /// Reads the saved setting. Call once at start-up.
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

  /// §22 — the short pop when a piece lands.
  Future<void> playPieceSnap() => _play(Sfx.pieceSnap);

  /// §23 — the picture is finished.
  Future<void> playPuzzleComplete() => _play(Sfx.puzzleComplete);

  /// §24 — a balloon gives up.
  Future<void> playBalloonPop() => _play(Sfx.balloonPop);

  /// §21 — "look at this one". Never a buzzer.
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
