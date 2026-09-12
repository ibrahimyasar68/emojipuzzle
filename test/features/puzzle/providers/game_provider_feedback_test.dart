import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../support/recording_sound_player.dart';

late RecordingSoundPlayer player;
late AudioService audio;

GameProvider _provider() => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      audio: audio,
    );

List<String> _listenForHaptics() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      calls.add(call.arguments as String? ?? 'default');
    }
    return null;
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    player = RecordingSoundPlayer();
    audio = AudioService(player: player);
  });

  tearDown(() => audio.dispose());

  test('a piece landing pops and taps (§22)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    final haptics = _listenForHaptics();
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    game.markPlaced(0);
    await Future<void>.delayed(Duration.zero);

    expect(player.played, [Sfx.pieceSnap]);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
  });

  test('the last piece plays the finishing phrase instead (§23)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    final haptics = _listenForHaptics();
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    for (final piece in [...game.pieces]) {
      game.markPlaced(piece.id);
    }
    await Future<void>.delayed(Duration.zero);

    expect(player.played.last, Sfx.puzzleComplete);
    expect(
      player.played.where((sound) => sound == Sfx.puzzleComplete),
      hasLength(1),
    );
    expect(
      player.played.where((sound) => sound == Sfx.pieceSnap),
      hasLength(3),
      reason: 'three pops, then the phrase — not four sounds at the end',
    );
    expect(haptics.last, 'HapticFeedbackType.mediumImpact');
  });

  test('picking a piece up is felt, not heard (§17)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    final haptics = _listenForHaptics();
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    game.beginDrag(0);
    await Future<void>.delayed(Duration.zero);

    expect(haptics, ['HapticFeedbackType.selectionClick']);
    expect(player.played, isEmpty);
  });

  test('a missed drop stays silent (§20)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));

    game
      ..beginDrag(0)
      ..dropFailed(0);
    await Future<void>.delayed(Duration.zero);

    expect(player.played, isEmpty, reason: 'no buzzer, ever');
  });

  test('muting silences sound but keeps the taps (§27)', () async {
    final game = _provider();
    addTearDown(game.dispose);
    final haptics = _listenForHaptics();
    await game.startPuzzle(PuzzleCatalog.v1.byId('apple_01'));
    await audio.setMuted(muted: true);

    game.markPlaced(0);
    await Future<void>.delayed(Duration.zero);

    expect(player.played, isEmpty);
    expect(haptics, contains('HapticFeedbackType.lightImpact'));
  });

  test('the provider exposes its audio, for the mute button (K-2)', () async {
    final game = _provider();
    addTearDown(game.dispose);

    expect(identical(game.audio, audio), isTrue);
  });
}
