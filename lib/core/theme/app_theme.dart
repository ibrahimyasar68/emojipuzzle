import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Oyunun renkleri, açık ve koyu olarak (§36).
///
/// Ekranlar renk yazmaz; `context.palette` ile o anki temanın paletini alır.
/// Boyayıcıların context'i yoktur, renklerini onları kuran widget verir.
/// Temaya göre değişmeyen renkler (sarı oyna düğmesi, balon ve konfeti
/// renkleri, parça gradyanları) burada değildir.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  const AppPalette({
    required this.background,
    required this.onBackgroundMuted,
    required this.subtleSurface,
    required this.onSubtleSurface,
    required this.stickerPlaceholder,
    required this.silhouette,
    required this.button,
    required this.onButton,
    required this.selectionBorder,
    required this.slotOutline,
    required this.pieceShadow,
    required this.balloonString,
    required this.rewardScrim,
  });

  /// Açık tema: oyunun ilk krem zemininin (`#FDF7EF`) bir ton koyusu,
  /// `#EEE8E1` (kullanıcı istedi), ve ona göre seçilmiş renkler.
  static const light = AppPalette(
    background: Color(0xFFEEE8E1),
    // #7A6F65 bu zeminde 4,0:1 kalıyordu; 13 px yazı için 4,5:1 gerekir.
    onBackgroundMuted: Color(0xFF6E645B),
    subtleSurface: Color(0x14000000),
    onSubtleSurface: Color(0xFF4A4039),
    stickerPlaceholder: Color(0x0F000000),
    silhouette: Color(0xFFBDB5AC),
    // Krem #F3E4D0 bu zemine çok yakın kalıyordu; bir ton koyusu (kullanıcı
    // istedi).
    button: Color(0xFFE4D6C4),
    onButton: Color(0xFF4A4039),
    selectionBorder: Color(0xFF4A4039),
    slotOutline: Color(0x738D6E63),
    pieceShadow: Color(0xFF6D4C41),
    balloonString: Color(0x66000000),
    rewardScrim: Color(0xE6EEE8E1),
  );

  /// Koyu tema. Zemin, ilk koyu lacivert `#14213D`'nin %25 beyaza doğru
  /// açılmışıdır: `#4F596E` (kullanıcı istedi). Açık zemine göre seçilmiş
  /// renkler (yarı saydam siyah, kahverengi yazı ve kontur, siyah ip) burada
  /// kaybolurdu; yeniden seçildi.
  static const dark = AppPalette(
    background: Color(0xFF4F596E),
    // #A9B4C8 bu zeminde 3,3:1 kalıyordu; 13 px yazı için 4,5:1 gerekir.
    onBackgroundMuted: Color(0xFFCBD3E0),
    subtleSurface: Color(0x1FFFFFFF),
    onSubtleSurface: Color(0xFFF2F4F8),
    stickerPlaceholder: Color(0x1FFFFFFF),
    silhouette: Color(0xFFBDB5AC),
    button: Color(0xFFF3E4D0),
    onButton: Color(0xFF4A4039),
    selectionBorder: Color(0xFFF2F4F8),
    slotOutline: Color(0x73FFFFFF),
    pieceShadow: Color(0xFF000000),
    balloonString: Color(0x80FFFFFF),
    rewardScrim: Color(0xE64F596E),
  );

  /// Bütün ekranların zemini.
  ///
  /// Android'in açılış penceresi (`res/values*/app_colors.xml`) ve iOS'un
  /// `LaunchBackground` renk seti aynı iki rengi kullanır; yoksa oyun
  /// açılırken bir an başka renkte parlar.
  final Color background;

  /// Yetişkin köşesindeki ikincil yazı, albümün kategori simgeleri.
  final Color onBackgroundMuted;

  /// İkincil düğmeler: zeminden bir ton ayrılan yüzey ve üstündeki ikon.
  final Color subtleSurface;
  final Color onSubtleSurface;

  /// Henüz kazanılmamış çıkartmanın zemini ve resmin gri gölgesi (§25).
  final Color stickerPlaceholder;
  final Color silhouette;

  /// Home'daki yuvarlak düğmeler.
  final Color button;
  final Color onButton;

  /// Seçili seçeneğin çerçevesi (Hakkında → Görünüm). Seçim yalnızca renk
  /// farkına bırakılmaz: açık temada düğme rengi zemine yakındır.
  final Color selectionBorder;

  /// Boş yuvanın kesikli konturu (§15).
  final Color slotOutline;

  /// Sürüklenen parçanın gölgesi (§17).
  final Color pieceShadow;

  /// Balonun ipi (§24).
  final Color balloonString;

  /// Kazanılan çıkartmanın arkasındaki perde (§25): zeminin kendisi, biraz
  /// saydam, ki arkada tamamlanmış resim sezilsin.
  final Color rewardScrim;

  @override
  AppPalette copyWith({
    Color? background,
    Color? onBackgroundMuted,
    Color? subtleSurface,
    Color? onSubtleSurface,
    Color? stickerPlaceholder,
    Color? silhouette,
    Color? button,
    Color? onButton,
    Color? selectionBorder,
    Color? slotOutline,
    Color? pieceShadow,
    Color? balloonString,
    Color? rewardScrim,
  }) {
    return AppPalette(
      background: background ?? this.background,
      onBackgroundMuted: onBackgroundMuted ?? this.onBackgroundMuted,
      subtleSurface: subtleSurface ?? this.subtleSurface,
      onSubtleSurface: onSubtleSurface ?? this.onSubtleSurface,
      stickerPlaceholder: stickerPlaceholder ?? this.stickerPlaceholder,
      silhouette: silhouette ?? this.silhouette,
      button: button ?? this.button,
      onButton: onButton ?? this.onButton,
      selectionBorder: selectionBorder ?? this.selectionBorder,
      slotOutline: slotOutline ?? this.slotOutline,
      pieceShadow: pieceShadow ?? this.pieceShadow,
      balloonString: balloonString ?? this.balloonString,
      rewardScrim: rewardScrim ?? this.rewardScrim,
    );
  }

  /// Tema değişirken geçiş animasyonu için.
  @override
  AppPalette lerp(covariant ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    // Uçlar tam döner: kayan noktalı ara değer, animasyon bittiğinde hedef
    // renge birebir eşit olmayabilir.
    if (t <= 0) return this;
    if (t >= 1) return other;
    Color mix(Color a, Color b) => Color.lerp(a, b, t)!;
    return AppPalette(
      background: mix(background, other.background),
      onBackgroundMuted: mix(onBackgroundMuted, other.onBackgroundMuted),
      subtleSurface: mix(subtleSurface, other.subtleSurface),
      onSubtleSurface: mix(onSubtleSurface, other.onSubtleSurface),
      stickerPlaceholder: mix(stickerPlaceholder, other.stickerPlaceholder),
      silhouette: mix(silhouette, other.silhouette),
      button: mix(button, other.button),
      onButton: mix(onButton, other.onButton),
      selectionBorder: mix(selectionBorder, other.selectionBorder),
      slotOutline: mix(slotOutline, other.slotOutline),
      pieceShadow: mix(pieceShadow, other.pieceShadow),
      balloonString: mix(balloonString, other.balloonString),
      rewardScrim: mix(rewardScrim, other.rewardScrim),
    );
  }
}

extension AppPaletteLookup on BuildContext {
  /// Geçerli temanın renkleri. Tema bir palet taşımıyorsa (ör. düz bir
  /// `MaterialApp` ile kurulan testler) parlaklığa göre seçilir.
  AppPalette get palette {
    final theme = Theme.of(this);
    return theme.extension<AppPalette>() ??
        (theme.brightness == Brightness.dark
            ? AppPalette.dark
            : AppPalette.light);
  }
}

abstract final class AppTheme {
  static final ThemeData light = _build(Brightness.light, AppPalette.light);
  static final ThemeData dark = _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette palette) {
    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: palette.background,
      extensions: <ThemeExtension<dynamic>>[palette],
    );
  }

  /// Status bar ikonları zeminin tersi renkte olmalı; yoksa saat ve pil
  /// zeminde kaybolur.
  static SystemUiOverlayStyle overlayFor(Brightness brightness) =>
      brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark;
}
