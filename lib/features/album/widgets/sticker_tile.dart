import 'package:flutter/widgets.dart';

import '../../puzzle/data/puzzle_palette.dart';
import '../../puzzle/models/puzzle_definition.dart';

/// One sticker in the album (§25).
///
/// An earned sticker is the picture the child put together. One that has
/// not been earned yet is the same picture as a flat grey silhouette: it
/// shows there is something there to find, without saying anything about
/// what has not been done (§2, §20).
class StickerTile extends StatelessWidget {
  const StickerTile({
    super.key,
    required this.puzzle,
    required this.earned,
    this.onTap,
    this.size = 96,
  });

  final PuzzleDefinition puzzle;

  /// Whether the child has finished this puzzle.
  final bool earned;

  /// Free Mode: tapping an earned sticker plays that puzzle again (§4).
  /// Null on the ones still to be found — nothing happens, and nothing is
  /// said about why.
  final VoidCallback? onTap;

  final double size;

  @override
  Widget build(BuildContext context) {
    final artwork = Image.asset(
      puzzle.imagePath,
      width: size * 0.78,
      height: size * 0.78,
      fit: BoxFit.contain,
      // The album is a grid of small pictures; asking for them at the size
      // they are drawn keeps nine 618 px images off the heap.
      cacheWidth: (size * 2).round(),
      filterQuality: FilterQuality.medium,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: size,
        height: size,
        child: DecoratedBox(
          decoration: BoxDecoration(
            // The same gradient the puzzle itself was played on, so a
            // sticker is recognisably the picture the child made (§25).
            gradient: earned
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      PuzzlePalette.gradientOf(puzzle.category).$1,
                      PuzzlePalette.gradientOf(puzzle.category).$2,
                    ],
                  )
                : null,
            color: earned ? null : const Color(0x0F000000),
            borderRadius: BorderRadius.circular(size * 0.18),
          ),
          child: Center(
            child: earned
                ? artwork
                : ColorFiltered(
                    // Everything that is left of the picture is its shape.
                    colorFilter: const ColorFilter.mode(
                      Color(0xFFBDB5AC),
                      BlendMode.srcATop,
                    ),
                    child: Opacity(opacity: 0.55, child: artwork),
                  ),
          ),
        ),
      ),
    );
  }
}
