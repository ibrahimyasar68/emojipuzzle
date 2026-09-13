import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/services/audio_service.dart';
import '../core/services/sound_player.dart';
import '../core/services/storage_service.dart';
import '../core/theme/theme_settings.dart';
import '../features/puzzle/data/progress_repository.dart';
import '../features/home/screens/home_screen.dart';
import '../features/puzzle/providers/game_provider.dart';
import 'themed_app.dart';

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
  late final ThemeSettings _theme;

  @override
  void initState() {
    super.initState();
    // İlk kare çizilmeden okunur; yoksa kayıtlı tema bir an yanlış renkte
    // açılırdı.
    _theme = ThemeSettings(storage: widget.storage)..load();
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
    _theme.dispose();
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
        ChangeNotifierProvider<ThemeSettings>.value(value: _theme),
      ],
      child: const ThemedApp(home: HomeScreen()),
    );
  }
}
