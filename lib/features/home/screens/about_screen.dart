import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/theme_settings.dart';
import '../../puzzle/providers/game_provider.dart';
import '../widgets/home_button.dart';

/// Yetişkinlerin köşesi: görünüm seçimi, attribution ve sıfırlama anahtarı
/// (§26, §33).
///
/// Bilerek sıkıcıdır — yazı var, resim yok, çocuğu burayı bulduğu için
/// ödüllendiren hiçbir şey yok. Sıfırlama basılı tutmayı gerektirir;
/// böylece bütün çıkartmaları çöpe atan düğmeye yanlışlıkla basılamaz.
/// §2'nin uzun basma yasağı, *çocuğun* oynamak için yapmak zorunda olduğu
/// şeylerle ilgilidir; bu ise onun tam tersidir.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  /// Yapımcı ve iletişim (K-21, kullanıcı istedi). Mağaza sayfasındaki
  /// adresle aynıdır; uygulamadan dışarı bir bağlantı açılmaz (§35), yazı
  /// olarak durur.
  static const String maker = 'IY Labs';
  static const String contactEmail = 'ibrahimyasar68@hotmail.com';

  /// OpenMoji lisansının gerektirdiği attribution (§33, assets/LICENSES.md).
  static const String openMojiAttribution =
      'Emoji artwork: OpenMoji — the open-source emoji and icon project.\n'
      'Licence: CC BY-SA 4.0';

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;

    return Scaffold(
      backgroundColor: palette.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Align(
              // ListView çocuklarını gerer ve gerilmiş sabit boyutlu bir
              // düğme ekranın ortasında kalır.
              alignment: Alignment.centerLeft,
              child: HomeButton(
                key: const ValueKey('about-back'),
                icon: Icons.arrow_back_rounded,
                size: 64,
                background: palette.subtleSurface,
                foreground: palette.onSubtleSurface,
                semanticLabel: 'Geri',
                onTap: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'EmojiPuzzle',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              'IY Labs',
              key: const ValueKey('about-maker'),
              style: TextStyle(
                fontSize: 14,
                color: palette.onBackgroundMuted,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              // K-21 — kullanıcı bu köşede oyunun kısa bir tarifini istedi.
              'Okuma yazma bilmeyen çocuklar için sakin bir yapboz oyunu. '
              'Yapbozlar dört parçadan başlar, on altı parçaya kadar büyür; '
              'resimler her oyunda havuzdan rastgele gelir. Yanlış konan '
              'parça yumuşakça yerine döner: kaybedilmez, süre ve puan '
              'yoktur. Her biten resim konfeti, balon oyunu ve albüme giren '
              'bir çıkartma demektir; ardından bir arabanın bir parçası '
              'boyanır.',
              key: ValueKey('about-summary'),
              style: TextStyle(fontSize: 14, height: 1.4),
            ),
            const SizedBox(height: 20),
            const Text(
              'İletişim',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              AboutScreen.contactEmail,
              key: ValueKey('about-contact'),
              style: TextStyle(fontSize: 14, height: 1.4),
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
            Text(
              'openmoji.org',
              style: TextStyle(
                fontSize: 13,
                color: palette.onBackgroundMuted,
              ),
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
            const SizedBox(height: 20),
            const Text(
              'Görünüm',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            const _AppearancePicker(),
            const SizedBox(height: 32),
            const _ResetTile(),
          ],
        ),
      ),
    );
  }
}

/// Görünüm: telefonun ayarı, açık ya da koyu.
///
/// Burada, yetişkin köşesinde durur: Home'da §2'nin beş dokunulabilir öğe
/// sınırına bir öğe daha eklerdi ve çocuğun bununla bir işi yok. Seçimin
/// hepsi ikon ve yazıyla birlikte (§2).
class _AppearancePicker extends StatelessWidget {
  const _AppearancePicker();

  static const _choices = [
    (ThemeMode.system, Icons.brightness_auto_rounded, 'Sistem'),
    (ThemeMode.light, Icons.light_mode_rounded, 'Açık'),
    (ThemeMode.dark, Icons.dark_mode_rounded, 'Koyu'),
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<ThemeSettings>();
    final palette = context.palette;

    return Row(
      children: [
        for (final (mode, icon, label) in _choices) ...[
          if (mode != _choices.first.$1) const SizedBox(width: 8),
          Expanded(
            child: Builder(
              builder: (context) {
                final selected = settings.mode == mode;
                final foreground =
                    selected ? palette.onButton : palette.onSubtleSurface;
                return Semantics(
                  button: true,
                  selected: selected,
                  child: GestureDetector(
                    key: ValueKey('about-theme-${mode.name}'),
                    behavior: HitTestBehavior.opaque,
                    onTap: () => settings.setMode(mode),
                    child: Container(
                      height: 64,
                      decoration: BoxDecoration(
                        color:
                            selected ? palette.button : palette.subtleSurface,
                        // Seçim yalnızca renkle anlatılmaz; açık temada
                        // düğme rengi zemine yakın.
                        border: selected
                            ? Border.all(
                                color: palette.selectionBorder, width: 2)
                            : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.all(6),
                      // İkon yazının üstünde: yan yana 360 dp'lik telefonda
                      // bile 18 px taşıyordu (ölçüldü). Büyük yazı boyutunda
                      // da taşmak yerine küçülür.
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 22, color: foreground),
                            const SizedBox(height: 2),
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 15,
                                color: foreground,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/// §26 — bütün çıkartmaları çöpe atar. Dokunmayla değil, basılı tutmayla.
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
                color: context.palette.subtleSurface,
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
