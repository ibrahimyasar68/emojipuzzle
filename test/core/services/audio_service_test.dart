import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recording_sound_player.dart';

Future<StorageService> _storage(
    [Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  return StorageService.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every effect has its own sound (§27)', () async {
    final player = RecordingSoundPlayer();
    final audio = AudioService(player: player);
    addTearDown(audio.dispose);

    await audio.playPieceSnap();
    await audio.playPuzzleComplete();
    await audio.playBalloonPop();
    await audio.playHint();

    expect(player.played, [
      Sfx.pieceSnap,
      Sfx.puzzleComplete,
      Sfx.balloonPop,
      Sfx.hint,
    ]);
    expect(player.played.toSet(), hasLength(4), reason: 'no shared file');
  });

  group('mute (K-2)', () {
    test('silences everything while it is on', () async {
      final player = RecordingSoundPlayer();
      final audio = AudioService(player: player);
      addTearDown(audio.dispose);

      await audio.setMuted(muted: true);
      await audio.playPieceSnap();
      await audio.playPuzzleComplete();

      expect(player.played, isEmpty);

      await audio.setMuted(muted: false);
      await audio.playPieceSnap();

      expect(player.played, [Sfx.pieceSnap]);
    });

    test('tells listeners, so a button can follow it', () async {
      final audio = AudioService(player: RecordingSoundPlayer());
      addTearDown(audio.dispose);

      var notifications = 0;
      audio.addListener(() => notifications++);

      await audio.toggleMuted();
      expect(audio.muted, isTrue);
      await audio.setMuted(muted: true); // already muted
      await audio.toggleMuted();

      expect(audio.muted, isFalse);
      expect(notifications, 2, reason: 'only real changes are worth a rebuild');
    });

    test('survives closing the app', () async {
      final storage = await _storage();
      final first =
          AudioService(player: RecordingSoundPlayer(), storage: storage);
      await first.setMuted(muted: true);
      first.dispose();

      final second = AudioService(
        player: RecordingSoundPlayer(),
        storage: storage,
      )..loadSettings();
      addTearDown(second.dispose);

      expect(second.muted, isTrue);
    });

    test('starts unmuted when nothing was ever chosen', () async {
      final audio = AudioService(
        player: RecordingSoundPlayer(),
        storage: await _storage(),
      )..loadSettings();
      addTearDown(audio.dispose);

      expect(audio.muted, isFalse);
    });
  });

  test('a device that cannot play sound still plays the game (§27)', () async {
    final player = RecordingSoundPlayer()..failure = Exception('no audio');
    final audio = AudioService(player: player);
    addTearDown(audio.dispose);

    // The failure belongs to the player implementation; the service must
    // not turn it into something the game has to handle.
    await expectLater(audio.playPieceSnap(), throwsException);
    expect(audio.muted, isFalse);
  });

  test('disposing the service disposes the player', () async {
    final player = RecordingSoundPlayer();
    AudioService(player: player).dispose();

    expect(player.disposed, isTrue);
  });
}
