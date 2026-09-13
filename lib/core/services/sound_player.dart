import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Tek bir kısa sesi çalar. Oyun ile ses eklentisi arasındaki dikiş.
///
/// İki uygulaması olmasının sebebi var: gerçek olan platformla konuşur,
/// testler ise cihaz olmadan neyin çalındığını duymak zorundadır.
abstract interface class SoundPlayer {
  Future<void> play(String assetPath);
  Future<void> dispose();
}

/// Hiç ses çıkarmaz.
///
/// Varsayılan budur ve bu bilinçli bir tercihtir: ses eklentisi yokken hata
/// *asenkron* fırlatılır — çağrıyı saran hiçbir try/catch'in erişemeyeceği
/// yerde — bu yüzden kendisine gerçek bir çalıcı verilmemiş kod gidip bir
/// tane aramamalıdır. Gerçek çalıcıyı açılışta uygulama verir; testler dahil
/// geri kalan her şey sessiz kalır ve çalışmaya devam eder.
class SilentSoundPlayer implements SoundPlayer {
  const SilentSoundPlayer();

  @override
  Future<void> play(String assetPath) async {}

  @override
  Future<void> dispose() async {}
}

/// Gerçek olanı, `audioplayers` üzerine kurulu (§27, §37).
///
/// Ses başına bir çalıcı; böylece bitiş ezgisi hâlâ çalarken yerine oturan
/// bir parça onu kesmez (§22).
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
      // Sesi olmayan bir cihaz ya da eklentisi olmayan bir test, çocuğun
      // oynamasını engellememelidir (§27).
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
        // Kapanırken yapılacak yararlı bir şey yok.
      }
    }
    _players.clear();
  }
}
