import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/puzzle_config.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../album/screens/album_screen.dart';
import '../../puzzle/models/puzzle_definition.dart';
import '../../puzzle/providers/game_provider.dart';
import '../../puzzle/screens/puzzle_screen.dart';
import '../widgets/home_button.dart';
import '../widgets/play_puzzle_button.dart';
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
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
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
                  background: palette.subtleSurface,
                  foreground: palette.onSubtleSurface,
                  semanticLabel: 'Ebeveynler için bilgi',
                  // Yetişkin kapısı (K-21, kullanıcı istedi): iki saniye
                  // basılı tutmak gerekir. Üç yaşındaki bir çocuk bunu
                  // kazara yapmaz; tutarken dolan halka yetişkine ne kadar
                  // kaldığını söyler.
                  holdDuration: PuzzleConfig.homeAboutHoldDuration,
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AboutScreen(),
                    ),
                  ),
                ),
              ),
            ),
            // Board gibi Home da ekranla büyür, ama bir tavana kadar (§40).
            LayoutBuilder(
              builder: (context, constraints) {
                final scale = (constraints.biggest.shortestSide /
                        PuzzleConfig.homeReferenceShortSide)
                    .clamp(1.0, PuzzleConfig.homeMaxScale);
                final buttonSize = PuzzleConfig.homeButtonSize * scale;

                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PlayPuzzleButton(
                        key: const ValueKey('home-play'),
                        size: PuzzleConfig.homePlayButtonSize * scale,
                        onTap: () => _openPuzzle(context),
                      ),
                      SizedBox(height: PuzzleConfig.homePlayButtonGap * scale),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          HomeButton(
                            key: const ValueKey('home-album'),
                            icon: Icons.photo_library_rounded,
                            size: buttonSize,
                            semanticLabel: 'Çıkartma albümü',
                            onTap: () => _openAlbum(context),
                          ),
                          SizedBox(width: PuzzleConfig.homeButtonGap * scale),
                          HomeButton(
                            key: const ValueKey('home-mute'),
                            icon: audio.muted
                                ? Icons.volume_off_rounded
                                : Icons.volume_up_rounded,
                            size: buttonSize,
                            semanticLabel:
                                audio.muted ? 'Sesi aç' : 'Sesi kapat',
                            onTap: audio.toggleMuted,
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
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

  /// Albümden yeniden oynama: albüm kapanır ve o resim, o anki safhanın
  /// ebadıyla yeniden başlar (§4, K-15).
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
