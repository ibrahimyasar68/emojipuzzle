# Emoji Puzzle Kids

[![CI](https://github.com/ibrahimyasar68/emojipuzzle/actions/workflows/ci.yml/badge.svg)](https://github.com/ibrahimyasar68/emojipuzzle/actions/workflows/ci.yml)

Üç ile beş yaş arası çocuklar için, kaybedilemeyen bir yapboz oyunu.
Flutter ile yazıldı.

Yanlış bırakılan parça yumuşakça yerine döner: kırmızı yok, uyarı sesi yok,
süre yok, puan yok. Çocuk duraksarsa oyun önce parçayı belirginleştirir,
sonra yerini gösterir, gerekirse parçayı kendisi yerleştirir — ama boş bir
odada kendi kendine oynamaz. Her tamamlanan resim konfeti, kısa bir balon
oyunu ve albüme eklenen bir çıkartma demektir.

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
flutter test                      # 875 test
dart format lib test tool
dart run tool/generate_sfx.dart   # ses efektlerini yeniden üretir
```

Testler `build/` altına kanıt görselleri bırakır (`preview_2x2.png`,
`solved_2x2.png`, `balloon_game.png`, …).

## Dokümanlar

| Dosya | Ne |
| ----- | -- |
| [`docs/spec-v2.2.md`](docs/spec-v2.2.md) | Şartname — projenin tek kaynağı (§0–§51) |
| [`devam.md`](devam.md) | Nerede kalındığı, verilmiş kararlar, mimari sözleşmeler |
| [`docs/privacy-policy.md`](docs/privacy-policy.md) | Gizlilik politikası |
| [`docs/store-listing.md`](docs/store-listing.md) | Mağaza metni |
| [`assets/LICENSES.md`](assets/LICENSES.md) | Her asset'in kaynağı ve lisansı |

## Lisans ve attribution

Yapbozlardaki görseller **OpenMoji** projesinden gelir:

> Emoji artwork: OpenMoji — the open-source emoji and icon project.
> Licence: CC BY-SA 4.0 · <https://openmoji.org>

Bu depo o görselleri birlikte dağıttığı için attribution burada da yer alır.
Görsel dosyaları değiştirilmemiştir; parçalara bölme işlemi çalışma anında
yapılır. Ayrıntılar için [`assets/LICENSES.md`](assets/LICENSES.md).

Ses efektleri bu deponun kendi ürünüdür (`tool/generate_sfx.dart`).
