# EmojiPuzzle

[![CI](https://github.com/ibrahimyasar68/emojipuzzle/actions/workflows/ci.yml/badge.svg)](https://github.com/ibrahimyasar68/emojipuzzle/actions/workflows/ci.yml)

Üç ile beş yaş arası çocuklar için, kaybedilemeyen bir yapboz oyunu.
Flutter ile yazıldı.

Yanlış bırakılan parça yumuşakça yerine döner: kırmızı yok, uyarı sesi yok,
süre yok, puan yok. Çocuk duraksarsa oyun önce parçayı belirginleştirir,
sonra yerini gösterir, gerekirse parçayı kendisi yerleştirir — ama boş bir
odada kendi kendine oynamaz. Her tamamlanan resim konfeti, balon eşleştirme
oyunu, albüme eklenen bir çıkartma ve bir boyama sayfası demektir.

Bir oyun üç arabadır, bir araba beş safha: yapbozlar 2×2'den 4×4'e büyür,
resimler 21 resimlik bir havuzdan rastgele gelir. Her safhanın sonunda
arabanın bir parçası boyanır; safhayı ilerleten boyamadır, bu yüzden hiçbir
araba beyaz bir parçayla gitmez.

Reklam yok, uygulama içi satın alma yok, hesap yok, ağ bağlantısı yok. Yayın
paketi hiçbir Android izni istemez.

## Çalıştırma

```bash
flutter pub get
flutter run
```

Gereken: Flutter 3.35.6.

## Geliştirme

```bash
flutter analyze
flutter test                            # 1173 test
dart format lib test tool
dart run tool/generate_sfx.dart         # ses efektlerini yeniden üretir
python3 tool/generate_object_images.py  # kodla çizilen resimler (Pillow)
python3 tool/generate_store_graphics.py # Play öne çıkan grafiği (Pillow)
python3 tool/generate_app_icon.py       # uygulama ikonu (Pillow)
flutter build appbundle --release       # Play paketi; imza android/key.properties'ten
```

Testler `build/` altına kanıt görselleri bırakır (`preview_2x2.png`,
`solved_2x2.png`, `balloon_game.png`, …).

## Dokümanlar

| Dosya | Ne |
| ----- | -- |
| [`docs/spec-v2.2.md`](docs/spec-v2.2.md) | Şartname — projenin tek kaynağı (§0–§51) |
| [`devam.md`](devam.md) | Nerede kalındığı, verilmiş kararlar, mimari sözleşmeler |
| [`docs/privacy-policy.md`](docs/privacy-policy.md) | Gizlilik politikası |
| [`docs/store-listing.md`](docs/store-listing.md) | Mağaza metni, iki dilde; sürüm notları |
| [`docs/play-store-release.md`](docs/play-store-release.md) | Play yayın kontrol listesi |
| [`docs/store/`](docs/store/) | Öne çıkan grafik ve ekran görüntüleri |
| [`assets/LICENSES.md`](assets/LICENSES.md) | Her asset'in kaynağı ve lisansı |

## Lisans ve attribution

Yapbozlardaki görseller **OpenMoji** projesinden gelir:

> Emoji artwork: OpenMoji — the open-source emoji and icon project.
> Licence: CC BY-SA 4.0 · <https://openmoji.org>

Bu depo o görselleri birlikte dağıttığı için attribution burada da yer alır.
Görsel dosyaları değiştirilmemiştir; parçalara bölme işlemi çalışma anında
yapılır. Ayrıntılar için [`assets/LICENSES.md`](assets/LICENSES.md).

Eşyalar kategorisinin üç resmi (kitap, mikroskop, dürbün), giriş ekranındaki
gülen surat ve boyama arabaları bu deponun kendi çizimidir; ses efektleri de
öyle (`tool/generate_sfx.dart`).

Yapımcı: IY Labs · ibrahimyasar68@hotmail.com
