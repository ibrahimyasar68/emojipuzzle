# Asset gelen kutusu

Buradaki dosyalar **uygulamayla paketlenmez**. `pubspec.yaml` yalnızca
`assets/images/puzzles/` ve `assets/audio/sfx/` klasörlerini bildirir; bu
klasör oyunun dışındadır.

Bir görselin oyuna girebilmesi için üç şey gerekir (§33, §34):

1. **Kaynağı ve lisansı bilinmeli** ve `assets/LICENSES.md`'ye yazılmalı.
   Depo herkese açık olduğu için, lisansı belirsiz bir dosyayı repoya
   koymak onu dağıtmak anlamına gelir.
2. **Puzzle görseliyse 1:1 kare olmalı** (§6.1: board kare, görsel
   `BoxFit.contain` ile yerleşir) ve zemini şeffaf olmalı (§34).
3. `assets/images/puzzles/` içine, §34'ün adlandırma düzeniyle konmalı
   (`apple.png`, `cat.png` …) ve `PuzzleCatalog`'a bir kayıt eklenmeli.

## Bekleyenler

| Dosya | Boyut | Durum |
| ----- | ----- | ----- |
| `frame6.png` | 122×90 | Kaynağı ve lisansı bilinmiyor. Kare değil, bu haliyle puzzle görseli olamaz. Bir çerçeve/logo grafiği gibi duruyor; nerede kullanılacağı da belirsiz. |
