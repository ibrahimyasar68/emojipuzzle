import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/services/audio_service.dart';
import '../../album/screens/album_screen.dart';
import '../../puzzle/models/puzzle_definition.dart';
import '../../puzzle/providers/game_provider.dart';
import '../../puzzle/screens/puzzle_screen.dart';
import '../widgets/home_button.dart';
import 'about_screen.dart';

/// Oyunun başladığı yer (§29).
///
/// Dokunulacak dört şey var, §2 beşe izin veriyor: oyna, albüm, sesi aç ya
/// da kapat ve küçük yetişkin kapısı. Çocuğun okuması gereken hiçbir yazı
/// yok.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final audio = context.watch<AudioService>();

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EF),
      body: SafeArea(
        child: Stack(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: HomeButton(
                  key: const ValueKey('home-about'),
                  icon: Icons.info_outline_rounded,
                  size: 64,
                  background: const Color(0x14000000),
                  semanticLabel: 'Ebeveynler için bilgi',
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HomeButton(
                    key: const ValueKey('home-play'),
                    icon: Icons.play_arrow_rounded,
                    size: 160,
                    background: const Color(0xFFFFC43D),
                    semanticLabel: 'Oyna',
                    onTap: () => _openPuzzle(context),
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      HomeButton(
                        key: const ValueKey('home-album'),
                        icon: Icons.photo_library_rounded,
                        semanticLabel: 'Çıkartma albümü',
                        onTap: () => _openAlbum(context),
                      ),
                      const SizedBox(width: 28),
                      HomeButton(
                        key: const ValueKey('home-mute'),
                        icon: audio.muted
                            ? Icons.volume_off_rounded
                            : Icons.volume_up_rounded,
                        semanticLabel: audio.muted ? 'Sesi aç' : 'Sesi kapat',
                        onTap: audio.toggleMuted,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openPuzzle(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const PuzzleScreen()),
    );
  }

  Future<void> _openAlbum(BuildContext context) async {
    final game = context.read<GameProvider>();
    final navigator = Navigator.of(context);

    await navigator.push(
      MaterialPageRoute<void>(
        builder: (_) => AlbumScreen(
          onPlay: (puzzle) => _replay(navigator, game, puzzle),
        ),
      ),
    );
  }

  /// Serbest Mod: albüm kapanır ve o resim yeniden başlar (§4).
  Future<void> _replay(
    NavigatorState navigator,
    GameProvider game,
    PuzzleDefinition puzzle,
  ) async {
    navigator.pop();
    await game.startPuzzle(puzzle);
    await navigator.push(
      MaterialPageRoute<void>(builder: (_) => const PuzzleScreen()),
    );
  }
}
