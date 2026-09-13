import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/audio_service.dart';
import '../core/services/sound_player.dart';
import '../core/services/storage_service.dart';
import '../features/puzzle/data/progress_repository.dart';
import '../features/home/screens/home_screen.dart';
import '../features/puzzle/providers/game_provider.dart';

/// Uygulama kabuğu.
///
/// Oyun Home'da açılır ve oradan ilerler (§29). Standart Flutter navigation,
/// router soyutlaması yok: dört ekranın buna ihtiyacı yok. Android geri tuşu
/// ve lifecycle Faz 14'te.
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
    // Provider geri çağrısının içinde değil burada kurulur; böylece
    // servisler her yeniden kurulumu atlatır ve tam olarak bir kez serbest
    // bırakılır. Gerçek sesi isteyen tek yer burası (§27).
    _audio = AudioService(
      player: AudioPlayersSoundPlayer(),
      storage: widget.storage,
    )..loadSettings();
    // Çocuk hâlâ Home'a bakarken devam ettirilir; böylece oyna'ya basınca
    // çoktan çizilmiş bir puzzle açılır (§25, §14).
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
        // Ayrıca tek başına da sunulur; Home ekranının Faz 13'te aldığı
        // ses düğmesi için (K-2).
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
