# 🧩 EMOJI PUZZLE KIDS — FLUTTER OYUN PROJESİ (v2.2)

> **Bu dokümanın okunma biçimi**
>
> Her madde bir öncelik etiketi taşır:
>
> * **[ZORUNLU]** — Bu karar bağlayıcıdır. Değiştirmek istersen önce bana sor.
> * **[TERCİH]** — Güçlü öneri. Daha iyi bir gerekçen varsa değiştirebilirsin, ama gerekçeyi yaz.
> * **[OPSİYONEL]** — İlk sürüm için zorunlu değil. Mimari buna engel olmamalı, o kadar.
> * **[KARAR BEKLİYOR]** — Henüz karara bağlanmadı. Bu maddeye gelmeden önce bana sor.
>
> Etiketsiz metin açıklama/bağlamdır, emir değildir.

---

# 0.1 v2.1 → v2.2 DEĞİŞİKLİK ÖZETİ

Bu bölüm yalnızca neyin değiştiğini gösterir. Detay ilgili bölümdedir.

| # | Değişiklik | Bölüm | Gerekçe |
|---|------------|-------|---------|
| 1 | Kademe 1 artık **2×2**. 1×3 içerikten çıktı, engine'de destekli kaldı. | §4 | 1×3 kare board'da 167×500'lük aşırı uzun hücreler üretiyordu |
| 2 | Kademe sayısı **4 → 3**, kademe başına puzzle **2 → 3** | §4 | 12 parça, scroll'suz tray + 64 px hedefiyle küçük telefonda sığmıyor |
| 3 | Tray parça ölçeği sabit değil, **dinamik hesaplanıyor** | §16 | Sabit 0.70 küçük telefonda 64 px dokunma hedefini ihlal ediyordu |
| 4 | `normalizedPosition`'ın **hücre sol üstü** olduğu sözleşmeye bağlandı | §8, §12 | Path sol üstü olsaydı kenar parçalarda negatif olurdu |
| 5 | Snap mesafesi **merkez–merkez** olarak tanımlandı | §18 | v2.1'de neyin arası olduğu yazmıyordu |
| 6 | Parça `id` kuralı tanımlandı: `row * columns + column` | §12 | Hint seçimi "en düşük id" diyordu ama id tanımsızdı |
| 7 | "Farklı seed → farklı dizilim" testi **istatistiksel** hale getirildi | §41, §49 | 1×3'te 4 olası dizilim var; test flaky oluyordu |
| 8 | Hint hedef seçim kuralı yeniden yazıldı | §21 | 1×3'te ortadaki parça da 2 flat kenarlıydı, kural belirsizdi |
| 9 | `unlockedStickerIds` **türetilmiş veri** oldu | §25 | `completedPuzzleIds` ile aynı veriyi iki yerde tutup desenkronize olabiliyordu |
| 10 | Yerleşmiş parça **kilitli**, tray slotları **sabit** | §10, §16 | v2.1'de tanımsızdı; reflow çocuğun mekânsal hafızasını bozar |
| 11 | `PuzzleImageLoader` katmanı eklendi | §14, §39 | Decode'un hangi katmanda olduğu tanımsızdı |
| 12 | Asset yükleme hatası için çocuk-facing fallback tanımlandı | §14 | `AppState.error` vardı ama davranışı yoktu |
| 13 | `schemaVersion` uyuşmazlık politikası tanımlandı | §25 | Migrate mi reset mi belirsizdi |
| 14 | Android back davranışı netleştirildi (dialog yok) | §30 | "Güvenli çıkış" tanımsızdı; çocuk onay dialogu okuyamaz |
| 15 | Balon oyunu bitiş koşulu ve spawn kuralı eklendi | §24 | Tanımsızdı |
| 16 | `displayNameKey` → `displayName` | §13 | Key'i çözecek bir l10n katmanı yoktu |
| 17 | Kademe açılma kuralı veriye taşındı (`requiredCompletions`) | §4, §13 | Sabit "2" kuralı içerik büyüyünce kırılıyordu |
| 18 | `GameProgress`'e kaldığı yer bilgisi eklendi | §25 | Uygulama kapanınca "sonraki puzzle" nereden devam edecekti belirsizdi |
| 19 | Tray karıştırma modellendi, seed'i inject edilebilir | §16, §41 | Serbest Mod karıştırmadan bahsediyordu ama model yoktu |
| 20 | Faz 1 kapsamı daraltıldı, §48 ile §49 tutarlı hale getirildi | §48, §49 | Kabul kriteri görev listesinde olmayan sınıfı istiyordu |
| 21 | Faz planı 17 → 16 faz | §44 | Kademe sayısı azaldı |

---

# 0.3 v2.2 SONRASI EKLER — FAZ 17 VE 18

*15 Eylül 2026'da eklendi.* 16 fazlık plan tamamlandıktan sonra proje sahibi
iki yeni safha istedi. Aşağıdaki kararlar §45 gereği önce soruldu ve
cevaplandı; değişen [ZORUNLU] maddeler kendi bölümlerinde işaretlidir.

| # | Karar | Bölüm |
|---|-------|-------|
| K-5 | Balon oyunu **renk eşleştirmedir**: aynı renkten iki balona art arda dokunulunca ikisi birlikte patlar. İkinci dokunuş farklı renkteyse **seçim sessizce yeni balona geçer**; hiçbir geri bildirim yok (§20). | §24 |
| K-6 | Balon sekansından ve sticker'dan sonra **boyama safhası** gelir ve **atlanabilir**. Sıra: kutlama → balon → sticker → boyama → sonraki puzzle. | §23, §24.2 |
| K-7 | Boyama çizimleri (siyah çizgili arabalar) **kodla çizilir** (Path); lisans kaydı gerekmez. | §24.2, §33 |
| K-8 | Boyama ekranında §2'nin "en fazla 5 dokunulabilir eleman" sınırı **esner**: renk seçimi + ~6 araba parçası, her biri ≥ 64 px. | §2, §24.2 |
| K-9 | Renk sabit bir listeden değil, **serbest bir paletten** seçilir: bir şeritte bütün tonlar açıktan koyuya, yanında beyazdan siyaha gri şerit. Parmak palette gezdikçe seçim de gezer. *(Faz 18 sırasında, 15 Eylül; K-8'in "6 renk"ini değiştirdi.)* | §24.2 |
| K-19 | **Puzzle parçaları kabartmalı çizilir:** her parçanın konturunun içinde sol üstte ışık, sağ altta gölge; board'a oturan parça ayrıca ince bir gölge düşürür. **Tamamlanan resimde dikişler görünür** — §14'ün "pürüzsüz tek resim" hedefi burada bilerek bırakıldı: kullanıcı bitmiş yapbozun üç boyutlu görünmesini istedi. Kabartma parçanın konturuna kırpılır, komşusunun alanına taşmaz; §14'ün dikiş tonu testi kabartma kapalı ölçer. *(20 Eylül, kullanıcı istedi.)* | §14, §15 |
| K-18 | **Safhayı boyama ilerletir.** Boyama sayfası atlanırsa oyun aynı safhada kalır: sıradaki puzzle **başka bir resimle, aynı ebatta** gelir. Safha sayacı türetilir: safha = o arabanın boyanmış parça sayısı. Böylece bir araba beyaz parçayla bitmez ve oyun sonunda boyanmamış parça kalmaz. Diziyi yarıda bırakmak da atlamaktır. *(20 Eylül, kullanıcı istedi; K-15'in "her safha sonunda ilerle" kuralını değiştirdi.)* | §4, §24.2, §25 |
| K-17 | **Boyama arabaları hacimli çizilir:** her parçanın dolgusunun üstüne, kendi sınırına kırpılmış açıktan koyuya bir perde (ışık yukarıdan) ve arabanın altına yere düşen bir gölge gelir. Perde **dolgudan sonra, çizgiden önce** çizilir; siyah çizgi solmaz. Perdenin ortası saydamdır, böylece K-9'un "palette gördüğün renk parçaya sürülür" sözü ekranda birebir görünmeye devam eder. *(17 Eylül, kullanıcı istedi: "daha gerçekçi ve üç boyutlu görünsün".)* | §24.2 |
| K-16 | **Eşyalar'ın üç resmi bu projede kodla çizildi** (`tool/generate_object_images.py`, Pillow): OpenMoji üslubunda (72 birim ızgara, 2 birim siyah çizgi, OpenMoji paletinden düz renkler), 1024×1024, şeffaf zemin. §33'ün [ZORUNLU] kaynak listesine **projenin kendi çizimi** eklendi; hiçbir OpenMoji dosyası kopyalanmadı ya da uyarlanmadı, attribution gerekmez. *(17 Eylül, kullanıcı istedi: "görselleri sen çiz"; K-14'ün "proje sahibi sağlayacak" kısmını değiştirdi.)* | §33, §34 |
| K-15 | **Yeni oyun kuralları.** Kademe ve kilit açma kalktı. Bir oyun 3 araba, bir araba 5 safhadır; her safhada havuzdan **rastgele** bir resim gelir (bir oyunda tekrar etmez) ve puzzle ebadını **safha** belirler: 2×2 → 2×3 → 3×3 → 4×3 → 4×4. Her safhanın sonunda arabanın bir parçası boyanır; **boyanan parça kilitlenir**, "geç" oku kalır. 5. safhadan sonra araba — beyaz parçası kalsa bile — sürülüp gider ve sıradaki araba 2×2'den başlar. 3 araba bitince **oyun sonu**: biten arabalar yan yana, konfeti, sonra Home ve yeni oyun; arabalar sırayla devam eder. 4×3 ve 4×4 küçük ekranlarda sığsın diye **board gerektiğinde küçülür** (§40); 64 px ve kaymayan tepsi kuralları korunur. Albümden seçilen resim o anki safhanın ebadıyla oynanır. *(15 Eylül, kullanıcı istedi.)* | §2, §4, §16, §24.2, §25, §40 |
| K-14 | Yeni kategori **Eşyalar** (`objects`): kitap, mikroskop, dürbün. §4'ün [ZORUNLU] "enum yalnızca 5 değer" kuralı 6'ya çıktı. Her kademeye bir tane: kitap 2×2, dürbün 2×3, mikroskop 3×3 (K-15'ten sonra kademe yok, üçü de havuzda). Görselleri proje sahibi sağlayacaktı; K-16 ile kodla çizildi. *(15 Eylül, kullanıcı istedi.)* | §4, §25 |
| K-13 | Boyama defterine **kamyon ve traktör** eklendi: 5 model (sedan, kamyonet, yarış arabası, kamyon, traktör), yine kodla çizilir ve her parça 64 px ölçümünü geçer. *(15 Eylül, kullanıcı istedi.)* | §24.2 |
| K-12 | İçerik **18 puzzle**: her kademeye 3 yeni resim (3 kademe × 6). Karpuz, çilek, ananas → meyveler; uçak, bisiklet → taşıtlar; ay, Satürn → doğa; kaplumbağa, koyun → hayvanlar. Kategori listesi (5 değer) değişmedi. Görseller OpenMoji, aynı kaynak ve lisans. *(15 Eylül, kullanıcı istedi; oyun kuralları sonra değişecek, kademe yerleşimi geçici olabilir.)* | §4 |
| K-11 | Balon oyunu **10 balon** (5 çift) üretir ve hepsi **3 saniye içinde** sahneye çıkar; çiftlerin renkleri **rastgeledir**. §24'ün "en fazla 8 aktif balon" [ZORUNLU] maddesi bu yüzden 10'a çıktı. *(15 Eylül, kullanıcı istedi: giriş uzun sürüyordu, balon çoktu.)* | §2, §24 |
| K-10 | Seçilen renk ekranın **sol üst köşesindeki bir karede** gösterilir; çocuk seçimin sonucunu parmağının altında kalmadan görür. *(Faz 18 sırasında, 15 Eylül.)* | §24.2 |

---

# 0.2 AÇIK KARARLAR

Bu maddeler karara bağlanmadan ilgili faza geçilmez.

**[KARAR BEKLİYOR] K-1 — Kademe merdiveni**

Varsayılan olarak 3 kademe × 3 puzzle yazıldı (§4). Alternatifler:

* **A (varsayılan)** — 3 kademe: 2×2, 2×3, 3×3. 9 puzzle.
* **B** — 4 kademe: 2×2, 2×3, 3×3, 3×4. 12 parçalık kademe yalnızca tray scroll'u veya landscape geldikten sonra mümkün; §16'daki "tray scroll etmez" kuralı gevşetilmeli.
* **C** — 1×3 kademe 1 olarak geri gelsin, board 1×3'te dikdörtgen olsun. §6'daki "board her zaman karedir" kuralı gevşetilmeli.

**[KARAR BEKLİYOR] K-2 — Sessize alma düğmesi**

Home ekranında tek ikonluk mute toggle MVP'ye alınsın mı? v2.1'de §47'de (ileride) idi. Maliyeti düşük, ebeveyn beklentisi yüksek.

**[KARAR BEKLİYOR] K-3 — CI**

`flutter analyze` + `flutter test` çalıştıran minimal bir GitHub Actions workflow'u Faz 1 sonunda kurulsun mu?

**[KARAR BEKLİYOR] K-4 — Debug overlay**

Yalnızca debug build'de hücre sınırlarını, snap yarıçapını ve grab offset vektörünü çizen geliştirici katmanı Faz 5'te eklensin mi?

---

# 0. TEKNİK ORTAM

**[ZORUNLU]**

* Flutter: stable kanal, 3.24 veya üzeri
* Dart: 3.5+
* Null safety: zorunlu
* Min Android: API 24
* Min iOS: 13.0
* Lint: `flutter_lints`
* Gereksiz paket eklenmez.
* Ekran yönü: yalnızca portrait (MVP).
* Landscape desteği ileride değerlendirilecek; mimari landscape'e hazır olmalı.
* Dil:

  * kod ve sınıf/değişken isimleri İngilizce
  * **kod yorumları Türkçe** — *13 Eylül 2026'da değiştirildi. v2.2 bu
    maddede "yorumlar İngilizce" diyordu; proje sahibi yorumların Türkçeye
    çevrilmesini istedi ve §45 gereği bu değişiklik önce sorulup onaylandı.
    `lib/` altındaki bütün yorumlar çevrildi. §46'nın "her `PuzzleConfig`
    sabiti hangi spec bölümünden geldiğini yorumda belirtir" kuralı aynen
    geçerli; `§` atıfları değişmedi.*
  * kullanıcıya görünen metinler ve seslendirme Türkçe

---

# 1. PROJENİN AMACI

3–5 yaş arasındaki, okuma-yazma becerisi henüz gelişmemiş çocukların yalnızca görsel ve dokunsal etkileşimle oynayabileceği bir jigsaw puzzle oyunu.

Oyuncunun temel görevi:

> Tepsideki yapboz parçalarını sürükleyerek hedef alana yerleştirmek ve resmi tamamlamak.

Temel prensipler:

* basit
* eğlenceli
* renkli
* güvenli
* cezasız
* dokunma odaklı
* sesli + animasyonlu geri bildirimli
* tamamen offline

---

# 2. HEDEF KİTLE VE UX KISITLARI

**[ZORUNLU]**

Kullanıcı 3–5 yaşındadır, okuma-yazma becerisi gelişmemiştir ve motor kontrolü yetişkin kadar hassas değildir.

Bu nedenle:

* Minimum dokunma hedefi: **64×64 logical px**
* Balon gibi kritik etkileşimlerde minimum hedef: **72×72 logical px**
* Kullanıcıya görünen metin minimumda tutulur.
* Metinli aksiyonlarda ikon da bulunur.
* Long press hiçbir yerde zorunlu aksiyon değildir.
* Double tap gerektiren aksiyon yoktur.
* Hiçbir ekranda 5'ten fazla temel dokunulabilir eleman bulunmaz.
* Hata durumunda:

  * kırmızı renk
  * ünlem
  * negatif ses
  * ceza animasyonu

  kullanılmaz.
* Oyun metin okumayı gerektirmez.
* Önemli yönlendirmeler mümkün olduğunca görsel, animasyon ve ses yoluyla yapılır.

Bu kurallar puzzle ekranı, home, celebration, balloon game ve album dahil tüm çocuk-facing ekranlar için geçerlidir.

*İstisnalar:* balon oyunu en fazla 10 balon gösterir (§24, K-11); boyama ekranı bir renk paleti (ton şeridi + gri şerit), 5–6 araba parçası ve bir "geç" oku gösterir (K-8, K-9, §24.2). İkisinde de her hedef en az 64 px'tir (balonda 72 px).

**[ZORUNLU] — 64 px kuralı bir tavan dayatır**

Minimum dokunma hedefi pazarlık konusu değildir. Bir layout 64 px'i sağlayamıyorsa layout değişir, kural değişmez. Bunun doğrudan sonucu:

> Scroll etmeyen bir tepside, 360×640 dp referans telefonda en fazla **9 parça** gösterilebilir.

Bu, MVP'de parça sayısının üst sınırıdır (§4, §16).

*K-15'te ölçüldü ve düzeltildi:* tepsi hesabı board'dan artan bütün yüksekliği kullandığı için 360×640'ta 16 parça da 64 px'te sığar. Sığmayan ekranlarda (320×568'de 12 ve 16 parça, sistem çubukları düşülmüş 360×592'de 16 parça) board küçülür (§40). Kural değişmedi; üst sınır 16 oldu.

---

# 3. CORE GAMEPLAY

```text
Puzzle seç
    ↓
Parçaları tepside göster
    ↓
Çocuk parçayı sürükler
    ↓
Bırakma anında snap kontrolü
    ↓
Doğruysa → yerine oturur → pop + particle
Yanlışsa → rubber-band ile tepsiye döner
    ↓
Tüm parçalar yerleşti mi?
    ↓
Evet → Celebration
    ↓
Balon mini oyunu
    ↓
Sticker ödülü
    ↓
Sonraki puzzle
```

Yanlış hareket hiçbir şekilde ilerlemeyi cezalandırmaz.

---

# 4. KADEME VE İÇERİK YAPISI

> **K-15 ile bu bölümün kademe, kilit açma ve Serbest Mod kuralları kalktı.** Oyunun biçimi artık safha ve arabadır (§0.3, K-15; kod: `features/puzzle/data/game_rules.dart`). Aşağıdaki resim listesi bir **havuz** olarak geçerlidir; kademe tablosu ve `requiredCompletions` tarihçe olarak bırakıldı.

**[ZORUNLU]** — *v2.2'de değişti, bkz. K-1*

| Kademe | Parça | Grid  | Puzzle |
| ------ | ----: | ----- | -----: |
| 1      |     4 | 2 × 2 |      6 |
| 2      |     6 | 2 × 3 |      6 |
| 3      |     9 | 3 × 3 |      6 |

*K-12'de her kademe 3'ten 6 puzzle'a çıktı.*

Engine 1×3 ve 3×4 dahil keyfi `rows × columns` gridlerini desteklemeye devam eder. Yukarıdaki tablo **içerik** kararıdır, engine kısıtı değildir. 1×3 için yazılmış engine testleri korunur.

Kademe açılma kuralı:

**[ZORUNLU]**

Bir kademe, kendisinden önceki kademede `requiredCompletions` kadar puzzle tamamlandığında açılır. Bu sayı sabit değildir; `LevelDefinition` içinde veri olarak tutulur (§13). v1 değeri her kademe için **2**'dir.

İçerik (K-12'den sonra):

```text
Kademe 1 (2×2) → apple_01 (fruits),  cat_01 (animals),   ball_01 (shapes)
                 strawberry_01 (fruits), moon_01 (nature), sheep_01 (animals)
Kademe 2 (2×3) → banana_01 (fruits), dog_01 (animals),   bus_01 (vehicles)
                 watermelon_01 (fruits), bicycle_01 (vehicles), turtle_01 (animals)
Kademe 3 (3×3) → car_01 (vehicles),  sun_01 (nature),    lion_01 (animals)
                 pineapple_01 (fruits), airplane_01 (vehicles), saturn_01 (nature)
```

K-14/K-16 ile havuza üç resim daha: `book_01`, `microscope_01`, `binoculars_01` (objects). Havuz **21 resim**.

```dart
enum PuzzleCategory {
  fruits,
  animals,
  vehicles,
  nature,
  shapes,
  objects, // K-14 — Eşyalar
}
```

v1'de enum yalnızca bu 5 değeri içeriyordu; K-14 ile **6** oldu (`objects`, Eşyalar).

İleride `colors`, `numbers` vb. eklenebilir.

**[TERCİH]**

Tüm kademeler açıldıktan sonra Serbest Mod bulunmalıdır.

Serbest Mod:

* tamamlanan herhangi bir puzzle tekrar oynanabilir
* parçalar her oyunda yeniden karıştırılır (§16)
* progress kaybolmaz
* çocuk herhangi bir cezaya maruz kalmaz

---

# 5. PUZZLE ENGINE

**[ZORUNLU]**

Puzzle Engine bağımsız bir katmandır.

Sorumlulukları:

* grid oluşturma
* parça üretme
* edge üretme
* jigsaw `Path` üretimi
* doğru pozisyon hesabı
* normalize/pixel dönüşümleri
* snap mesafesi hesabı
* tamamlanma durumu

Engine hiçbir widget import etmez.

`package:flutter/material.dart` engine dosyalarında kullanılmaz.

`dart:ui` kullanılabilir (`Offset`, `Size`, `Path`, `Rect` için).

Engine iki alt katmana ayrılır:

```text
engine/
├── geometry/
│   ├── puzzle_generator.dart
│   ├── edge_resolver.dart
│   ├── coordinate_mapper.dart
│   ├── snap_calculator.dart        ← Faz 6
│   └── tray_layout_calculator.dart ← Faz 4
└── path/
    └── jigsaw_path_generator.dart  ← Faz 2
```

Geometri mümkün olduğunca deterministik ve kolay test edilebilir olmalıdır.

Rastgelelik dependency injection ile verilir:

```dart
PuzzleGenerator({Random? random})
    : _random = random ?? Random();
```

Testlerde:

```dart
Random(42)
```

kullanılabilmelidir.

**[ZORUNLU] — Engine saflık kontrolü otomatik olmalıdır**

"Engine widget import etmiyor" kuralı gözle denetlenmez. Engine klasöründeki dosyaları okuyup yasaklı import arayan bir test yazılır (§41).

---

# 6. GEOMETRİ

## 6.1 Board

**[ZORUNLU]**

* Tüm puzzle görselleri 1:1 kare asset'tir.
* Board her zaman karedir.
* Board maksimum 500×500 logical px'tir.
* Hücrelerin kare olması gerekmez.

Örneğin 2×3:

```text
Board = 500 × 500

┌────────┬────────┬────────┐
│        │        │        │
│   0    │   1    │   2    │
│        │        │        │
├────────┼────────┼────────┤
│        │        │        │
│   3    │   4    │   5    │
│        │        │        │
└────────┴────────┴────────┘

cellWidth  = 500 / 3 = 166.67
cellHeight = 500 / 2 = 250.00
```

```dart
cellWidth = boardWidth / columns;
cellHeight = boardHeight / rows;
```

Görsel `BoxFit.contain` ile board'a yerleştirilir.

`cover` ve `fill` kullanılmaz.

---

# 7. TAB BOYUTU VE PARÇA BOYUTU

**[ZORUNLU]**

Jigsaw çıkıntıları hücre sınırının dışına taşar.

```dart
final shortEdge = min(cellWidth, cellHeight);
final tabSize = shortEdge * PuzzleConfig.tabSizeRatio; // 0.20

final pieceWidth  = cellWidth  + 2 * tabSize;
final pieceHeight = cellHeight + 2 * tabSize;
```

Piece `Path` koordinat sistemi:

```text
(0,0)
  ┌────────────────────┐
  │    ┌──────────┐    │
  │    │   CELL   │    │
  │    └──────────┘    │
  └────────────────────┘
```

Hücrenin gövdesi `(tabSize, tabSize)` noktasından başlar.

Görsel de aynı offset mantığıyla çizilir.

Amaç:

* tab'ların kırpılmaması
* komşu parçaların görsel olarak doğru birleşmesi
* dar gridlerde tab boyutunun aşırı büyümemesi

**[ZORUNLU] — Parça bounding box'ı board'un dışına taşabilir**

Dış sınır parçalarında path bounding box'ı board'un `tabSize` kadar dışına çıkar. Bu bölge **boştur** (dış kenarlar flat olduğu için orada geometri yoktur), ama layout ve hit-test bunu hesaba katmak zorundadır. Bu taşma bir hata değildir; kırpılması hatadır.

---

# 8. KOORDİNAT SİSTEMİ

**[ZORUNLU]**

Projede koordinat sistemleri açıkça birbirinden ayrılmalıdır.

```text
Global Screen Coordinates
        ↓  (board origin çıkarılır)
Board Coordinates (pixel)
        ↓  (board size'a bölünür)
Normalized Board Coordinates (0..1)
        ↓  (tabSize offset uygulanır)
Piece Coordinates
```

## 8.1 Global koordinat

Flutter gesture sistemi tarafından sağlanan ekran/Stack koordinatıdır.

## 8.2 Board koordinatı

Board'un sol üstü `(0,0)` kabul edilir. Birim: logical pixel.

## 8.3 Normalized koordinat

Domain içinde `0.0 → 1.0` aralığındadır.

`Offset(0.333, 0.0)` board'un yaklaşık üçte birini ifade eder.

## 8.4 Pixel dönüşümü

```dart
Offset pixelOf(Offset normalized, Size boardSize) {
  return Offset(
    normalized.dx * boardSize.width,
    normalized.dy * boardSize.height,
  );
}
```

**[ZORUNLU]**

Domain model içinde responsive hedef pozisyonları pixel olarak saklanmaz.

## 8.5 `normalizedPosition` sözleşmesi

**[ZORUNLU]** — *v2.2'de eklendi*

`PuzzlePiece.normalizedPosition`:

* **hücrenin sol üst köşesidir**, parça path'inin sol üstü değildir
* tab taşmasını **içermez**
* her zaman `[0.0, 1.0)` aralığındadır

```dart
normalizedPosition = Offset(column / columns, row / rows);
```

Render ve drag katmanları parça sol üstünü şöyle türetir:

```dart
pieceTopLeftPixel = pixelOf(normalizedPosition, boardSize)
                  - Offset(tabSize, tabSize);
```

Bu ayrım kritiktir: path sol üstü saklansaydı kenar parçalarında değer negatif olurdu ve "0..1 aralığında" kuralı ihlal edilirdi.

## 8.6 Piece id sözleşmesi

**[ZORUNLU]** — *v2.2'de eklendi*

```dart
id = row * columns + column;
```

id'ler `0 .. pieceCount-1` aralığında, boşluksuz ve tekildir. Satır-öncelikli sıradadır. Hint hedef seçimi (§21) ve tray sıralaması bu tanıma dayanır.

---

# 9. DRAG KOORDİNAT SÖZLEŞMESİ

**[ZORUNLU]**

Çocuk parçayı tam merkezinden tutmak zorunda değildir.

Parça tutulduğu anda:

```text
grabOffset = pointerBoardLocal - pieceTopLeftBoardLocal
```

ilişkisi kurulur ve sürükleme boyunca sabit kalır:

```text
pieceTopLeftBoardLocal = pointerBoardLocal - grabOffset
```

Örneğin çocuk parçanın sağ üstünden tutarsa, sürükleme sırasında parça parmağın merkezine sıçramamalıdır.

Bu hesap widget içinde karmaşık matematik olarak yazılmamalıdır. `CoordinateMapper` tarafından yönetilir:

```dart
static Offset grabOffsetOf({
  required Offset pointerBoardLocal,
  required Offset pieceOriginBoardLocal,
});

static Offset pieceOriginFromPointer({
  required Offset pointerBoardLocal,
  required Offset grabOffset,
});
```

---

# 10. TRAY → BOARD DRAG AKIŞI

**[ZORUNLU]**

Bir parça tepsideyken:

```text
Tray piece
   ↓
Pointer down
   ↓
Drag starts
   ↓
Piece drag layer'a alınır
   ↓
Piece %100 boyuta çıkar
   ↓
Z-order en üste çıkar
   ↓
Board koordinat sisteminde hareket eder
```

Drag tamamlandığında:

```text
Drop
 ↓
Snap check
 ├── success → placed
 └── failure → tray return
```

Parça board'a yerleşmediyse **kendi sabit tepsi slotuna** geri döner (§16).

Parça yanlış bir hücreye yakın bırakılırsa **başka hücreye snap olamaz.**

**[ZORUNLU] — Yerleşmiş parça kilitlidir** — *v2.2'de eklendi*

`PieceStatus.placed` durumundaki bir parça tekrar alınamaz, sürüklenemez, dokunmaya tepki vermez. Çocuğun yanlışlıkla tamamlanmış bir işi bozması engellenir. Yerleşmiş parça üzerindeki pointer olayları alttaki board'a da geçmez.

---

# 11. EDGE ÜRETİMİ

```dart
enum EdgeType {
  flat,
  tab,
  blank,
}
```

**[ZORUNLU]**

Kurallar:

1. Board dış sınırı → `flat`
2. İç kenar → `tab` veya `blank`
3. Komşuluk her zaman tamamlayıcıdır.
4. `A.right == tab` ise `B.left == blank`
5. `A.right == blank` ise `B.left == tab`
6. `flat` kenarın tamamlayıcısı `flat`'tir.
7. Üretim sırası:

   * satır satır
   * soldan sağa
   * `top` ve `left` komşudan devralınır
   * `right` ve `bottom` üretilir

1×3 grid'de (engine testi olarak korunur):

* top → flat
* bottom → flat
* yalnızca dikey iç kenarlar tab/blank olabilir.

---

# 12. MODEL AYRIMI

**[ZORUNLU]**

Domain modeli immutable'dır.

```dart
class PuzzlePiece {
  final int id;          // row * columns + column  (§8.6)
  final int row;
  final int column;

  final EdgeType top;
  final EdgeType right;
  final EdgeType bottom;
  final EdgeType left;

  /// Hücrenin sol üstü, normalized board space (§8.5).
  /// Tab taşmasını içermez. Her zaman [0.0, 1.0).
  final Offset normalizedPosition;

  /// Hint hedef seçimi için (§21).
  int get flatEdgeCount;
}
```

Runtime state:

```dart
class PieceRuntimeState {
  final int pieceId;
  final PieceStatus status;
  final Offset? dragOffset;
  final int failedAttempts;

  /// Sabit tepsi slot indeksi (§16). Karıştırma bunu belirler,
  /// parça yerleştikten sonra slot boş kalır ama başkasına verilmez.
  final int traySlotIndex;
}
```

`PieceStatus`:

```dart
enum PieceStatus {
  inTray,
  dragging,
  snapping,
  placed,
}
```

Parça döndürme yoktur.

---

# 13. PUZZLE VE LEVEL TANIMI

```dart
class PuzzleGrid {
  final int rows;
  final int columns;

  int get pieceCount => rows * columns;
  int idOf(int row, int column) => row * columns + column;
}
```

```dart
class PuzzleDefinition {
  final String id;
  final String imagePath;
  final PuzzleCategory category;
  final PuzzleGrid grid;
  final String displayName; // v2.2: displayNameKey değil.
}
```

`displayName` doğrudan Türkçe metindir. v1 tek dillidir ve key çözecek bir l10n katmanı yoktur; olmayan bir mekanizmaya işaret eden alan adı kullanılmaz. Çok dillilik gerekirse §47 kapsamında ayrıca ele alınır.

```dart
class LevelDefinition {
  final int index;
  final List<PuzzleDefinition> puzzles;

  /// Bir sonraki kademenin açılması için gereken tamamlama sayısı (§4).
  final int requiredCompletions;
}
```

Puzzle içerikleri engine'den ayrıdır.

v1 için:

```text
features/puzzle/data/puzzle_catalog.dart
```

tercih edilir.

JSON ancak içerik miktarı ciddi biçimde büyürse değerlendirilir.

---

# 14. RENDERING

**[ZORUNLU]** — *v2.2: sorumlu katman tanımlandı*

Puzzle görselinin decode'u ne provider'da ne widget'ta yapılır. Sorumlu sınıf:

```dart
// core/services/puzzle_image_loader.dart
class PuzzleImageLoader {
  Future<ui.Image> load(String assetPath, {int? cacheWidth});
  void evict(String assetPath);
}
```

Bir puzzle görseli bir kez decode edilir ve puzzle boyunca paylaşılır.

```text
asset
  ↓
PuzzleImageLoader
  ↓
ui.Image (shared)
  ↓
piece CustomPainter
```

Parçalar `CustomPainter` ile çizilir.

Painter:

* `canvas.clipPath(...)`
* `canvas.drawImageRect(...)`

kullanır.

`srcRect` ve `dstRect` hesapları açık bir coordinate contract'a sahip olmalıdır. `srcRect` her zaman kaynak görsel sınırlarına clamp edilir; sınır aşımı sessizce şeffaf piksel üretmez, assert ile yakalanır.

**[ZORUNLU]**

* Path build sırasında sürekli yeniden oluşturulmaz.
* Path'ler puzzle oluşturulurken hesaplanır.
* Path cache'lenir.
* `shouldRepaint` doğru uygulanır.
* `RepaintBoundary` sürüklenen parçada kullanılmalıdır.

**[ZORUNLU] — Asset yükleme hatası** — *v2.2'de eklendi*

Görsel yüklenemezse çocuğa hata gösterilmez. Davranış:

```text
load failure
   ↓
debug log
   ↓
o puzzle atlanır
   ↓
katalogdaki bir sonraki oynanabilir puzzle'a geçilir
   ↓
hiçbiri yüklenemiyorsa → Home, nötr placeholder
```

Kırmızı yok, metin yok, ünlem yok (§2).

**[TERCİH] — Kenar dikişleri**

Matematiksel olarak tam tamamlayıcı iki path arasında anti-aliasing 1 px'lik şeffaf çizgi bırakabilir. Faz 3'te gerçek cihazda kontrol edilir; gerekirse path yarım piksel dışa genişletilir veya `FilterQuality` ayarlanır. Faz 2'de peşinen çözülmeye çalışılmaz.

---

# 15. BOARD VE GHOST

**[ZORUNLU]**

Board:

* kare
* maksimum 500×500
* responsive
* merkezlenebilir

Ghost image:

* opacity: `%25`

Her hücrede:

* ince
* kesikli
* anlaşılır
* çocuk tarafından kolay görülebilen

slot outline bulunur.

MVP ghost modu:

```text
fadedImage + outline
```

---

# 16. TRAY

**[ZORUNLU]** — *v2.2'de yeniden yazıldı*

Tray scroll etmez. Tüm parçalar aynı anda görünür.

## 16.1 Dinamik boyut hesabı

Sabit ölçek kullanılmaz. Tray parça boyutu, kullanılabilir tepsi alanından türetilir:

```text
Girdi:  trayWidth, trayHeight, pieceCount, pieceAspectRatio
Çıktı:  columns, rows, itemSize
```

Algoritma:

```text
for rows in 1..pieceCount:
    columns   = ceil(pieceCount / rows)
    widthCap  = (trayWidth  - (columns-1) * spacing) / columns
    heightCap = (trayHeight - (rows-1)    * spacing) / rows
    itemWidth = min(widthCap, heightCap * aspectRatio)

    if itemWidth >= minTouchTargetSize:
        aday çözüm olarak kaydet

Kabul edilen adaylar arasından:
    board ölçeğine oranı trayPreferredPieceScale'e (0.70) en yakın olan seçilir.

Hiçbir aday yoksa:
    → bu grid bu ekranda oynanamaz (§2 tavanı)
    → debug'da assert, release'de en az satırlı çözüm
```

Kurallar:

* `itemWidth` ve `itemHeight` asla `minTouchTargetSize` (64 px) altına inmez.
* `trayPreferredPieceScale` (0.70) bir **hedef**tir, taban değildir.
* Parçalar arası minimum boşluk **12 logical px**'tir.
* Hesap widget içinde değil, `engine/geometry/tray_layout_calculator.dart` içinde yapılır ve unit test edilir.

Referans sonuç (360×640 dp, board 344, tray 256) — *v2.2'nin tahmini; K-15'te ölçülünce 12 ve 16 parçanın da sığdığı görüldü, bkz. §2 notu ve §40:*

| Parça | Satır × Sütun | itemSize | Durum |
|------:|---------------|---------:|-------|
| 4 | 2 × 2 | ~122 | ✓ |
| 6 | 2 × 3 | ~106 | ✓ |
| 9 | 3 × 3 | ~77  | ✓ |
| 12 | — | <64 | ✗ (§2 ihlali) |

## 16.2 Slot davranışı

**[ZORUNLU]**

* Tepsi slotları **sabittir**. Bir parça board'a yerleştiğinde slotu boş kalır; diğer parçalar yer değiştirmez.
* Reflow yapılmaz. Çocuğun "o parça şuradaydı" hafızası korunur.
* Başarısız drop'ta parça **kendi** slotuna döner.

## 16.3 Karıştırma

**[ZORUNLU]**

Parçaların slotlara dağılımı puzzle başlangıcında bir kez karıştırılır ve `PieceRuntimeState.traySlotIndex` içinde saklanır.

```dart
TrayShuffler({Random? random});
```

Random inject edilebilir; testte `Random(42)` ile deterministik sonuç alınır. Serbest Mod'da her oturumda yeniden karıştırılır.

## 16.4 Hit area çakışması

Genişletilmiş hit area'lar çakışırsa:

> Dokunma noktasına merkezi en yakın parça seçilir.

---

# 17. DRAG & DROP

**[ZORUNLU]**

Drag başlangıcı:

```text
tray itemSize → board pieceSize  (ölçek animasyonu)
+ 1.0 → 1.1 vurgu scale
120 ms

elevation: 6

z-order: top

HapticFeedback.selectionClick()
```

Provider her frame'de rebuild edilmez.

Drag position için:

```dart
ValueNotifier<Offset>
```

veya eşdeğer lokal state kullanılabilir.

**[ZORUNLU]**

Sürükleme sırasında `Provider.notifyListeners()` her frame çağrılmaz.

Sadece:

* drag başlangıcı
* drag bitişi
* gerekli state değişimleri

Provider state'ini etkiler.

---

# 18. SNAP

**[ZORUNLU]**

```dart
snapThreshold = max(
  PuzzleConfig.minSnapThreshold,                 // 24.0
  min(cellWidth, cellHeight) * PuzzleConfig.snapThresholdRatio, // 0.35
);
```

Bu değer `PuzzleConfig` üzerinden değiştirilebilir olmalıdır.

## 18.1 Mesafe tanımı

**[ZORUNLU]** — *v2.2'de eklendi*

Snap mesafesi **parçanın merkezi ile hedef hücrenin merkezi** arasındaki Öklid mesafesidir.

```dart
final pieceCenter  = pieceTopLeftBoardLocal + Offset(pieceWidth / 2, pieceHeight / 2);
final targetCenter = cellTopLeftBoardLocal  + Offset(cellWidth / 2,  cellHeight / 2);
final distance = (pieceCenter - targetCenter).distance;
```

Sol üst köşeler arası mesafe kullanılmaz. Parça merkezi ile hücre merkezi, tab offset'i simetrik olduğu için doğal olarak çakışır.

## 18.2 Kural

Snap yalnızca parçanın **kendi doğru yuvasına** göre hesaplanır. Yanlış hücreye yakınlık snap sebebi değildir. Board üzerindeki diğer hücrelere hiç bakılmaz.

```text
drop
 ↓
distance <= threshold  →  snap
distance >  threshold  →  rubber-band return
```

---

# 19. ASSIST MODE

**[ZORUNLU]**

Aynı parça için `failedAttempts >= 3` olduğunda:

```text
snapThreshold × 1.8
```

uygulanır.

Sayaç yalnızca o parça yerleştiğinde veya puzzle sıfırlandığında sıfırlanır; parçalar arasında taşınmaz.

Not: 3×3 gridde genişletilmiş eşik hücre yarı-mesafesini aşar. Yalnızca doğru yuva kontrol edildiği için yanlış snap riski yoktur, ancak parça uzaktan yerine "uçabilir". Bu bilinçli bir kabuldür; çocuğun takılı kalmasını önlemek önceliklidir.

---

# 20. NO PENALTY

**[ZORUNLU]**

Yanlış bırakmada:

* hata mesajı yok
* kırmızı yok
* negatif ses yok
* puan kaybı yok
* süre kaybı yok
* titreşim yok
* "tekrar dene" yok

Sadece:

```text
1.00 → 1.08 → 0.96 → 1.00
```

rubber-band animasyonu, **250 ms**.

---

# 21. IDLE HINT

**[ZORUNLU]**

8 saniyelik hareketsizlikten sonra kademeli hint sistemi:

```text
8 sn  → hedef parça pulse ×2
16 sn → parça + yuva birlikte pulse
24 sn → parçadan yuvaya hayalet hareket
32 sn → parça otomatik yerleşir
```

## 21.1 Hedef parça seçimi

**[ZORUNLU]** — *v2.2'de yeniden yazıldı*

Yerleşmemiş parçalar arasından:

1. `flatEdgeCount` en yüksek olan
2. eşitlikte `id` en düşük olan

seçilir.

Bu kural her grid için tek ve belirsizliksiz sonuç üretir. (v2.1'deki "iki flat kenarlı köşe" kuralı 1×3'te ortadaki parçayla köşeyi ayırt edemiyordu.)

## 21.2 Timer davranışı

Herhangi bir kullanıcı etkileşimi:

```text
idle timer reset
hint stage reset
```

32 sn otomatik yerleştirmeden sonra:

```text
idle timer reset
hint stage reset  →  bir sonraki parça için 8 sn'den başlar
```

Uygulama arka planda: `timer pause`
Foreground: `timer reset`

---

# 22. FEEDBACK

**[ZORUNLU]**

Doğru yerleşme feedback'i maksimum 400 ms sürer.

* kısa pop sound
* scale animation
* 6–8 sparkle
* hafif haptic

Feedback bir sonraki parçayı gereksiz yere bloke etmez.

---

# 23. PUZZLE COMPLETION

```text
Puzzle completed
      ↓
600 ms completion animation
      ↓
completion sound
      ↓
confetti
      ↓
balloon mini game
      ↓
sticker reward
      ↓
album update
      ↓
next puzzle
```

Kutlama sekansı:

**[ZORUNLU]**

* atlanabilir
* ekrana dokunmak sekansı hızlandırabilir
* çocuk gereksiz yere bekletilmez

*Faz 18'de (K-6):* sticker ödülünden sonra, sonraki puzzle'dan önce boyama safhası gelir (§24.2). Sticker yalnızca ilk bitirişte verilir; boyama **her** bitirişte gelir, Serbest Mod dahil.

---

# 24. BALLOON MINI GAME

Ayrı bir feature modülüdür. Puzzle feature'ına bağımlı olmaz.

**[ZORUNLU]** — *Faz 17'de değişti (K-5): tek dokunuş değil, renk eşleştirme*

```text
Idle floating
 ↓
Tap → balon seçilir (büyür, hafifçe sallanır)
 ↓
Aynı renkten başka bir balona tap
 ├── aynı renk → ikisi birlikte: scale → pop sound → particle → disappear
 └── farklı renk → seçim sessizce yeni balona geçer
```

* Seçili balona tekrar dokunmak hiçbir şey yapmaz (çift dokunuş anlamı taşımaz, §2).
* Farklı renkte ikinci dokunuş bir hata değildir: ses yok, titreşim yok, "yanlış" yok (§20).
* Seçim yalnızca renkle değil **boyut ve hareketle** gösterilir.
* Bir balon **3 saniye** seçili kalırsa eşlerinden biri hafifçe nabız atar. Okuma bilmeyen çocuk kuralı böyle öğrenir.

**[ZORUNLU]**

* maksimum **10** aktif balon — *K-11'de 8'den çıktı; on balonun hepsi aynı anda sahnede olabilir*
* minimum hit target 72 px
* maksimum süre 15 saniye

**[ZORUNLU] — Bitiş ve spawn kuralı** — *v2.2'de eklendi, Faz 17'de değişti*

* Oyun toplam **10 balon** üretir: **5 renk çifti** (K-11). Bir çiftin iki balonu aynı anda ve aynı renkte doğar.
* Çiftlerin renkleri **rastgeledir**: palet her oyunda karıştırılıp dağıtılır, çift sayısı renk sayısını aşmadıkça iki çift aynı renkte olmaz. (Tamamen rastgele renkler bütün çiftleri aynı renge boyayabilir ve eşleştirmeyi ortadan kaldırırdı.)
* Spawn: başlangıçta **2 balon (1 çift)**, sonra **0,6 sn'de bir çift**; balon **0,6 sn'de** yükselir. Son çift 2,4. saniyede doğar, **3. saniyede bütün balonlar yerindedir** (K-11).
* Ekranda her rengin balon sayısı her an **çifttir**: eşi olmayan bir balon asla kalmaz.
* Bitiş koşulu, hangisi önce olursa:
  * 10 balonun tamamı patlatıldı → **500 ms sonra kapanır** (erken bitiş ödüldür)
  * 15 saniye doldu → kapanır
* Ekranda patlatılmamış balon kalması bir başarısızlık değildir; hiçbir geri bildirim verilmez (§20).

İleride renk/sayı/şekil bulma gibi mini oyunlara genişletilebilir.

## 24.2 Boyama safhası

*Faz 18'de eklendi.* Kararlar: K-6, K-7, K-8, K-9, K-10 (§0.3).

Ayrı bir feature modülüdür (`features/colouring/`). Puzzle dahil hiçbir feature'a bağımlı olmaz; puzzle ekranı onu kullanır.

```text
Sticker ödülü (ya da sticker yoksa balonların hemen ardından)
 ↓
Beyaz kâğıt üstünde siyah çizgili araba + serbest renk paleti + köşede "geç" oku
 ↓
Paletten renk seç (mavi baştan seçili) → arabanın bir parçasına dokun
 ↓
Parça boyanır → kısa ses → ~0,9 sn
 ├── araba bitmedi → sonraki puzzle
 └── araba bitti → tamamlanma sesi → araba ekrandan sürülerek çıkar → sonraki puzzle
```

**[ZORUNLU]**

* Boyama **her** puzzle bitişinde gelir, Serbest Mod dahil. Sticker yalnızca ilk bitirişte verilir (§25).
* Her bitişte **bir** parça boyanır. *K-15:* boyanmış parça **kilitlidir**, yalnızca beyaz bir parça boyanabilir — beş safha beş parçadır.
* *K-15:* arabanın **son safhasında** (5.) boyamadan ya da geçildikten sonra araba — beyaz parçası kalsa bile — sürülüp gider; sıradaki arabaya geçmeye oyun karar verir, boyama sayfası değil.
* *K-15:* **3 araba** bitince oyun sonu: bu oyunda biten arabalar yan yana gelir (konfetiyle), bir süre sonra ya da dokununca Home'a dönülür ve yeni oyun hazırlanır. Geri tuşu da aynı yere götürür (§30).
* Safha **atlanabilir** (§23): "geç" oku hemen sonraki puzzle'a geçer, hiçbir şey boyanmaz. Kâğıda ya da boş alana dokunmak hiçbir şey yapmaz, bir şey söylemez (§20).
* Renk **serbest bir paletten** seçilir (K-9). Dikey ekranda palet altta: tonlar enine, açıklık boyuna; yatay ekranda sağda: tonlar boyuna, açıklık enine. Yanında beyazdan siyaha gri şerit. Dokunmak ve sürüklemek aynı şeyi yapar: parmağın altındaki renk seçilir; şeritten taşan parmak kenardaki rengi seçer.
* Palette **çizilen renk, boyanan rengin kendisidir** — otomatik test ekran piksellerini seçilen renkle karşılaştırır.
* Seçili renk yalnızca renkle değil, dokunulan noktada duran **siyah-beyaz çift çerçeveli bir halkayla** gösterilir.
* Seçilen renk ayrıca **sol üst köşedeki çerçeveli bir karede** görünür (K-10); parmak palette gezerken kare de anında değişir. Kare dokunuşa kapalıdır. Yatay ekranda "geç" oku karenin altına iner.
* Boya, palet sırası olarak değil **renk değeri (opak ARGB)** olarak saklanır.
* Araba **hacimli** görünür (K-17): parça dolgusu düz değildir, üstünde açıktan koyuya bir perde vardır ve araba yere gölge düşürür. Perde çizginin altında kalır; parçanın orta bandında seçilen renk birebir görünür.
* Araba **kodla çizilir** (K-7). Her model 5–6 parçadır; her parçanın görünen alanına en dar ekranda (320 dp) bile 64 px'lik bir daire sığar (§2, K-8) — otomatik test eder.
* 5 model sırayla gelir — sedan, kamyonet, yarış arabası, kamyon, traktör (K-13); sonuncudan sonra ilkine dönülür. Her modelin tam **5** parçası vardır (safha sayısı; testle korunur). Defter en son biten 3 arabayı hatırlar (oyun sonu için).
* Boyama durumu **ayrı bir anahtarda** saklanır (`emoji_puzzle.colouring`), `GameProgress`'te değil: feature bağımsızlığı korunur ve §25.1 şema değişikliği ilerlemeyi silmez. Bozuk kayıt → ilk araba, boş (§25.1'in ruhu).
* §26 ilerleme sıfırlaması boyama defterini de ilk arabaya, boş olarak döndürür.
* Geri tuşu (§30): safha kesilir, boyanan parça kalır, sonraki puzzle hazırlanır.
* Bekleme ve sürme animasyon denetleyicisiyle yapılır, `Timer` ile değil: uygulama arka plandayken durur (§28).
* Paletteki kırmızı bir boya rengidir; §2'nin yasakladığı hata işareti değildir.

---

# 25. PROGRESS VE STICKER ALBUM

> *K-15 — şema 2:* `unlockedLevel` kalktı; `stage` (0–4), `carsFinished` (bu oyunda), `playedThisGame` (bu oyunda gelmiş resimler) ve `currentSolved` (puzzle çözüldü ama safhanın dizisi bitmedi — açılışta safha ilerletilir) geldi. Şema 1'den geçişte **çıkartmalar korunur**, oyun baştan başlar. Albüm aynı kalır: bir resmi ilk kez bitirmek çıkartmasını verir.

**[ZORUNLU]** — *v2.2'de sadeleştirildi*

```dart
class GameProgress {
  final int unlockedLevel;
  final Set<String> completedPuzzleIds;
  final int schemaVersion;

  /// Uygulama yeniden açıldığında nereden devam edileceği.
  final String? lastPlayedPuzzleId;

  /// Türetilmiş veri — ayrı saklanmaz.
  Set<String> get unlockedStickerIds => completedPuzzleIds;
}
```

`unlockedStickerIds` artık persist edilmez. "Tamamlanan puzzle = sticker" kuralı tek kaynaktan türetilir; iki set'in desenkronize olma ihtimali ortadan kalkar.

Persistence:

```text
SharedPreferences
      ↓
tek JSON string
```

## 25.1 Schema politikası

**[ZORUNLU]** — *v2.2'de eklendi*

```text
okunan schemaVersion == güncel   → normal yükle
okunan schemaVersion <  güncel   → migration çalıştır
                                    (migration yoksa → fresh progress)
okunan schemaVersion >  güncel   → fresh progress (downgrade senaryosu)
parse hatası                     → debug log → fresh progress
```

Çocuğa hiçbir durumda hata gösterilmez.

Album kategorilere göre gruplanır. Kazanılmamış stickerlar gri silüet olarak gösterilir.

---

# 26. PROGRESS RESET

**[ZORUNLU]**

Storage katmanı progress temizleme capability'sine sahip olmalıdır:

```dart
clearProgress()
```

MVP'de çocuk-facing UI'da gösterilmek zorunda değildir. İleride ebeveyn alanı tarafından kullanılabilir.

Reset işlemi:

```text
completedPuzzleIds  → empty
unlockedLevel       → 1
lastPlayedPuzzleId  → null
```

haline getirir.

---

# 27. AUDIO VE HAPTICS

**[ZORUNLU]**

Widget içinde `AudioPlayer` oluşturulmaz. Merkezi `AudioService` kullanılır.

```dart
AudioService.playPieceSnap();
AudioService.playPuzzleComplete();
AudioService.playBalloonPop();
AudioService.playHint();
```

Asset:

```text
assets/audio/
├── sfx/
├── voice/
└── music/
```

Haptic Flutter'ın kendi API'si ile yapılır:

```dart
HapticFeedback.selectionClick();
HapticFeedback.lightImpact();
HapticFeedback.mediumImpact();
```

Haptic hiçbir zaman gameplay'in çalışması için zorunlu değildir.

```text
Animation
   +
Audio
   +
Haptic supplementary
```

Cihaz haptic desteklemese bile oyun normal çalışmalıdır.

**[KARAR BEKLİYOR]** Mute toggle için bkz. K-2.

---

# 28. LIFECYCLE

**[ZORUNLU]**

`WidgetsBindingObserver` kullanılmalıdır.

Paused:

* müzik durur
* idle timer durur
* aktif animation controller'lar uygun şekilde durur

Resumed:

* müzik devam eder
* idle timer sıfırlanır

Drag sırasında uygulama arka plana giderse:

```text
dragging
   ↓
cancel
   ↓
piece → kendi tray slotu
   ↓
drag state temizlenir
   ↓
failedAttempts artmaz
   ↓
idle timer reset
```

Parça yanlışlıkla board üzerinde bırakılmış kabul edilmez. Kesinti bir "deneme" sayılmaz.

---

# 29. NAVIGATION

**[ZORUNLU]**

MVP'de gereksiz navigation abstraction oluşturulmaz. Standart Flutter navigation yeterlidir.

```text
Home → Puzzle → Celebration → Balloon → Sticker → Next Puzzle
```

Feature sayısı büyümediği sürece özel router abstraction oluşturulmaz.

---

# 30. ANDROID BACK DAVRANIŞI

**[ZORUNLU]** — *v2.2'de netleştirildi*

Onay dialogu kullanılmaz. Çocuk dialog okuyamaz; okuyamadığı bir soruya cevap vermeye zorlanmaz.

Puzzle ekranında:

```text
Back
 ↓
aktif drag varsa iptal et (§28 ile aynı yol)
 ↓
progress kaydedilir
 ↓
doğrudan Home'a dönülür
```

Celebration / Balloon sırasında:

```text
Back
 ↓
sekans anında sonlandırılır
 ↓
kazanılan sticker yine de verilir
 ↓
Home'a dönülür
```

Ödül asla geri alınmaz. Back bir ceza mekanizması değildir.

Home ekranında back sistem varsayılanıdır (uygulamadan çıkış).

---

# 31. ACCESSIBILITY

**[TERCİH]**

MVP görsel/dokunsal/sesli oyun olduğundan accessibility ayrı bir mimari katman olarak oyunu karmaşıklaştırmamalıdır.

Ancak:

* semantic label'lar mümkün olduğunca anlamlı olmalı
* erişilebilirlik özellikleri oyun state'ini bozmamalı
* sistem font scaling oyun layout'unu bozmamalı
* TalkBack / VoiceOver testleri ilerleyen aşamada değerlendirilmeli

Çocuk oyununun temel oynanışı erişilebilirlik servisi olmadan da çalışmalıdır.

---

# 32. İLK KULLANIM / ONBOARDING

**[TERCİH]**

Çocuk okuma bilmediğinden klasik metin tabanlı onboarding tercih edilmez.

İlk puzzle sırasında gerekirse kısa görsel sürükleme animasyonu gösterilebilir:

```text
Parça → hedef → snap → 🎉
```

Bu mekanizma bir eğitim ekranına dönüşmemelidir. MVP'de uygulanmasa bile mimari ileride eklenmesine engel olmamalıdır.

---

# 33. ASSET VE LİSANS

**[ZORUNLU]**

Emoji/görsel asset'leri platform emoji glyph'lerinden alınmaz. `Text("🍎")` kullanılmaz.

Kullanılabilecek kaynaklar:

* Noto Emoji — uygun lisans koşullarıyla
* OpenMoji — lisans ve attribution koşullarıyla
* Twemoji — lisans ve attribution koşullarıyla
* Projenin kendi çizimi — kodla üretilir, üreten betik repoda durur (K-16)

Seçilen asset setinin lisansı, attribution metni ve kaynak adresi `assets/LICENSES.md` içinde tutulur. Ses asset'leri için de aynı prensip geçerlidir.

---

# 34. ASSET ÜRETİM PIPELINE

**[ZORUNLU]**

```text
Source artwork → 1024×1024 → 1:1 composition → transparent background
  → license verification → standard naming → assets/images/puzzles/
```

Dosya adları: `apple.png`, `cat.png`, `banana.png`, `dog.png` …

Puzzle ID ile katalog ilişkisi:

```text
apple_01 → assets/images/puzzles/apple.png
```

Asset'in runtime boyutu `PuzzleImageLoader` tarafından uygun `cacheWidth` ile optimize edilir (§14).

---

# 35. ÇOCUK UYGULAMASI VE PRIVACY

**[ZORUNLU]**

Hedef: Google Play Designed for Families, Apple Kids Category.

v1:

* reklam yok
* IAP yok
* sosyal paylaşım yok
* dış link yok
* analitik yok
* kişisel veri toplama yok
* tüm oyun progress'i cihazda
* gereksiz network izni yok
* offline çalışır

Gizlilik politikası hazırlanmalıdır.

---

# 36. PROJE KLASÖR YAPISI

```text
lib/
├── main.dart
│
├── app/
│   ├── app.dart
│   └── theme/
│       └── app_theme.dart
│
├── core/
│   ├── constants/
│   │   ├── app_strings.dart
│   │   └── puzzle_config.dart
│   ├── services/
│   │   ├── audio_service.dart
│   │   ├── haptic_service.dart
│   │   ├── storage_service.dart
│   │   └── puzzle_image_loader.dart
│   └── utils/
│
└── features/
    ├── puzzle/
    │   ├── models/          ← EdgeType, PieceStatus, PuzzleCategory dahil
    │   ├── engine/
    │   │   ├── geometry/
    │   │   └── path/
    │   ├── data/
    │   ├── providers/
    │   ├── widgets/
    │   └── screens/
    │
    ├── celebration/
    ├── balloon/
    ├── album/
    └── home/
```

**[TERCİH]** — *v2.2'de değişti*

Puzzle domain'ine ait enum'lar (`EdgeType`, `PieceStatus`, `PuzzleCategory`) `core/enums/` yerine `features/puzzle/models/` altında tutulur. Bunlar puzzle domain'inin parçasıdır; `core`'a taşınmaları core → feature bağımlılığı yaratır. Gerçekten feature'lar arası paylaşılan bir enum çıkarsa o zaman `core/enums/` açılır.

**[ZORUNLU]**

Gereksiz abstraction oluşturulmaz. Tek implementasyonu olan interface yazılmaz. Proje büyüdükçe klasör yapısı gerektiğinde refactor edilebilir.

---

# 37. PAKETLER

**[ZORUNLU]**

v1 onaylı liste:

```yaml
provider:
audioplayers:
shared_preferences:
confetti:
```

Bu listeye yeni paket eklemeden önce bana sor.

**[TERCİH]** Her paket, ilk kez ihtiyaç duyulduğu fazda eklenir; hepsi Faz 1'de eklenmez:

```text
provider           → Faz 4
shared_preferences → Faz 8
audioplayers       → Faz 9
confetti           → Faz 11
```

Kullanılmayan paket:

```text
flutter_animate
lottie
drag & drop paketleri
```

Drag sistemi `GestureDetector` + `Stack` + lokal drag layer ile yazılır. Haptic için paket eklenmez.

---

# 38. STATE MANAGEMENT

**[ZORUNLU]**

Provider + ChangeNotifier.

```text
UI → Provider → Service → Repository / Local Storage
UI ↕ Provider ↕ Puzzle Engine
```

Engine state tutmaz.

```text
AppState             loading | ready | error
PuzzleSessionState   idle | dragging | snapping | completed
PieceStatus          inTray | dragging | snapping | placed
```

Drag position Provider üzerinden her frame taşınmaz.

---

# 39. PROVIDER SORUMLULUK SINIRI

**[ZORUNLU]**

`GameProvider` zamanla sınırsız büyütülmemelidir.

Provider'ın sorumluluğu:

* oyun state'ini yönetmek
* puzzle session state'ini değiştirmek
* gerekli service'leri çağırmak
* UI'ın ihtiyaç duyduğu state'i yayınlamak

Provider içinde **yapılmaz**:

* puzzle geometrisi
* Path üretimi
* asset decode (→ `PuzzleImageLoader`)
* tray layout hesabı (→ `TrayLayoutCalculator`)
* audio implementation
* persistence parsing
* karmaşık rendering

---

# 40. RESPONSIVE TASARIM

**[ZORUNLU]**

`LayoutBuilder` + `MediaQuery`.

```dart
board = min(
  availableWidth,
  availableHeight * PuzzleConfig.boardHeightFactor, // 0.6
  PuzzleConfig.maxBoardSize,                        // 500
);
```

Board kare kalır. Tablet: max 500×500, centered.

**[ZORUNLU]** — *K-15'te eklendi:* yukarıdaki boyda tepsi her parçayı 64 px'te tutamıyorsa board, tutabileceği en büyük boya kadar 2 px adımlarla küçülür; en uzun kenarındaki hücre 64 px'in altına inecek kadar küçülmez. Ödün sırası: dokunma hedefi (asla) > kaymayan tepsi (asla) > board boyu. Hesap `engine/geometry/board_fitter.dart`'tadır ve testlidir.

Test edilecek ekranlar:

```text
≤360 dp telefon   ← kritik referans, tray sınırı burada belirlenir
normal telefon
≥600 dp tablet
```

`SafeArea` zorunludur.

**[ZORUNLU]** Board hesabından artan alan tray'e gider ve `TrayLayoutCalculator`'a girdi olur (§16.1). Board sabit, tray artık değildir; ikisi birlikte çözülür.

---

# 41. TEST STRATEJİSİ

**[ZORUNLU]**

Testler sona bırakılmaz. Engine testleri ilgili faz ile birlikte yazılır.

Parça sayısı:

```text
1×3 → 3   (engine desteği, içerikte kullanılmıyor)
2×2 → 4
2×3 → 6
3×3 → 9
3×4 → 12  (engine desteği)
```

Edge:

```text
dış sınır → flat
komşu     → complementary (yatay ve dikey)
flat'in complement'i → flat
```

Determinism:

```text
aynı seed → birebir aynı parça listesi
```

**[ZORUNLU] — Farklı seed testi istatistikseldir** — *v2.2'de değişti*

"Farklı seed → farklı dizilim" **tek çift seed ile test edilmez**. 1×3 gridde yalnızca 2 iç kenar, yani 4 olası dizilim vardır; iki farklı seed'in aynı sonucu vermesi normaldir ve test flaky olur.

Doğru test:

```text
3×3 grid (12 iç kenar)
50 farklı seed
→ en az 40 benzersiz dizilim üretilmeli
```

Koordinat:

```text
normalizedPosition ∈ [0, 1)
normalizedPosition doğru hücreyi temsil ediyor
normalized ↔ pixel dönüşümü tolerans içinde tersinir
piece origin = cell origin - (tabSize, tabSize)
grab offset round-trip doğru
```

Tray layout:

```text
4 / 6 / 9 parça, 360×640 dp → itemSize >= 64
9 parça → 3×3 yerleşim
12 parça → çözüm yok (assert)
aynı seed → aynı slot dağılımı
```

Snap:

```text
merkez mesafesi eşik içinde → true
eşik dışında → false
yanlış yuva → her zaman false
assist >= 3 → eşik × 1.8
```

Progress:

```text
save → read → equal
invalid JSON → fresh progress
schemaVersion > current → fresh progress
clearProgress → initial state
```

Mimari:

```text
engine/ altındaki hiçbir dosya package:flutter/material.dart,
widgets.dart veya cupertino.dart import etmiyor
```

Bu test dosya içeriğini okuyarak yapılır, gözle değil.

Widget test:

* tray render
* drag start
* drag layer
* snap
* placed count
* completion

Lifecycle testleri ilgili state davranışlarını doğrulamalıdır.

---

# 42. PERFORMANS

**[ZORUNLU]**

* Puzzle image bir kez decode edilir, puzzle boyunca paylaşılır.
* Path cache kullanılır; build içinde Path üretilmez.
* Drag edilen parça ayrı repaint alanında tutulur.
* Maksimum 40 particle.
* AnimationController'lar dispose edilir.
* Provider her drag frame'inde notify edilmez.

Performans hedefi:

> Orta seviye referans Android cihazında puzzle sürükleme sırasında belirgin jank/frame drop olmamalıdır.

"Her cihazda mutlak 60 FPS" garanti kriteri değildir.

**[TERCİH]** İlk profiling Faz 17'de değil, **Faz 5 sonunda** gerçek cihazda yapılır. Drag mimarisi yanlışsa bunu 11 faz sonra öğrenmek pahalıdır.

---

# 43. GELİŞTİRME YÖNTEMİ

**[ZORUNLU]**

Proje tek seferde tamamlanmaz.

Her faz için:

1. Fazın amacını açıkla.
2. Mimari kararın gerekçesini kısa anlat.
3. Dosyaları oluştur.
4. Kodu yaz.
5. Kendi kodunu gözden geçir.
6. Olası hataları belirt.
7. Testleri çalıştır.
8. Kabul kriterlerini tek tek kontrol et.
9. Fazı özetle.
10. Onay iste.

Kabul kriterleri karşılanmadan sonraki faza geçilmez.

Kod devasa bloklar halinde verilmez. Küçük, çalıştırılabilir adımlarla ilerlenir.

Yalnızca kod verilmez. Önemli mimari kararların mantığı kısa ve anlaşılır şekilde açıklanır.

Kullanıcı kodu kendisi yazmak zorunda değildir; AI kodu yazabilir. Ancak yapılan kodun ve mimarinin anlaşılması sağlanmalıdır.

**[ZORUNLU] — Testleri çalıştıramıyorsan bunu açıkça söyle**

Ortamında Flutter SDK yoksa "testler geçti" deme. Testleri yaz, çalıştırılamadığını belirt, hangi komutun çalıştırılması gerektiğini yaz. Doğrulanmamış bir iddia, doğrulanmamış koddan daha zararlıdır.

---

# 44. FAZ PLANI

| Faz | İçerik | Kabul kriteri |
| --- | ------ | ------------- |
| **1** | Proje kurulumu + klasör + config + modeller + geometry + coordinate contract + unit tests | Tüm grid/edge/determinism/coordinate testleri yeşil |
| **2** | JigsawPathGenerator + tab taşması + src/dst coordinate contract + Path cache | Path boyutları doğru, tab'lar kırpılmıyor |
| **3** | Statik 4 parçalık önizleme + kenar dikişi kontrolü | Gerçek jigsaw parçaları doğru birleşiyor, görünür dikiş yok |
| **4** | Provider + GameProvider + PieceRuntimeState + TrayLayoutCalculator + TrayShuffler + ghost + slot outline | Board ve tray doğru render, 4/6/9 parça 360 dp'de ≥64 px |
| **5** | Drag layer + grab offset + z-order + drag animation + **ilk profiling** | Parça akıcı sürükleniyor, board rebuild olmuyor |
| **6** | SnapCalculator + rubber-band + assist | Doğru snap, yanlışta cezasız dönüş |
| **7** | PuzzleDefinition + LevelDefinition + catalog + level flow | 3 kademe / 9 puzzle çalışıyor |
| **8** | SharedPreferences progress + schema politikası | Kapanıp açılınca progress korunuyor |
| **9** | AudioService + HapticService + feedback | Ses/haptic/feedback çalışıyor |
| **10** | HintController + 4 aşamalı idle hint | 8/16/24/32 sn sistemi doğru |
| **11** | Completion + confetti + celebration | Kutlama baştan sona çalışıyor |
| **12** | Balloon mini game | Balonlar çalışıyor, erken bitiş ve 15 sn timeout |
| **13** | Album + Home + Serbest Mod + progress reset capability | Album/progress/free mode çalışıyor |
| **14** | Navigation + Android Back + lifecycle | Ekran geçişleri ve interruption güvenli |
| **15** | Responsive + tablet + accessibility smoke test | Farklı ekranlarda layout bozulmuyor |
| **16** | Asset/license audit + privacy + test tamamlaması + final polish | Tüm testler yeşil, belirgin jank yok, lisanslar tamam |
| **17** | Balon renk eşleştirme (K-5; K-11 ile 10 balon, 3 sn) | Aynı renk çifti birlikte patlıyor, yanlış renkte seçim sessizce geçiyor, eşi olmayan balon kalmıyor |
| **24** | Puzzle parçalarında kabartma ve gölge (K-19) | Parçanın üst kenarı ışıklı, alt kenarı gölgeli; kabartma parçanın dışına taşmıyor; tamamlanan resimde dikiş görünüyor |
| **23** | Safhayı boyama ilerletir (K-18) | Atlanan sayfa safhayı ilerletmiyor, resim değişiyor; beş boyamada araba bitiyor; kayıt ve yarıda çıkış aynı kuralı izliyor |
| **22** | Boyama arabalarında hacim gölgesi ve yere düşen gölge (K-17) | Parçanın üstü açık, altı koyu; seçilen renk orta bantta birebir; çizgi siyah kalıyor; gölge yalnızca arabanın altında |
| **20b** | Kitap, mikroskop, dürbün kodla çizildi; havuz 21 (K-16) | Üç resim Eşyalar'da, lisans kaydı tamam, §34 biçimi testle korunuyor |
| **21** | Yeni oyun kuralları: 5 safha, 3 araba, rastgele resim, board sığdırma (K-15) | 2×2→4×4 safhalar oynanıyor, araba 5. safhada gidiyor, 3 arabada oyun sonu, 4×4 küçük telefonda 64 px |
| **20** | Kamyon, traktör; Eşyalar kategorisi (K-13, K-14) | 5 araba modeli ölçümü geçiyor, Eşyalar'ın kendi gradyanı var |
| **19** | 9 yeni puzzle, 18'e çıkış (K-12) | 18 puzzle 3 kademede oynanıyor, albümde doğru kategoride, lisanslar tamam |
| **18** | Boyama safhası (K-6, K-7, K-8) | Her bitirişte bir parça boyanıyor, atlanabiliyor, boyama kalıcı, araba bitince yeni model |

**[TERCİH]**

Faz sırası gerektiğinde değiştirilebilir. Ancak değişiklikten önce:

```text
Mevcut mimariyi değerlendir → Etkiyi belirle → Gerekirse refactor → Entegre et → Devam et
```

korunmalıdır.

---

# 45. PLANIN ESNEKLİĞİ

**[ZORUNLU]**

Plana körü körüne bağlı kalınmaz.

```text
Yeni gereksinim
      ↓
Mevcut mimariyi değerlendir
      ↓
Etkilenen fazları belirle
      ↓
Gerekirse küçük refactor
      ↓
Entegre et
      ↓
Test
      ↓
Devam
```

Gereksiz büyük refactorlardan kaçınılır.

`[ZORUNLU]` bir karar değiştirilecekse **önce kullanıcıya sorulur.** Bir `[ZORUNLU]` kural başka bir `[ZORUNLU]` kuralla çakışıyorsa sessizce birini tercih etme; çakışmayı bildir ve sor.

---

# 46. KODLAMA PRENSİPLERİ

**[ZORUNLU]**

Kod okunabilir, modüler, test edilebilir, null-safe ve Dart standartlarına uygun olmalıdır.

* Bir sınıf, bir sorumluluk.
* UI ve oyun mantığı ayrı.
* Puzzle matematiği widget içinde yazılmaz.
* Magic number kullanılmaz.
* Eşikler `PuzzleConfig` içinde tutulur.
* Tek implementasyonu olan interface yazılmaz.
* Engine widget import etmez.
* Provider rendering işini üstlenmez.
* Service'ler UI state'i doğrudan değiştirmez.
* Her `PuzzleConfig` sabiti hangi spec bölümünden geldiğini yorumda belirtir.

---

# 47. İLERİDE EKLENEBİLECEKLER

**[OPSİYONEL]**

* yeni kategoriler (colors, numbers)
* renk / şekil / sayı bulma mini oyunları
* aynısını bul
* 12 / 16 parçalık puzzle (tray scroll veya landscape gerektirir)
* çok dillilik
* gelişmiş ebeveyn alanı
* ses/müzik ayarları
* zorluk ayarı
* progress reset UI
* ebeveyn kapısı
* landscape
* gelişmiş accessibility

Bunlar MVP kapsamına dahil değildir.

---

# 48. İLK GÖREV — FAZ 1

Şimdi yalnızca **FAZ 1** yapılacaktır.

## Yapılacaklar

1. Flutter proje iskeletini ve §36 klasör yapısını oluştur.
2. `pubspec.yaml` ve `analysis_options.yaml` oluştur (yalnızca `flutter_lints`; §37).
3. `PuzzleConfig` oluştur.
4. `EdgeType` enum'unu ve `complement` davranışını oluştur.
5. `PuzzleGrid` modelini oluştur (`idOf` dahil).
6. `PuzzlePiece` modelini oluştur (immutable, `flatEdgeCount` dahil).
7. `CoordinateMapper` oluştur (§8, §9 sözleşmeleri).
8. Coordinate contract testlerini yaz.
9. `EdgeResolver` oluştur.
10. `PuzzleGenerator` oluştur.
11. `Random` dependency injection uygula.
12. 1×3, 2×2, 2×3, 3×3 ve 3×4 gridlerini destekle.
13. Engine unit testlerini yaz (§41).
14. Engine saflık testini yaz (import kontrolü).
15. Testleri çalıştır — çalıştıramıyorsan §43'teki kurala uy.
16. Kodun kendi review'unu yap.
17. Kabul kriterlerini tek tek kontrol et.

## Yapılmayacaklar

* Drag & drop yok.
* Provider yok.
* `PieceRuntimeState` yok (Faz 4).
* `SnapCalculator` yok (Faz 6).
* `TrayLayoutCalculator` yok (Faz 4).
* Path üretimi yok (Faz 2).
* UI yok. `main.dart` yalnızca derlenebilirlik için minimal placeholder olabilir.
* Audio, haptic, confetti, sticker, balloon, navigation yok.
* Puzzle katalog içeriği yok (Faz 7).

---

# 49. FAZ 1 KABUL KRİTERLERİ

```text
✓ 1×3 → 3 parça
✓ 2×2 → 4 parça
✓ 2×3 → 6 parça
✓ 3×3 → 9 parça
✓ 3×4 → 12 parça

✓ Dış sınır kenarları flat
✓ Yatay komşu kenarlar complementary
✓ Dikey komşu kenarlar complementary
✓ flat.complement == flat

✓ Aynı seed → birebir aynı parça listesi
✓ 3×3'te 50 seed → en az 40 benzersiz dizilim

✓ id == row * columns + column
✓ id'ler 0..n-1, boşluksuz ve tekil

✓ normalizedPosition ∈ [0, 1)
✓ normalizedPosition hücre sol üstünü temsil ediyor (path sol üstünü değil)
✓ normalized ↔ pixel dönüşümü tolerans içinde tersinir
✓ tabSize == min(cellW, cellH) × 0.20
✓ pieceSize == cellSize + 2 × tabSize
✓ piece origin == cell origin - (tabSize, tabSize)
✓ grab offset round-trip doğru

✓ PuzzlePiece immutable (tüm alanlar final, const constructor)
✓ Engine hiçbir Flutter widget kütüphanesi import etmiyor (otomatik test)
✓ Random inject edilebilir
✓ Magic number yok
✓ PuzzleConfig kullanılıyor
✓ flutter analyze temiz

✓ flutter test yeşil
```

**FAZ 1 kabul edilmeden FAZ 2'ye geçilmez.**

---

# 50. ANA GELİŞTİRME FELSEFESİ

```text
DOĞRU MATEMATİK
       ↓
DOĞRU KOORDİNAT SİSTEMİ
       ↓
DOĞRU PATH
       ↓
DOĞRU GÖRSEL
       ↓
DOĞRU DRAG
       ↓
DOĞRU SNAP
       ↓
DOĞRU STATE
       ↓
DOĞRU FEEDBACK
       ↓
DOĞRU OYUN AKIŞI
       ↓
PERFORMANS
       ↓
POLISH
```

Amaç yalnızca çalışan bir puzzle yapmak değildir.

Amaç:

> **3–5 yaşındaki bir çocuğun okuyamadan, hata yapmaktan korkmadan, tamamen dokunma + görsel + ses yoluyla oynayabileceği; teknik olarak temiz, test edilebilir, performanslı ve ileride büyütülebilir bir Flutter oyun altyapısı oluşturmaktır.**

**Önce doğru matematik, sonra doğru koordinat sistemi, sonra görsel, sonra gameplay.**

---

# 51. ŞİMDİ NE YAPACAKSIN

Bu dokümanı okudun.

1. Önce **§0.2 AÇIK KARARLAR**'daki K-1 ile K-4'ü bana sor. K-1 cevaplanmadan Faz 7'ye, diğerleri cevaplanmadan ilgili faza geçme. Faz 1 bunların hiçbirine bağlı değildir; K-1'i sorduktan sonra cevabı beklemeden Faz 1'e başlayabilirsin.
2. **§48 Faz 1**'i uygula.
3. **§43**'teki 10 adımlık yöntemi harfiyen izle.
4. **§49**'daki kabul kriterlerini tek tek, tik atarak kontrol et.
5. Onay iste. Onay almadan Faz 2'ye geçme.

Emin olmadığın her noktada tahmin etme, sor.
