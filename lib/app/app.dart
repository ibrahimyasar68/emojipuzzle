import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/audio_service.dart';
import '../core/services/sound_player.dart';
import '../core/services/storage_service.dart';
import '../features/puzzle/data/progress_repository.dart';
import '../features/home/screens/home_screen.dart';
import '../features/puzzle/providers/game_provider.dart';

/// App shell.
///
/// The game opens on Home and pushes from there (§29). Standard Flutter
/// navigation, no router abstraction: four screens do not need one. Android
/// Back and the lifecycle are Faz 14.
class EmojiPuzzleApp extends StatefulWidget {
  const EmojiPuzzleApp({super.key, required this.storage});

  final StorageService storage;

  @override
  State<EmojiPuzzleApp> createState() => _EmojiPuzzleAppState();
}

class _EmojiPuzzleAppState extends State<EmojiPuzzleApp> {
  late final AudioService _audio;
  late final GameProvider _game;

  @override
  void initState() {
    super.initState();
    // Built here, not inside a provider callback, so the services outlive
    // any rebuild and are disposed exactly once.
    // The one place that asks for real sound (§27).
    _audio = AudioService(
      player: AudioPlayersSoundPlayer(),
      storage: widget.storage,
    )..loadSettings();
    // Resumed while the child is still looking at Home, so pressing play
    // opens a puzzle that is already painted (§25, §14).
    _game = GameProvider(
      progressRepository: ProgressRepository(widget.storage),
      audio: _audio,
    )..resume();
  }

  @override
  void dispose() {
    _game.dispose();
    _audio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Exposed on its own as well, for the mute toggle the Home screen
        // gets in Faz 13 (K-2).
        ChangeNotifierProvider<AudioService>.value(value: _audio),
        ChangeNotifierProvider<GameProvider>.value(value: _game),
      ],
      child: const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeScreen(),
      ),
    );
  }
}
