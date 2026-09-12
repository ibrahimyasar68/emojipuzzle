import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../puzzle/models/puzzle_category.dart';
import '../../puzzle/models/puzzle_definition.dart';
import '../../puzzle/providers/game_provider.dart';
import '../widgets/sticker_tile.dart';

/// Everything the child has made, grouped by category (§25).
///
/// It is also the way into Free Mode (§4): an earned sticker is a picture
/// that can be played again, shuffled afresh. The ones still to be found
/// are grey and do nothing — an album never tells a child off for a gap.
class AlbumScreen extends StatelessWidget {
  const AlbumScreen({super.key, this.onPlay});

  /// Called with a finished puzzle the child wants to play again.
  final void Function(PuzzleDefinition puzzle)? onPlay;

  /// One symbol per category, because the child cannot read the name (§2).
  static const _categoryIcons = {
    PuzzleCategory.fruits: '🍎',
    PuzzleCategory.animals: '🐾',
    PuzzleCategory.vehicles: '🚗',
    PuzzleCategory.nature: '🌿',
    PuzzleCategory.shapes: '🔵',
  };

  @override
  Widget build(BuildContext context) {
    final game = context.watch<GameProvider>();
    final grouped = game.catalog.byCategory;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EF),
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
                      icon: _categoryIcons[entry.key] ?? '⭐',
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
    required this.puzzles,
    required this.game,
    required this.onPlay,
  });

  final PuzzleCategory category;
  final String icon;
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
            child: Text(icon, style: const TextStyle(fontSize: 28)),
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

/// The only way out, and big enough for a small finger (§2).
class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('album-back'),
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        width: 64,
        height: 64,
        decoration: const BoxDecoration(
          color: Color(0xFFF3E4D0),
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: const Icon(Icons.arrow_back_rounded, size: 32),
      ),
    );
  }
}
