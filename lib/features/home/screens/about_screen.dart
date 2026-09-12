import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../puzzle/providers/game_provider.dart';
import '../widgets/home_button.dart';

/// The grown-ups' corner: attribution and the reset switch (§26, §33).
///
/// It is deliberately dull — words, no pictures, nothing that rewards a
/// child for finding it. The reset needs a long press, so the button that
/// throws away every sticker cannot be hit by accident. §2's ban on long
/// press is about what a *child* must do to play; this is the opposite of
/// that.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// The attribution OpenMoji's licence requires (§33, assets/LICENSES.md).
  static const String openMojiAttribution =
      'Emoji artwork: OpenMoji — the open-source emoji and icon project.\n'
      'Licence: CC BY-SA 4.0';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7EF),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              // A ListView stretches its children, and a stretched fixed-size
              // button ends up in the middle of the screen.
              alignment: Alignment.centerLeft,
              child: HomeButton(
                key: const ValueKey('about-back'),
                icon: Icons.arrow_back_rounded,
                size: 64,
                background: const Color(0x14000000),
                semanticLabel: 'Geri',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Emoji Puzzle Kids',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            const Text(
              'Görseller',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              openMojiAttribution,
              key: ValueKey('about-attribution'),
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 6),
            const Text(
              'openmoji.org',
              style: TextStyle(fontSize: 13, color: Color(0xFF7A6F65)),
            ),
            const SizedBox(height: 20),
            const Text(
              'Sesler',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Uygulamanın kendi ürettiği ses efektleri. Lisans gerekmez.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'Gizlilik',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Reklam yok, satın alma yok, hesap yok. Uygulama hiçbir veri '
              'toplamaz ve internete bağlanmaz. İlerleme yalnızca bu cihazda '
              'saklanır.',
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 32),
            const _ResetTile(),
          ],
        ),
      ),
    );
  }
}

/// §26 — throws away every sticker. Held down, not tapped.
class _ResetTile extends StatefulWidget {
  const _ResetTile();

  @override
  State<_ResetTile> createState() => _ResetTileState();
}

class _ResetTileState extends State<_ResetTile> {
  bool _done = false;

  Future<void> _reset() async {
    final game = context.read<GameProvider>();
    await game.clearProgress();
    if (!mounted) return;
    setState(() => _done = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İlerlemeyi sıfırla',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        const Text(
          'Tüm çıkartmalar silinir ve oyun baştan başlar. Yanlışlıkla '
          'basılmasın diye düğmeyi basılı tutmanız gerekir.',
          style: TextStyle(fontSize: 14, height: 1.4),
        ),
        const SizedBox(height: 12),
        Semantics(
          button: true,
          label: 'İlerlemeyi sıfırlamak için basılı tutun',
          child: GestureDetector(
            key: const ValueKey('about-reset'),
            behavior: HitTestBehavior.opaque,
            onLongPress: _done ? null : _reset,
            child: Container(
              height: 64,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0x14000000),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                _done ? 'Sıfırlandı' : 'Basılı tutun',
                style: const TextStyle(fontSize: 15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
