import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../puzzle/models/puzzle_category.dart';
import '../../puzzle/models/puzzle_definition.dart';
import '../../puzzle/providers/game_provider.dart';
import '../widgets/sticker_tile.dart';

/// Çocuğun yaptığı her şey, kategorilere göre gruplanmış (§25).
///
/// Aynı zamanda Serbest Mod'un kapısıdır (§4): kazanılmış bir çıkartma,
/// yeniden karıştırılıp tekrar oynanabilecek bir resimdir. Henüz
/// bulunmamış olanlar gridir ve hiçbir şey yapmaz — albüm bir çocuğu
/// eksiği için asla azarlamaz.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, this.onPlay});

  /// Çocuğun yeniden oynamak istediği, bitirilmiş bir puzzle ile çağrılır.
  final void Function(PuzzleDefinition puzzle)? onPlay;

  /// Kategori başına bir simge, çünkü çocuk adı okuyamaz (§2).
  ///
  /// Emoji karakteri değil, Flutter'ın birlikte getirdiği fonttan ikonlar:
  /// §33 platformun kendi emoji glyph'lerinden bir şey çizmeyi yasaklar ve
  /// gerekçe burada da görseller için olduğu kadar geçerlidir — bir glyph
  /// her cihazda farklı görünür, bazılarında hiç yoktur.
  static const _categoryIcons = {
    PuzzleCategory.fruits: Icons.local_dining_rounded,
    PuzzleCategory.animals: Icons.pets_rounded,
    PuzzleCategory.vehicles: Icons.directions_car_rounded,
    PuzzleCategory.nature: Icons.wb_sunny_rounded,
    PuzzleCategory.shapes: Icons.circle_rounded,
    PuzzleCategory.objects: Icons.category_rounded,
  };

  /// Ekran okuyucu tarafından seslendirilir; hiç gösterilmez (§2, §31).
  static const _categoryNames = {
    PuzzleCategory.fruits: 'Meyveler',
    PuzzleCategory.animals: 'Hayvanlar',
    PuzzleCategory.vehicles: 'Taşıtlar',
    PuzzleCategory.nature: 'Doğa',
    PuzzleCategory.shapes: 'Şekiller',
    PuzzleCategory.objects: 'Eşyalar',
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final grouped = game.catalog.byCategory;

    return Scaffold(
      backgroundColor: context.palette.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: _BackButton(onTap: () => Navigator.of(context).pop()),
            ),
            Expanded(
              child: ListView(
                key: const ValueKey('album-list'),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                children: [
                  for (final entry in grouped.entries)
                    _CategorySection(
                      category: entry.key,
                      icon: _categoryIcons[entry.key] ?? Icons.star_rounded,
                      name: _categoryNames[entry.key] ?? '',
                      puzzles: entry.value,
                      game: game,
                      onPlay: onPlay,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  const _CategorySection({
    required this.category,
    required this.icon,
    required this.name,
    required this.puzzles,
    required this.game,
    required this.onPlay,
  });

  final PuzzleCategory category;
  final IconData icon;
  final String name;
  final List<PuzzleDefinition> puzzles;
  final GameProvider game;
  final void Function(PuzzleDefinition puzzle)? onPlay;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Semantics(
              header: true,
              label: name,
              child: Icon(
                icon,
                size: 28,
                color: context.palette.onBackgroundMuted,
              ),
            ),
          ),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final puzzle in puzzles)
                Builder(
                  builder: (context) {
                    final earned = game.isPuzzleCompleted(puzzle.id);
                    return StickerTile(
                      key: ValueKey('sticker-${puzzle.id}'),
                      puzzle: puzzle,
                      earned: earned,
                      onTap: earned && onPlay != null
                          ? () => onPlay!(puzzle)
                          : null,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Tek çıkış yolu ve küçük bir parmak için yeterince büyük (§2).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return GestureDetector(
      key: const ValueKey('album-back'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: palette.button,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        // Koyu temada varsayılan ikon rengi açık; krem düğmenin üstünde
        // kaybolurdu. Düğme iki temada da krem.
        child: Icon(
          Icons.arrow_back_rounded,
          size: 32,
          color: palette.onButton,
        ),
      ),
    );
  }
}
