import 'package:flutter/widgets.dart';

import '../../puzzle/data/puzzle_palette.dart';
import '../../puzzle/models/puzzle_definition.dart';

/// Albümdeki tek bir çıkartma (§25).
///
/// Kazanılmış bir çıkartma, çocuğun birleştirdiği resimdir. Henüz
/// kazanılmamış olan ise aynı resmin düz gri silüetidir: bulunacak bir şey
/// olduğunu gösterir, yapılmamış olan hakkında hiçbir şey söylemez
/// (§2, §20).
class StickerTile extends StatelessWidget {
  const StickerTile({
    super.key,
    required this.puzzle,
    required this.earned,
    this.onTap,
    this.size = 96,
  });

  final PuzzleDefinition puzzle;

  /// Çocuğun bu puzzle'ı bitirip bitirmediği.
  final bool earned;

  /// Serbest Mod: kazanılmış bir çıkartmaya dokunmak o puzzle'ı yeniden
  /// oynatır (§4). Henüz bulunmamış olanlarda null — hiçbir şey olmaz ve
  /// nedeni hakkında hiçbir şey söylenmez.
  final VoidCallback? onTap;

  final double size;

  @override
  Widget build(BuildContext context) {
    final artwork = Image.asset(
      puzzle.imagePath,
      width: size * 0.78,
      height: size * 0.78,
      fit: BoxFit.contain,
      // Albüm küçük resimlerden oluşan bir ızgaradır; onları çizildikleri
      // boyutta istemek, dokuz adet 618 px'lik görseli bellekten uzak
      // tutar.
      cacheWidth: (size * 2).round(),
      filterQuality: FilterQuality.medium,
    );

    return Semantics(
      // §31 — oyunun buna hiç ihtiyacı yok, ama hangi resim olduğunu ve
      // yapılıp yapılmadığını söyleyen bir etiketin maliyeti sıfır,
      // anlamı var.
      button: onTap != null,
      label: earned
          ? '${puzzle.displayName}, tamamlandı'
          : '${puzzle.displayName}, henüz yapılmadı',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: SizedBox(
          width: size,
          height: size,
          child: DecoratedBox(
            decoration: BoxDecoration(
              // Puzzle'ın kendisinin üzerinde oynandığı gradyanın aynısı;
              // böylece çıkartma, çocuğun yaptığı resim olarak tanınır
              // (§25).
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
                      // Resimden geriye kalan her şey onun şeklidir.
                      colorFilter: const ColorFilter.mode(
                        Color(0xFFBDB5AC),
                        BlendMode.srcATop,
                      ),
                      child: Opacity(opacity: 0.55, child: artwork),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
