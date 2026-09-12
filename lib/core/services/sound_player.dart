import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Plays one short sound. The seam between the game and the audio plugin.
///
/// Two implementations exist for a reason: the real one talks to the
/// platform, and tests need to hear what was played without a device.
abstract interface class SoundPlayer {
  Future<void> play(String assetPath);
  Future<void> dispose();
}

/// Makes no sound at all.
///
/// This is the default, and deliberately so: the audio plugin fails
/// *asynchronously* when it is not there — out of reach of any try/catch
/// around the call — so code that has not been given a real player must not
/// reach for one. The app hands the real player in at start-up; everything
/// else, tests included, stays quiet and keeps working.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> play(String assetPath) async {}

  @override
  Future<void> dispose() async {}
}

/// The real thing, on top of `audioplayers` (§27, §37).
///
/// One player per sound, so a piece snapping while the finishing tune is
/// still ringing does not cut it off (§22).
class AudioPlayersSoundPlayer implements SoundPlayer {
  final Map<String, AudioPlayer> _players = <String, AudioPlayer>{};
  bool _warned = false;

  @override
  Future<void> play(String assetPath) async {
    try {
      final player = _players.putIfAbsent(
        assetPath,
        () =>
            AudioPlayer(playerId: assetPath)..setReleaseMode(ReleaseMode.stop),
      );
      await player.stop();
      await player.play(AssetSource(assetPath));
    } on Object catch (error) {
      // A device with no audio, or a test without the plugin, must not stop
      // a child from playing (§27).
      if (!_warned) {
        _warned = true;
        debugPrint('Sound is unavailable ($error); playing on in silence.');
      }
    }
  }

  @override
  Future<void> dispose() async {
    for (final player in _players.values) {
      try {
        await player.dispose();
      } on Object catch (_) {
        // Nothing useful to do while shutting down.
      }
    }
    _players.clear();
  }
}
