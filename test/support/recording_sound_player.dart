import 'package:emoji_puzzle_kids/core/services/sound_player.dart';

/// A player that writes down what it was asked to play instead of making a
/// noise, so a test can hear the game without a device.
class RecordingSoundPlayer implements SoundPlayer {
  final List<String> played = <String>[];
  bool disposed = false;

  /// Set to make [play] fail, the way a device with no audio would.
  Object? failure;

  @override
  Future<void> play(String assetPath) async {
    final error = failure;
    if (error != null) throw error;
    played.add(assetPath);
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
