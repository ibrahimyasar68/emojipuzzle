# Devam Notu — EmojiPuzzle

Bu dosya, yeni bir sohbette kaldığı yerden devam edebilmek için yazıldı.
Son güncelleme: 20 Eylül 2026, giriş ekranı yenilendi (K-21) ve Play hazırlığı gözden geçirildi.

> **Yeni sohbete başlarken:** `docs/spec-v2.2.md` ile bu dosyayı okut.
> Spec artık repoda — yapıştırmaya gerek yok.

---

## 1. Nerede kaldık

| Faz | İçerik | Durum |
| --- | ------ | ----- |
| 1 | Modeller, geometri, koordinat sözleşmeleri | ✅ onaylandı |
| 2 | JigsawPathGenerator, PiecePaths cache, src/dst sözleşmesi | ✅ onaylandı |
| 3 | Statik önizleme, kenar dikişi çözümü | ✅ onaylandı |
| 4 | Provider, PieceRuntimeState, TrayLayoutCalculator, ghost | ✅ onaylandı |
| 5 | Drag layer, grab offset, debug overlay | ✅ onaylandı |
| 6 | SnapCalculator, rubber-band, assist | ✅ onaylandı |
| 7 | Katalog, kademe akışı (+ gerçek OpenMoji görselleri) | ✅ onaylandı |
| 8 | SharedPreferences kalıcılık, §25.1 şema politikası | ✅ onaylandı |
| 9 | AudioService, HapticService, §22 geri bildirim | ✅ onaylandı |
| 10 | HintController, 4 aşamalı idle hint | ✅ onaylandı |
| 11 | Kutlama + konfeti (atlanabilir) | ✅ onaylandı |
| 12 | Balon mini oyunu | ✅ onaylandı |
| 13 | Album, Home, Serbest Mod, progress reset | ✅ onaylandı |
| 14 | Navigation, Android Back, lifecycle | ✅ onaylandı |
| 15 | Responsive, tablet, accessibility | ✅ onaylandı |
| 16 | Asset/lisans denetimi, privacy, final cila | ✅ onaylandı |
| 17 | Balon renk eşleştirme | ✅ onaylandı |
| 18 | Boyama safhası (araba) | ✅ onaylandı |
| 19 | 9 yeni puzzle (18'e çıkış) | ✅ onaylandı |
| 20 | Kamyon, traktör; Eşyalar kategorisi | ✅ commit; görseller 17 Eylül'de kodla çizildi (K-16) — tamamlandı |
| 21 | Yeni oyun kuralları: 5 safha, 3 araba | ✅ onaylandı |
| 22 | Boyamada hacim gölgesi + yere gölge (K-17) | ✅ onaylandı |
| 23 | Safhayı boyama ilerletir (K-18) | ✅ onaylandı |
| 24 | Puzzle parçalarında kabartma (K-19) | ✅ onaylandı |
| 25 | Play Store hazırlığı (K-20) | ⏳ imza anahtarı kullanıcıda |
| 26 | Giriş ekranı + yetişkin kapısı + İngilizce metin (K-21) | ⏳ onay bekliyor |

**Durum:** `flutter analyze` temiz, `flutter test` yeşil — **1171 test**.
`lib/` altındaki bütün kod yorumları Türkçe.
Yirmi sekiz commit, **GitHub'da yayında**:
<https://github.com/ibrahimyasar68/emojipuzzle> (public). CI push'ta çalışıyor.

---

## 2. Verilmiş kararlar (tekrar sorma)

- **K-1 = A** — 3 kademe: 2×2, 2×3, 3×3. Engine 1×3 ve 3×4'ü
  desteklemeye devam ediyor ama içerikte yoklar. **K-12** (15 Eylül) ile
  her kademede **6 puzzle, toplam 18**.
- **K-2 = evet** — mute `AudioService` içinde ve kalıcı. Home'daki düğme Faz 13'te.
- **K-3 = evet** — `.github/workflows/ci.yml` hazır (format + analyze + test).
- **K-4 = evet** — debug overlay yapıldı, `debugShowPuzzleOverlay` bayrağıyla.
- **Görseller = OpenMoji**, CC BY-SA 4.0, **618×618** (kullanıcı §34'ün 1024
  hedefinden sapmayı onayladı; SVG'den render için `librsvg` kurulu değil).
- **Sesler = sentezlenmiş**, indirilmedi: `dart run tool/generate_sfx.dart`.
- **16 fazdan sonra iki yeni safha** (15 Eylül, spec §0.3):
  - **K-5** — balon oyunu renk eşleştirmedir; farklı renkte ikinci dokunuşta
    seçim sessizce yeni balona geçer.
  - **K-6** — sticker'dan sonra **atlanabilir** boyama safhası: kutlama →
    balon → sticker → boyama → sonraki puzzle. Boyama her bitirişte gelir.
  - **K-7** — boyama çizimleri (siyah çizgili arabalar) **kodla** çizilir.
  - **K-8** — boyama ekranında §2'nin 5 öğe sınırı esner: renk seçimi + ~6 parça.
  - **K-9** — renk **serbest paletten** seçilir (kullanıcı Faz 18 sırasında
    istedi, K-8'in "6 renk"ini değiştirdi): ton×açıklık şeridi + gri şerit.
  - **K-11** — balon oyunu **10 balon** (5 çift), hepsi **3 sn'de** sahnede,
    çift renkleri **rastgele** (kullanıcı istedi: giriş uzun, balon çoktu).
    §24'ün [ZORUNLU] "en fazla 8 aktif balon"u 10'a çıktı.
  - **K-15** — **yeni oyun kuralları** (kullanıcı istedi; kademeler bitti):
    bir oyun 3 araba, bir araba 5 safha. Her safhada havuzdan rastgele resim
    (bir oyunda tekrar yok), ebat safhadan: 2×2 → 2×3 → 3×3 → 4×3 → 4×4.
    Safha sonunda bir parça boyanır; boyanan parça kilitli, geç oku kalır.
    5. safhadan sonra araba nasıl olursa olsun gider. 3 arabada oyun sonu:
    biten arabaların geçidi + konfeti → Home → yeni oyun; arabalar sırayla
    devam. Board gerektiğinde küçülür (64 px ve kaymayan tepsi korunur).
    Albümden seçilen resim o safhanın ebadıyla oynanır.
  - **K-21** — **giriş ekranı** (kullanıcı 20 Eylül'de istedi): oyna düğmesi
    gülen suratın dört parçalı bitmiş yapbozu + sağ altta kırmızı oynat
    işareti; ⓘ iki saniye basılı tutunca açılır (dolan halka); Hakkında'da
    oyunun kısa tarifi, IY Labs ve ibrahimyasar68@hotmail.com; mağaza
    metni ikinci dil olarak İngilizce.
  - **K-20** — **Play Store yayını** (kullanıcı 20 Eylül'de istedi):
    paket kimliği `com.iylabs.emojipuzzle` (eskisi
    `com.emojipuzzlekids.emoji_puzzle_kids`; ilerleme sıfırlanır, kullanıcı
    kabul etti), sürüm 1.0.0+1, ekran yönü kilidi kaldırıldı (yatay da
    açılır), yayın imzası `android/key.properties`'ten okunur — **anahtar
    kullanıcıda, henüz yok**. Adımlar: `docs/play-store-release.md`.
  - **K-19** — puzzle parçaları **kabartmalı** (kullanıcı 20 Eylül'de istedi):
    konturun içinde sol üstte ışık, sağ altta gölge; board'daki parça ayrıca
    ince gölge düşürür. **Tamamlanan resimde dikişler görünür** — §14'ün
    pürüzsüzlük hedefinden bilerek vazgeçildi.
  - **K-18** — **safhayı boyama ilerletir** (kullanıcı 20 Eylül'de istedi):
    sayfa atlanırsa safha yerinde kalır, resim değişir. Safha = o arabanın
    boyanmış parça sayısı (türetilir). Amaç: oyun sonunda boyanmamış parça
    kalmasın.
  - **K-17** — boyama arabaları **hacimli** (kullanıcı 17 Eylül'de istedi):
    her parçaya kendi sınırına kırpılmış açıktan koyuya perde, arabanın
    altına elips gölge. Perde **dolgudan sonra, çizgiden önce** çizilir.
    Perdenin ortası saydam: seçilen renk orta bantta birebir görünür
    (K-9 korunur). Sırada: puzzle parçalarında kabartma.
  - **K-16** — kitap, mikroskop, dürbün **kodla çizildi** (kullanıcı 17 Eylül'de
    istedi): `python3 tool/generate_object_images.py` (Pillow), OpenMoji
    üslubu, 1024×1024, şeffaf. §33 kaynak listesine "projenin kendi çizimi"
    eklendi — [ZORUNLU] kural değişikliği, 17 Eylül'de **onaylandı**. Havuz 21.
  - **K-14** — yeni kategori **Eşyalar** (`objects`): kitap, mikroskop,
    dürbün. §4'ün 5 kategori kuralı 6'ya çıktı. Her kademeye bir tane
    (kitap 2×2, dürbün 2×3, mikroskop 3×3). **Görselleri kullanıcı koyacak**
    (indirme izni vermedi); dürbünün Unicode emojisi yok.
  - **K-13** — boyama defterine kamyon ve traktör: 5 model, sırayla sedan,
    kamyonet, yarış, kamyon, traktör.
  - **K-12** — 9 yeni puzzle (kullanıcı istedi): çilek, ay, koyun → 2×2;
    karpuz, bisiklet, kaplumbağa → 2×3; ananas, uçak, Satürn → 3×3. Ay ve
    Satürn **doğa** kategorisinde (5 kategori kuralı korundu). Kullanıcı
    "sonra oyun kurallarını değiştireceğiz" dedi; kademe yerleşimi geçici
    olabilir.
  - **K-10** — seçilen renk sol üst köşedeki çerçeveli bir karede de
    görünür (kullanıcı istedi). Yatay ekranda "geç" oku karenin altına iner.
  - Boyama durumu `GameProgress`'e değil **ayrı bir anahtara** yazılır
    (`emoji_puzzle.colouring`; feature bağımsızlığı, şema değişince
    ilerleme silinmesin). Klasör adı `features/colouring/` — kod tabanının
    İngiliz yazımıyla (`colourIndex`, `outlineColour`) uyumlu.

---

## 3. Çalışma yöntemi (bunlar kullanıcının beklentisi)

1. **Faz kapısı:** Onay alınmadan sonraki faza geçilmez (§43, §51).
2. **[ZORUNLU] bir kural değişecekse önce sorulur** (§45). Spec içinde iki
   zorunlu kural çakışıyorsa sessizce seçim yapılmaz, bildirilir.
3. **Her faz sonunda:** amaç → mimari kararlar ve gerekçeleri → riskler →
   kabul kriterleri tek tek → test sayısı → onay isteği.
4. **Testler gerçekten çalıştırılır.** Flutter 3.35.6 bu makinede kurulu
   (`~/flutter/flutter`). "Geçti" denmeden önce koşturulur.
5. **Yeni testin boş olmadığı mutasyonla kanıtlanır:** ilgili kod bozulur,
   testin kırmızıya döndüğü gösterilir, kod geri alınır.
6. **Test kırıldığında tahmin edilmez, ölçülür** — teşhis çıktısı eklenip
   sebep bulunur. (Bu projede üç kez tahminler yanlış çıktı.)
7. **Dil:** kullanıcıya Türkçe, **kod yorumları da Türkçe** (13 Eylül'de
   değişti, spec §0 da güncellendi). Sınıf/değişken isimleri ve commit
   mesajları İngilizce kalır.
8. **İndirme veya sisteme kurulum öncesi izin istenir.**

---

## 4. Komutlar

```bash
flutter analyze
flutter test
dart format lib test tool
dart run tool/generate_sfx.dart     # ses dosyalarını yeniden üretir
python3 tool/generate_app_icon.py   # uygulama ikonunu yeniden üretir (Pillow)
python3 tool/generate_object_images.py  # kitap, mikroskop, dürbün (Pillow)
python3 tool/generate_store_graphics.py # Play öne çıkan grafiği (Pillow)
flutter build appbundle --release   # Play'e yüklenecek paket
git push                            # CI'yi tetikler
```

**Not:** `gh` bu makinede kurulu değil; depo işleri düz `git` ile yapılıyor.

Testler `build/` altına kanıt görselleri bırakır: `preview_2x2.png`,
`screen_3x3.png`, `solved_2x2.png`, `drag_overlay.png`, `hint_ghost.png`,
`placement_feedback.png`, `level2_banana.png`, `balloon_game.png`.

---

## 5. Dosya haritası

```text
docs/spec-v2.2.md                   # EMOJI PUZZLE KIDS v2.2 — tek kaynak (§0–§51)
docs/play-store-release.md          # yayın kontrol listesi (K-20)
docs/store/                         # öne çıkan grafik + 5 ekran görüntüsü
docs/privacy-policy.md              # §35 — yayımlanacak metin
docs/store-listing.md               # §33 attribution + mağaza açıklaması
docs/branding/                      # ikon kaynağı, 1024 ana görsel, Play 512
tool/generate_app_icon.py           # kaynaktan bütün ikon boyutları
lib/
├── app/app.dart                    # servisleri kurar, MultiProvider
├── app/themed_app.dart             # MaterialApp, seçilen görünüme bağlı
├── main.dart                       # StorageService açılır, sonra runApp
├── core/
│   ├── constants/puzzle_config.dart   # TÜM eşikler ve süreler, §atıflarıyla
│   ├── constants/debug_flags.dart     # debugShowPuzzleOverlay (K-4)
│   ├── theme/app_theme.dart           # AppPalette (açık/koyu), AppTheme
│   ├── theme/theme_settings.dart      # Sistem/Açık/Koyu seçimi, kalıcı
│   └── services/
│       ├── storage_service.dart       # SharedPreferences sarmalayıcı
│       ├── puzzle_image_loader.dart   # decode + cache + evict (§14)
│       ├── audio_service.dart         # §27 API + mute
│       ├── sound_player.dart          # SoundPlayer + Silent/AudioPlayers
│       └── haptic_service.dart        # §27 haptic
└── features/
    ├── puzzle/
    │   ├── models/      # PuzzlePiece, PuzzleGrid, DragState, PieceFlight,
    │   │                # HintStage, GameProgress, PuzzleDefinition, ...
    │   ├── engine/
    │   │   ├── geometry/  # generator, edge_resolver, coordinate_mapper,
    │   │                  # board_fitter (K-15: board gerektiğinde küçülür)
    │   │   │              # snap_calculator, tray_layout_calculator,
    │   │   │              # piece_image_mapper
    │   │   ├── path/      # jigsaw_path_generator, piece_paths
    │   │   ├── tray_shuffler.dart
    │   │   └── hint_target.dart
    │   ├── data/        # puzzle_catalog, puzzle_palette, progress_repository
    │                    # game_rules (K-15), katalog artık 18 resimlik havuz, ilerleme şema 2
    │   ├── providers/   # game_provider, hint_controller
    │   ├── widgets/     # board, tray, drag_layer, feedback_layer, hint_layer,
    │   │                # piece_painter, ghost_painter, debug_overlay_painter
    │   └── screens/puzzle_screen.dart
    ├── celebration/widgets/celebration_overlay.dart
    ├── balloon/                     # §24, puzzle'a bağımlı DEĞİL
    │   ├── models/balloon.dart
    │   ├── providers/balloon_game_controller.dart
    │   └── widgets/  # balloon_game_overlay, balloon_layout, balloon_painter
    ├── album/                       # §25 — puzzle'a bağımlıdır (stickerlar
    │   ├── screens/album_screen.dart          # puzzle'ların kendisi)
    │   └── widgets/  # sticker_tile, sticker_reward_overlay
    ├── colouring/                   # §24.2 — hiçbir feature'a bağımlı DEĞİL
    │   ├── models/car_model.dart      # CarPart, CarModel (100×80 birim)
    │   ├── data/      # car_catalog (3 araba, kodla), paint_colours (palet)
    │   ├── providers/colouring_book.dart  # hangi araba, hangi parça, kalıcı
    │   └── widgets/   # colouring_overlay, car_painter, colouring_layout
    │                  # car_parade_overlay (oyun sonu, K-15)
    └── home/
        ├── screens/home_screen.dart    # §29 giriş ekranı
        ├── screens/about_screen.dart   # §26 sıfırlama, §33 attribution, görünüm
        └── widgets/home_button.dart
```

---

## 6. Bozulmaması gereken mimari sözleşmeler

Bunlar pahalıya mal olmuş kararlar; yeni kod bunları ihlal etmemeli.

- **Engine saflık:** `features/puzzle/engine/` altındaki hiçbir dosya
  `material.dart` / `widgets.dart` / `cupertino.dart` import etmez. Dolaylı
  importlar dahil otomatik test eder (`test/architecture/`).
- **Koordinatlar:** `normalizedPosition` **hücrenin** sol üstüdür, path'in
  değil; `[0,1)` aralığında. Dönüşümler yalnızca `CoordinateMapper`'da.
- **Snap:** merkez–merkez mesafe, yalnızca parçanın **kendi** yuvası kontrol
  edilir. Başka yuvaya asla oturmaz.
- **Path cache** hem board boyutuna hem **puzzle kimliğine** bağlıdır.
- **Jestler slota aittir, parçaya değil.** Parça tepsiden çıkınca jest
  dinleyicisi de ağaçtan silinirse "bırakma" olayı kaybolur (yaşandı).
- **Provider kare başına notify etmez.** Sürükleme konumu `ValueNotifier`
  üzerinden yalnızca drag layer'a gider; board yeniden build edilmez.
  Test bunu koruyor.
- **Geometri Provider'da değil.** Snap kararını board boyutunu bilen ekran
  verir, Provider yalnızca sonucu uygular (§39).
- **Ses varsayılanı sessizliktir.** `audioplayers` eklenti yokken hatayı
  **asenkron** fırlatır; try/catch kurtaramaz. Gerçek çalıcıyı yalnızca
  `main` enjekte eder.
- **Görseller şeffaf, zemin çalışma anında boyanır** (`PuzzlePalette`), asset
  dosyalarına dokunulmaz — lisans da bu yüzden basit kalıyor.
- **Bırakılan parça önce uçar, sonra durum değişir.** Parça hiçbir anda iki
  yerde birden çizilmez.
- **Feature'lar birbirine bağlanmaz.** `features/balloon/` ve
  `features/celebration/` yalnızca `core`'a bakar; puzzle onları kullanır,
  tersi olmaz. `test/architecture/feature_independence_test.dart` bunu
  dosyaları okuyarak denetler.
- **Balonlar asla üst üste binmez** (§2): hücre tabanlı yerleşim (3 sütun ×
  4 satır), balon kendi yerinin hemen altından belirerek yükselir. Ekranın
  altından yükselmek, üstteki sıralarda duran balonların önünden geçmek
  demekti — dokunma hedefini örtüyordu.
- **Slot çerçevesi parçanın şeklini izler** (§15). Kenarlar **sabit yönde**
  üretilir (yatay: soldan sağa, dikey: yukarıdan aşağı) — bir parçanın sağ
  kenarı ile komşusunun sol kenarı aynı eğri olduğu için, aynı yönde
  yürünmezse kesikler birbirinin boşluğunu doldurur ve dikiş **düz çizgiye**
  döner. `JigsawPathGenerator.edgePath` bunun için var.
- **Kesikli konturlar `PiecePaths` içinde önbelleklenir** ve **board
  koordinatındadır** (`dashedSlots`) — `of()` ise parça-yerel. Tek sınıfta
  iki koordinat uzayı var, dokunurken dikkat.
- **Hint merdiveni boş odada oynamaz** (§21). İki ardışık auto-place'ten
  sonra uykuya geçer; `start()` ve `resume()` uyandırmaz, yalnızca
  `registerInteraction()` uyandırır.
- **Platform emoji glyph'i kullanılmaz** (§33). `Text('🍎')` yasak; ikonlar
  Flutter'ın kendi font'undan, görseller assets'ten gelir.
  `test/architecture/asset_policy_test.dart` bunu dosyaları tarayarak
  denetler — ama yalnızca gerçek karakterleri yakalar, `\u{...}` kaçışını
  değil.
- **Parça konturu büyütülmez, boyayıcı taşırır.** Dikişleri kapatan bleed
  (§14) artık `PuzzlePiecePainter`'da: kontur hem doldurulur hem de
  `bleed * 2` kalınlığında çizgiyle çizilir. Path'i boolean union ile
  büyütmek bu eğrilerde **çalışmıyor** — knob'un boynu kendi kendisiyle
  kesişiyor ve union bambaşka bir şekil döndürürken sınır kutusu doğru
  kalıyor. İkinci union şekli küçültüyordu bile.
- **Tepsi bir raftır** (§16.1, §40): sütun sayısı satır sayısından az olamaz.
  Bu kural olmadan uzun bir tepside (tablet) parçalar ekranın ortasında tek
  sütuna diziliyordu. Ödün sırası: dokunma hedefi (asla) > raf biçimi >
  dış kenar boşluğu (yer darsa ilk o gider — yatay telefon + 9 parça).
- **Kesinti bir deneme değildir** (§28). Arka plana geçiş sürüklemeyi iptal
  eder, parça kendi yuvasına döner, `failedAttempts` **artmaz**.
- **`Timer` arka planda çalışmaya devam eder, `Ticker` etmez.** Balon
  oyununun 15 saniyesi bu yüzden `pause()/resume()` ile durduruluyor; yoksa
  çocuk cebindeyken ödülü yanardı. Yeni bir zamanlayıcı yazarken bunu sor.
- **Geri tuşu ceza değildir** (§30). Kutlama/balon sırasında basılırsa
  sekans kesilir ama kazanılan sticker durur ve sonraki puzzle hazırlanır —
  yoksa çocuk çözülmüş bir board'a geri dönerdi.
- **Bitince boş ekran bırakma.** `startNextPuzzle()` oynanacak yeni puzzle
  kalmayınca Serbest Mod'a düşer (§4). Sessizce dönerse "her şey bitti"
  görüntüsü "yükleniyor" görüntüsüyle aynı olur; emülatörde tam olarak bu
  yaşandı.
- **Sticker yalnızca ilk bitirişte verilir.** "Zaten kazanılmış mıydı"
  bilgisi son parça yerleşmeden **önce** okunur; sonrası çok geç.
- **Widget kendi kimlik key'ini kendi koymaz.** `sticker-<id>` key'i
  `StickerTile`'ın kendisine, album tarafından verilir; iç GestureDetector'a
  konunca `tester.widget<StickerTile>` tipi tutmaz.
- **Renkler temadan gelir.** Ekranlar renk yazmaz, `context.palette`'ten
  alır; boyayıcıların context'i yoktur, rengi onları kuran widget verir
  (`outlineColour`, `shadowColour`, `stringColour`). Temaya göre değişmeyen
  renkler (sarı oyna düğmesi, balon, konfeti, parça gradyanları) palette
  değildir. Açık ve koyu zemin Android `values*/app_colors.xml` ve iOS
  `LaunchBackground` renk setinde de tekrarlanır; biri değişirse diğeri de.
- **Parça tek katmanda bestelenir.** `PuzzlePiecePainter` önce örtüyü
  (kontur dolgusu + bleed çizgisi) opak basar, sonra gradyanı `srcIn`,
  resmi `srcATop` ile üstüne koyar ve katmanı tek seferde tuvale verir.
  Gradyan ve resim ayrı ayrı yumuşatılmış kenarla boyanırsa komşunun bleed
  çizgisinin kenarında gradyan resmin altından `c·(1−c)` kadar (en çok %25)
  görünür: delik yok ama her parça sınırında açık bir çizgi (aslanın siyah
  konturunda 64–75 birim, ölçüldü). `piece_seam_tone_test.dart` korur.
- **Home ekranla büyür.** Düğmeler kısa kenar / 360 oranında, en çok 2 kat
  (`PuzzleConfig.home*`); 360'tan küçükte küçülmez. Tavan olmadan 1024 dp
  tablette oyna düğmesi 450 px'i geçerdi.
- **Balonlar çift doğar, çift patlar** (K-5). Bir çiftin iki balonu aynı
  anda ve aynı renkte doğar; eşleşen iki balon birlikte patlar. Bu yüzden
  ekranda her rengin sayısı her an çifttir ve eşi olmayan balon kalmaz —
  rastgele dokunan 20 oyunda her tıkta testle korunuyor. Açılış sayısı ve
  toplam çift olmak zorunda (assert). Kimlikler çift içinde ardışık
  (`2k`, `2k+1`); akış testi buna dayanıyor.
- **Seçim çizimdedir, dokunma alanında değil.** Seçili balon `BalloonPainter`
  `scale` ile büyür, `Transform.rotate` ile sallanır; dokunma kutusu yerinde
  kalır, komşunun 72 px'ini yemez.
- **Boyama hiçbir feature'a bağlı değildir** (§24.2). `ColouringBook`
  `GameProvider`'da durur (`game.colouring`) yalnızca §26 sıfırlaması onu da
  temizlesin diye; puzzle → colouring yönü serbest, tersi yasak
  (`feature_independence_test.dart`).
- **Araba parçaları ölçülerek çizilir.** Her parçanın *görünen* alanına
  (üstteki parçalar çıkarılınca) en küçük ölçekte 64 px'lik daire sığmalı;
  `car_catalog_test.dart` bunu 0,5 birimlik ızgarada ölçer. Şu an en küçük
  parça 12,5 birim, gereken 10,96 (568×320 yatay telefon). Yeni araba
  çizilirse küçük ayrıntılar parça değil süs çizgisi (`details`) olur.
- **Palette çizilen renk, boyanan renktir.** Palet iki gradyan katmanıdır:
  tam doygun tonlar (HSL, L=0,5) + beyazdan saydama, saydamdan siyaha perde.
  Tam doygun HSL'de açıklık beyaz/siyahla doğrusal karışım olduğu için bu
  birebir tutar; `PaletteChoice.colour` aynı HSL'den hesaplanır.
  `colouring_overlay_test.dart` ekran piksellerini ölçer (142 nokta, en
  büyük fark 1). Perdenin durakları ya da açıklık sınırları değişirse iki
  taraf birlikte değişmeli. Boya opak ARGB olarak saklanır.
- **Boyama beklemeleri `AnimationController`'dır, `Timer` değil** — arka
  planda durur (§28). Bitmiş ama sürülüp gitmeden çıkılmış araba, overlay
  bir sonraki açılışta `startNextCar()` ile yenilenir.
- **Ebat resmin değil safhanındır** (K-15). `PuzzleDefinition`'da grid yok;
  `GameProvider.startPuzzle(def, {grid})` ebat verilmezse `stageGrid`'i
  kullanır. Kademe/kilit/Serbest Mod kodu tamamen silindi.
- **Safha, ödül bitince ilerler.** `markPlaced` yalnızca çıkartmayı ve
  `currentSolved`'u yazar; `finishStage()` dizi bittiğinde (ekran `_moveOn`)
  ya da dizinin ortasında çıkılınca (`_afterInterruptedSequence`) çağrılır,
  çözülmemiş puzzle'da hiçbir şey yapmaz, iki kez çağrılması bir kez sayar.
  Açılışta `currentSolved` doğruysa önce safha ilerletilir.
- **Arabayı değiştiren oyundur, boyama sayfası değil.** `finishStage` 5.
  safhadan sonra `colouring.startNextCar()` çağırır. Overlay yalnızca
  `finishesCar` ile arabayı sürer; eski "tamamlanmış arabayla açılınca
  yenisine geç" davranışı kaldırıldı. Defter son 3 biten arabayı
  (`recentCars`) saklar; oyun sonu geçidi onları gösterir.
- **Board sığdırma** (`BoardFitter`): önce §40 boyu, sığmazsa 2 px adımla
  küçülür, hücre 64 px altına inene kadar değil. Raf biçimi burada
  aranmaz: 320 dp'de 4×3'ün parçaları (en/boy 1,238) dört sütuna **hiçbir
  board boyunda** 64 px'te sığmaz (ölçüldü); orada tepsi 4 satır × 3 sütun.
  Testler rafı yalnızca `test/support/tray_shelf.dart`'ın "mümkün" dediği
  yerde ister. İlk denemede eklenen "önce raf ara" döngüsü hiçbir ekranda
  sonucu değiştirmediği için geri alındı.
- **Kabartmanın kaydırması çizgi kalınlığı kadardır** (K-19). Daha azı
  olursa ışık ve gölge kenarda üst üste biner, koyu olan kazanır ve üst
  kenar da gölgeli çıkar (ölçüldü). Yönler sezgiye ters: ışık **sağ alta**
  kaydırılır, çünkü kırpmadan sonra yalnızca üst/sol kenarın içinde kalır.
  Kırpma zorunludur; yoksa kabartma komşu parçanın üstüne taşar
  (`piece_bevel_test.dart` bunu tek parçayı beyaz zeminde ölçerek korur —
  board'da komşu zaten örtüyor ve kaçıyordu).
- **Safha sayacı türetilmiştir** (K-18): `finishStage` artırmaz,
  `colouring.fills.length`'i yazar. Bu yüzden `GameProvider`'a verilen
  defter oyun ilerlemesiyle **aynı depoyu** görmeli; testlerde de
  `ColouringBook(storage: storage)..load()` verilir, yoksa her oturum
  2×2'den başlar.
- **Basılı tutma iptali sayaç sıfırken de durdurulmalı** (K-21). Kısa bir
  dokunuşta basma ve kalkma aynı karededir; `value == 0` diye erken dönen
  bir iptal sayacı çalışır bırakır ve kapı iki saniye sonra kendiliğinden
  açılır (testte yaşandı). Testte de sıra önemli: parmak indikten **sonra
  bir kare** geçmeden sayaç başlamaz.
- **Perde çizginin altında, dolgunun üstünde** (K-17). Sıra bozulursa siyah
  kontur solar — ama yalnızca parçanın **üst** kenarında (perde orada beyaz),
  alt kenarda siyah üstüne siyah gelir ve fark edilmez. Testin ölçtüğü nokta
  bu yüzden bir parçanın üst kenarının **iç** yarısıdır; ilk iki deneme
  (alt kenar, sonra çizginin dış yarısı) mutasyonu yakalamadı.
- **Tepsideki ve eldeki parça çizgilidir, board'daki değil** (16 Eylül,
  kullanıcı istedi: açık parça açık zeminde görünmüyordu).
  `PuzzlePiecePainter.outlineColour/outlineWidth`, renk
  `palette.pieceOutline` (açıkta koyu kahve, koyuda açık gri; zemine ≥ 3:1),
  kalınlık ekranda `PuzzleConfig.pieceOutlineWidth` = 1,5 px — tepsi parçayı
  küçülterek çizdiği için ölçeğe böler. Çizgi katmanın dışında, en üstte.
  Parça board'a oturunca çizgisiz hâle geçer. `tray_piece_outline_test.dart`
  korur (beş mutasyonla kanıtlandı).
- **Widget genişliğini `rect.width`'ten alma.** `sağ − sol` kayan noktada
  tam 72 vermiyor (71.99999999999999); boyut `BalloonLayout.diameterOf`
  üzerinden verilir.

---

## 7. Test tuzakları (widget testlerinde)

- Bir animasyonun **ilk tick'i onu başlatan karede** olur. `pump(160ms)` tek
  hamlede atlanırsa sayaç 0'da kalır; her aşama kendi pump'ını ister.
- **Konfeti kare başına** parçacık yayar; tek uzun pump neredeyse hiçbir şey
  üretmez. Kanıt görseli için 16 ms'lik kareler döngüsü kullanılır.
- Kutlama ekrandayken **`pumpAndSettle` kullanılamaz** (sürekli kare üretilir).
  Puzzle'ı bitiren testler açık pump'larla yazılmıştır.
- Gerçek asset'ler widget testlerinde `rootBundle` üzerinden yüklenir; sorun
  çıkmaz. Ama `startPuzzle` asenkron olduğu için `tester.runAsync` gerekir.
- **Balon oyunu ekrandayken `pumpAndSettle` kullanılamaz** (kutlama gibi).
  Puzzle akış testleri balon oyununu 15 sn açık pump'la geçiyor.
- Balonlar **ikişer** gelir (K-11): açılışta 2, sonra 0,6 sn'de bir çift,
  yükselme 0,6 sn; 3. saniyede onu da yerinde. Overlay testleri balonlara
  3,1 sn sonra dokunur (`_afterTheRise`). Yükselirken dokunulan balon hareketli
  bir hedeftir; testte "ıskaladı" diye yanlış teşhis koydurur.
- **Mutasyonu kanıt görselini üreten test dosyasıyla koşturma** — ya da
  görsele mutasyonlar geri alınıp tam koşu yapıldıktan sonra bak. Faz 18'de
  bozuk kodun ürettiği görsel bir an gerçek hata sanıldı.
- Salınım (bob), yerleşme anındaki konum karşılaştırmalarını bozar; yükselme
  yönü iki ara noktayla (200/800 ms) ölçülür.
- **Lifecycle testleri geçerli sırayı izlemeli:** resumed → inactive →
  hidden → paused, dönüşte tersi. Geri tuşu
  `handlePlatformMessage('flutter/navigation', popRoute)` ile gönderilir.
- **Sınır kutusu testi şekli test etmez.** Bleed hatası aylarca ayakta
  kaldı çünkü tek testi "render path her yönde bleed kadar büyüdü mü"ydü;
  bu doğruydu, ama şekil bozuktu. Artık kontur, kenar boyunca noktasal
  ölçülüyor (`piece_outline_test.dart`).
- **Hayalet katmanın üstünde piksel ölçümü yapma.** Board'un tamamı %25
  alfayla boyalı olduğu için "boyalı piksel" testi her yerde doğru çıkar;
  çerçeveyi izole etmek için render **iki kez** alınıp farkı bakılır
  (`board_outline_test.dart`). Bu bir kez yanlış ölçüme sebep oldu.
- **Yerleşim testi doğru ekranı seçmeli.** Dış kenar boşluğunu yalnızca
  *genişlik sınırlı* ekranlar (414×896, 1024×1366) kanıtlar; yükseklik
  sınırlı bir ekranda içerik zaten ortalanır ve test mutasyonda kırmızıya
  dönmez. Bu bir kez yaşandı.
- **Olmayan bir key'e `findsNothing` demek test değildir.** Faz 14'te
  `hint-pulse` diye bir key yokken test boşuna geçiyordu; hint'in durduğu
  artık ses kaydı ve `placedCount` üzerinden ölçülüyor.
- **Animasyon süresi aşılınca biter, erişilince değil.** `pump(900ms)` +
  `pump()` 900 ms'lik bir `AnimationController`'ı bitirmez (simülasyon
  `t > süre` ister); son pump'a 20 ms eklenir. Faz 18'de üç test bu yüzden
  kırmızıydı, geçen tek test tesadüfen fazladan 250 ms bekliyordu.
- **Mutasyon koşuları `build/` altındaki kanıt görsellerini bozuk kodla
  yeniden yazar.** Görsele mutasyonlar geri alınıp testler yeniden
  koşturulduktan sonra bakılır (Faz 18'de doğru renk karesi mavi göründü).
- **Album ve About kaydırılabilir**; `ListView` ekran dışındaki çocukları hiç
  kurmaz. Testler `scrollUntilVisible` kullanır ve **yalnızca tek yöne**
  kaydırır — sticker'lar katalog sırasında değil, album (kategori) sırasında
  gezilmeli, yoksa liste bir aşağı bir yukarı gitmek zorunda kalır ve test
  "Bad state: No element" ile patlar.

---

## 8. Açık borçlar

1. ~~CI hiç çalışmadı.~~ **Çözüldü** (13 Eylül): depo
   <https://github.com/ibrahimyasar68/emojipuzzle> (public), ilk dokuz
   commit push edildi, `.github/workflows/ci.yml` her push'ta çalışıyor.
2. ~~OpenMoji attribution uygulamada görünmüyor.~~ **Faz 13'te yapıldı**:
   Home → ⓘ → Hakkında ekranı. Mağaza açıklamasına da Faz 16'da eklendi
   (`docs/store-listing.md`).
3. **§42 gerçek cihaz profiling'i yapılmadı.** Faz 12 sonunda Pixel 6
   emülatöründe uygulama baştan sona elle oynandı (puzzle → kutlama →
   balon → sonraki puzzle, hepsi çalışıyor) ama bu bir profiling değildi.
   Yalnızca yapısal kısmı test edildi (board rebuild yok, kare başına
   notify yok). `flutter run --profile`
   ile bakılmalı.
4. ~~Faz 14 için hazır ama bağlanmamış.~~ **Faz 14'te bağlandı**:
   `WidgetsBindingObserver`, `PopScope`, drag iptali, progress kaydı.
   §28'in "müzik durur/devam eder" maddesi **boş geçildi — müzik yok**.
5. ~~Idle hint gözetimsiz oyunu kendi bitiriyor.~~ **Faz 16'da düzeltildi**
   (bkz. §9 Kalanlar 1): iki ardışık auto-place'ten sonra merdiven uyur.
6. ~~**Cila (Faz 16):** konfetinin cihazdaki dağılımı, parıltıların açık
   görseller üzerinde sönük kalması, Home'un tablette seyrek durması.~~
   **Kapandı** (15 Eylül): Home ve parça sınırı tonu düzeltildi; konfeti ve
   parıltıları kullanıcı olduğu gibi uygun buldu.
   (Tamamlanınca kesikli çerçevenin görünmesi Faz 16'da, tepsi
   parçalarındaki şekil bozukluğu Faz 15 sonunda düzeltildi.)

---

## 8b. Faz 13'e girerken verilmiş kararlar

- **"Her şey bitti" boş ekranı Faz 13'te düzgün çözülecek** (ara çözüm yok).
  Emülatörde yaşandı: dokuz puzzle da tamamlanınca `resume()` →
  `startNextPuzzle()` → `nextPuzzle == null` → sessiz çıkış → `appState`
  sonsuza dek `loading` → boş ekran. Spec'in cevabı §4'ün Serbest Mod'u.
- ~~Tepsi parçalarındaki hizalama kusuru Faz 16'ya bırakıldı.~~ **Çözüldü**
  (13 Eylül): hizalama değil, `PiecePaths`'in konturu boolean path
  işlemleriyle büyütmesiydi; tırnaklı her parçanın köşesini çapraz
  kesiyordu. Bleed artık `PuzzlePiecePainter`'da bir stroke (bkz. §6).

---

## 9. Faz 16 durumu

**Bitenler:**

- **§33 lisans denetimi** — `assets/LICENSES.md` ile gerçek dosyalar birebir
  eşleşiyor (13/13), otomatik test eder. **Album kategori başlıklarındaki
  emoji glyph'leri kaldırıldı** (§33 ihlaliydi, Faz 13'te girmişti).
- **§35 privacy** — `docs/privacy-policy.md` yazıldı. Yayın manifest'i
  **hiçbir izin istemiyor**, otomatik test eder.
- **Mağaza metni** — `docs/store-listing.md`, attribution dahil.
- **§42 profiling** — Pixel 6 emülatöründe profile derlemesiyle ölçüldü:
  build (UI thread) ort **1,34 ms**, p99 3,27 ms. Raster ort 15,7 ms ama bu
  emülatörün yazılım GPU'su. **Gerçek cihazda ölçülmedi.** Bleed stroke'unun
  maliyeti ölçüldü: yok (15,94 → 15,71 ms).
- **Tamamlanınca kesikli çerçeve** — dolu hücrelerde artık çizilmiyor.
- **Slot çerçevesi parçanın şeklini izliyor** (§15) — kullanıcı istedi.
  Kenarlar sabit yönde üretilir, yoksa komşuların kesikleri iç içe geçip
  dikişi düz çizgiye çevirir. Kesikler puzzle başına bir kez hesaplanır
  (9 parça için 4,1 ms ölçüldü), `paint` path yürütmez (§42).
- **`lib/` altındaki bütün kod yorumları Türkçeye çevrildi** ve **spec §0
  buna göre güncellendi** (§45 gereği önce soruldu, onaylandı). Sınıf ve
  değişken isimleri, `§` atıfları ve commit mesajları İngilizce kaldı;
  `debugPrint` çıktıları da öyle.

- **Uygulama ikonu ve görünen ad** (kullanıcı 13 Eylül'de istedi): ikon
  kullanıcının ChatGPT'de ürettiği görsel, "IY Labs" rozeti **dahil**.
  Kaynak `docs/branding/app-icon-source.png`; köşeleri yuvarlatılmış ve zemini
  beyazdı, `python3 tool/generate_app_icon.py` köşeleri komşu renkle doldurup
  bütün boyutları tek bir kare ana görselden üretir (Android legacy +
  adaptive, iOS, Play 512). Yeni paket eklenmedi (§37). Görünen ad
  **EmojiPuzzle**: `android:label`, `CFBundleDisplayName`/`CFBundleName`,
  `MaterialApp.title`, Hakkında ekranı, README ve mağaza/gizlilik metinleri.
  Paket adı ve bundle id **değişmedi** (değişirse kurulu ilerleme kaybolur).
  Adaptive icon'da çizim görünen 72 dp'yi doldurur. **Rozet küçültüldü**
  (kullanıcı istedi): köşedeki büyük rozet Pixel'in daire maskesinde
  kırpılıp yalnızca "IY" bırakıyordu. Betik onu kaldırır, altında kalan
  kırmızı parçanın köşesini görünen kenarlarından yeniden çizer (köşe
  yarıçapı 200 px, ölçüldü) ve orijinal yazıyı %74 ölçekle kırmızı parçanın
  üstünde küçük bir etikete koyar. Etiketin köşeleri 66 dp güvenli bölgenin
  içinde; betik taşarsa hata verir. Koordinatlar bu kaynağa özgüdür, görsel
  değişirse yeniden ölçülmeli. Pixel 6 emülatöründe görüldü.

- **Görünüm seçimi: Sistem / Açık / Koyu** (kullanıcı 13 Eylül'de istedi).
  Hakkında ekranında, sıfırlamanın üstünde; Home'a konmadı (§2'nin beş öğe
  sınırı). Seçim `lib/core/theme/theme_settings.dart`'ta
  (`emoji_puzzle.theme_mode`), mute gibi saklanır, ilerleme sıfırlaması
  silmez; varsayılan telefonun ayarı. MaterialApp `lib/app/themed_app.dart`'ta
  — testler gerçek ses çalıcısını kurmadan tema bağlantısını sınayabilsin
  diye. Renkler `lib/core/theme/app_theme.dart`'ta: `AppPalette`
  (ThemeExtension, `context.palette`) ve `AppTheme.light/dark`; ekranlar renk
  yazmaz, boyayıcılar rengi parametre alır (`outlineColour`, `shadowColour`,
  `stringColour`).
  - **Açık** = `#EEE8E1`, ilk krem `#FDF7EF`'nin bir ton koyusu (kullanıcı
    istedi). İkincil yazı 4,5:1 kontrast için `#6E645B`'ye, krem düğmeler
    zemine yaklaştığı için `#E4D6C4`'e koyulaştırıldı (kullanıcı istedi);
    diğer renkler ilk halleri.
  - **Seçili görünüm seçeneği 2 px çerçeveli** (kullanıcı istedi): açık
    temada koyu kahve, koyu temada beyaz. Seçim yalnızca renk farkına
    bırakılmaz; çerçevenin zemine kontrastı ≥ 3:1 ve yalnızca seçili
    seçeneğin çerçeveli olduğu testle korunuyor (mutasyonla kanıtlandı).
  - **Koyu** = önceki koyu lacivert `#14213D`'nin %25 beyaza açılmışı,
    `#4F596E` (kullanıcı istedi). Açık zemine göre seçilmiş renkler (yarı
    saydam siyah, kahverengi yazı/kontur, siyah ip, kahverengi gölge) yeniden
    seçildi; küçük yazı kontrastı ≥ 4,5:1, testle korunuyor.
  - Android açılış penceresi `values/` + `values-night/app_colors.xml`, iOS
    `LaunchBackground` renk seti (açık/koyu varyant). Oyunda telefonun tersi
    seçildiyse açılışta bir an telefonun rengi görünür: seçim Flutter
    başlamadan okunamaz. **iOS tarafı derlenip görülmedi** (simülatör yok).
  - Pixel 6'da iki tema ve yeniden başlatmada kalıcılık görüldü. 887 test;
    üç mutasyonla yeni testlerin boş olmadığı kanıtlandı. Seçici ilk halinde
    360 dp'de 18 px taşıyordu (ölçüldü): ikon yazının üstüne alındı,
    `FittedBox` ile küçülür.
  - **Olay:** aynı istek aynı anda ikinci bir Claude oturumunda
    (emojipuzzle-25) da uygulandı ve dosyalar karıştı (analyze 10 hata).
    Kullanıcı bu oturumun bitirmesini seçti; diğerinin `theme_controller.dart`'ı
    ve ikinci seçicisi silindi, onun açık tema rengi `#BEB9B3` (kremin %25
    koyultulmuşu) yerine ilk krem kullanıldı.

**Kalanlar:**

1. ~~Idle hint gözetimsiz oyunu bitiriyor.~~ **Düzeltildi** (kullanıcı
   13 Eylül'de onayladı): `hintMaxAutoPlacesInARow = 2`. Üst üste iki
   auto-place'ten sonra merdiven uykuya geçer; **yalnızca ekrana dokunmak**
   uyandırır. Arka plandan dönmek ve sonraki puzzle'a geçmek uyandırmaz —
   uyandırsaydı gözlemlenen sonsuz döngü aynen sürerdi.
2. ~~GitHub remote yok.~~ **Çözüldü**, depo public ve push edildi.
3. **Gerçek cihazda profiling** — emülatör yeterli değil.
4. ~~Küçük cila: Home tablette seyrek duruyor; parça sınırlarında 1 piksellik
   ton farkı kalıyor.~~ **Düzeltildi** (kullanıcı 15 Eylül'de istedi):
   - **Ton farkı:** sebep ölçüldü — gradyan ve resim ayrı ayrı yumuşatılmış
     kenarla boyanıyordu, komşunun bleed çizgisinin kenarında gradyan opak
     resmin altından görünüyordu. Parça artık tek katmanda bestelenir (bkz.
     §6). Sınır bandında (±2 px) en büyük fark 75 → 2, ortalama 4,94 → 0,14;
     iç bölgeyle aynı. Mutasyonla kanıtlandı (eski boyayıcıyla 75 ve 62).
     **Maliyet ölçülmedi:** parça başına bir `saveLayer` eklendi (§42);
     board sürükleme sırasında yeniden boyanmadığı için etkisi sınırlı
     olmalı, ama emülatörde/cihazda bakılmadı.
   - **Home tablette:** sabit boyutlu düğmeler 1024 dp'de genişliğin %21'ini
     kaplıyordu (telefonda %61). Artık kısa kenarla büyüyor, en çok 2 kat
     (tablette %43–%57). Telefonda hiçbir şey değişmedi. Altı ekranda test
     edilir; mutasyonla kanıtlandı (ölçeksiz halde üç tablet testi kırmızı).
5. **Konfeti dağılımı ve parıltılar** — kullanıcı 15 Eylül'de uygun buldu,
   dokunulmayacak.
6. ~~`docs/assets-inbox/frame6.png`~~ — **kapandı**: kullanıcı 13 Eylül'de
   "taşınan yerde kalsın, bu ikona bir şey yapmayalım" dedi. Dosya pakete
   girmiyor, git'e eklenmedi (depo public), lisans testi yeşil. Bir gün
   kullanılacaksa kaynağı ve lisansı `assets/LICENSES.md`'ye işlenmeli.

---

## 10. Faz 17 durumu — balon renk eşleştirme

**Yapılanlar** (15 Eylül'de onaylandı):

- Spec: §0.3 (K-5..K-8), §2 istisnaları, §23 notu, §24 yeniden yazıldı,
  §24.2 boyama taslağı, §44'e Faz 17 ve 18 satırları.
- `BalloonGameController.tap(id)` → patlayan balonları döndürür (ya aynı
  renkten iki, ya hiç). `pop` kaldırıldı. `selectedId`, `partnerHintId`.
- Çiftler: açılışta 4 balon, 2,4 sn'de bir çift, toplam 12, en çok 8.
  **15 Eylül'de K-11 ile değişti:** 10 balon, en çok 10, açılışta 2, 0,6 sn'de
  bir çift, yükselme 0,6 sn (giriş 3 sn). Renkler artık karıştırılmış
  desteden dağıtılır: her çift ayrı renk, sıra her oyunda başka. Tamamen
  rastgele renk bütün çiftleri aynı renge boyayabilirdi (eşleştirme biterdi).
  Beş mutasyonla kanıtlandı (sabit sıra, tekrarlı renk, 1 sn yükselme,
  2,4 sn aralık, 8 sınırı).
- Seçili balon 120 ms'de 1,12'ye büyür ve ±0,08 rad sallanır; 3 sn seçili
  kalırsa eşlerinden biri 800 ms periyotla 1,08'e nabız atar.
- Seçimde yalnızca haptik `selection`; ses yalnızca patlamada, çift başına
  bir kez. Farklı renk: ses yok, sayılmaz (§20).
- 13 yeni test; dört mutasyonla kanıtlandı (yanlış renk de patlatır, renk
  balon başına yürür, ipucu beklemez, seçilen büyümez — hepsi kırmızı).
- **Emülatörde elle oynanmadı.**

---

## 11. Faz 18 durumu — boyama safhası

**Yapılanlar** (15 Eylül'de onaylandı):

- Spec §24.2 yazıldı, §2 istisnasına "geç oku" eklendi.
- Sıra: kutlama → balon → sticker (yalnızca ilk bitiriş) → **boyama** →
  sonraki puzzle. Boyama her bitirişte, Serbest Mod dahil.
- 3 araba (sedan, kamyonet, yarış), her biri 5 parça, kodla çizilir. Beyaz
  kart, siyah çizgi.
- **Serbest palet (K-9, kullanıcı istedi):** 6 sabit renk yerine sürekli
  bir palet. Dikey ekranda altta (tonlar enine, açıktan koyuya boyuna),
  yatayda sağda (tonlar boyuna). Yanında beyaz→siyah gri şerit (siyah
  teker, beyaz cam için). Dokunmak ve sürüklemek aynı: parmağın altındaki
  renk; şeritten taşan parmak kenardaki rengi seçer. Seçim noktasında
  siyah-beyaz çift çerçeveli halka. Başlangıçta tam doygun mavi seçili.
- **Renk karesi (K-10, kullanıcı istedi):** sol üst köşede 64 px, siyah
  çerçeveli (beyaz seçilince de görünsün), dokunuşa kapalı. Parmak palette
  gezerken her karede güncellenir. Yatayda "geç" oku karenin altında; kartın
  ölçeği değişmedi.
- Parçaya dokun → boya 250 ms'de akar, `playPieceSnap`, 900 ms sonra
  sonraki puzzle. Bitişte bir parça; boyanmış parça yeniden boyanabilir.
- Son parça → `playPuzzleComplete`, araba 1,4 sn'de sağdan çıkar, defter
  sonraki modele geçer (sonuncudan sonra başa).
- Geç oku hemen geçer; kâğıda ya da boşluğa dokunmak hiçbir şey yapmaz.
  Geri tuşu: boya kalır, sonraki puzzle hazırlanır.
- Kalıcılık ayrı anahtarda; bozuk kayıt → ilk araba boş. Sıfırlama defteri
  de temizler.
- 57 yeni test (Faz 17'den bu yana). İlk sürüm yedi mutasyonla kanıtlandı
  (tek boyama sınırı, geç oku, araba değişimi, sticker sonrası boyama,
  sıfırlama, ince parça, 60 px renk); serbest palet beş mutasyonla daha
  (dokunuş yok sayılır, perde ters çizilir, boya hep başlangıç rengi,
  saydam boya kabul, yatayda eksenler), renk karesi iki mutasyonla daha
  (kare hep başlangıç rengi, yatayda ok kareyle çakışır) — hepsi kırmızı.
- **Test tuzağı (yaşandı):** mutasyon koşusu `build/colouring.png`'i bozuk
  kodla yeniden yazar. Kanıt görseline mutasyonlar bittikten sonra bakılır.
- Kanıt görseli: `build/colouring.png`. **Emülatörde elle oynanmadı.**
- Parça sayısı 5 (K-8 "~6" diyordu): 6. parça ya 64 px daireyi
  sağlamıyordu (far, jant, kapı) ya da gövdeyi dokunulamaz kılıyordu.

---

## 12. Faz 19 durumu — 9 yeni puzzle

**Yapılanlar** (15 Eylül'de onaylandı):

- 9 PNG, kullanıcının izniyle OpenMoji `color/618x618/` klasöründen
  indirildi (15 Eylül, `master`), değiştirilmeden `assets/images/puzzles/`'e
  kondu. Kod noktaları ve dosya adları `assets/LICENSES.md` tablosunda;
  indirilen dosyaların PNG ve 618×618 olduğu, resimlerin doğru olduğu gözle
  (önizleme sayfası) doğrulandı.
- Katalog: her kademeye bir meyve + iki başka resim eklendi; kademe sırası
  eski üçün ardından yeni üç. `requiredCompletions` hâlâ 2.
- Spec §4 tablosu ve içerik listesi, §44'e Faz 19 satırı, §0.3'e K-12.
- Testler: 18 puzzle / kademe başına 6, yeni resimlerin kategorileri, her
  kademede meyve, beş kategorinin hepsi dolu. İki mutasyonla kanıtlandı
  (lisans satırı silinir → lisans testi kırmızı; Ay meyvelere düşer →
  kategori testi kırmızı).
- **Dikkat:** `firstUnsolved` bir kademeyi bitirmeden üstüne geçmez; artık
  2×3'e varmak için altı 2×2 puzzle gerekiyor. Kullanıcının haber verdiği
  kural değişikliğinde bu konuşulmalı.
- Bisiklet resmi ince çizgili ve çok boşluklu: 2×3'te bazı parçalar
  neredeyse boş gradyan olacak. Emülatörde bakılmadı.

**Sırada:** kullanıcı oyun kurallarını değiştirmek istiyor.

---

## 13. Faz 20 durumu — kamyon, traktör; Eşyalar

**Yapılanlar** (15 Eylül'de commit edildi):

- **Kamyon** (kasa, kabin, üç teker) ve **traktör** (kabin, kaput, ızgaralı
  ön panel, büyük arka teker, küçük ön teker) kodla çizildi. En küçük parça
  12,01 birim, gereken 10,96. Traktörün ilk hâlinde teker büyüklüğünde bir
  far vardı; boyanınca havada üçüncü bir teker gibi göründüğü için
  (görsel kontrolde) dikdörtgen ızgaraya çevrildi. Cam ve egzoz süs
  çizgisi. Spec §24.2 ve K-13.
- **Eşyalar** kategorisi: enum `objects`, pembe gradyan, albüm ikonu
  (`Icons.category_rounded`) ve başlığı. Spec §4 ve K-14. Yeni
  `puzzle_palette_test.dart` her kategorinin kendi gradyanı olduğunu
  denetler; ilk yazılışı boştu (gradyan unutulsa da geçerdi), mutasyonla
  yakalanıp düzeltildi.
- Albüm boş kategoriyi göstermez; Eşyalar başlığı görseller gelince çıkar.

**17 Eylül'de kapandı (K-16):** görseller kodla çizildi, havuza eklendi
(21 resim), lisans kaydı yapıldı; testler: 21 resim, Eşyalar dolu ve albümde
ikonuyla, her resim dosyası var, her resim kare / ≤ 1024 / köşesi şeffaf.
Beş mutasyonla kanıtlandı. Aşağıdaki liste tarihçedir.

**Bekleyen — kullanıcıdan (eski):**

- `assets/images/puzzles/book.png`, `microscope.png`, `binoculars.png`:
  PNG, 1:1 kare, şeffaf zemin (§34), tercihen 618×618 (en fazla 1024),
  OpenMoji'ye benzer kalın siyah çizgili üslup; her birinin kaynağı ve
  lisansı (`assets/LICENSES.md` için, §33).
- Dosyalar gelince: katalog satırları (kitap 2×2, dürbün 2×3, mikroskop
  3×3 → kademe başına 7, toplam 21), lisans kaydı, testler (21 puzzle,
  Eşyalar kategorisi dolu, albümde başlık).

**Sonra:** kullanıcı oyun kurallarını yeniden belirleyecek.

---

## 14. Faz 21 durumu — yeni oyun kuralları (K-15)

**Yapılanlar** (15 Eylül'de onaylandı):

- `data/game_rules.dart` (safha ebatları, 3 araba), katalog düz havuz,
  `LevelDefinition` silindi, `PuzzleDefinition.grid` kalktı.
- `GameProgress` şema 2 (`stage`, `carsFinished`, `playedThisGame`,
  `currentSolved`); şema 1'den geçiş çıkartmaları korur, oyunu baştan açar.
- `GameProvider`: rastgele resim (`Random` enjekte), `stageGrid`,
  `finishStage`, `startNewGame`, `isGameOver`, `isLastStageOfCar`, yeni
  `resume`.
- Boyama: kilitli parça, `finishesCar`, `recentCars`, `CarParadeOverlay`.
- Ekran: dizi sonu safha ilerletir; oyun sonunda konfeti + araba geçidi →
  Home + yeni oyun; geri tuşu da aynı.
- `BoardFitter` + `TrayLayoutCalculator.tryCalculate(requireShelf)`.
- Spec: K-15, §2/§16.1 notu, §4 başı, §24.2, §25, §40, §44.
- Testler: eski kademe/Serbest Mod testleri silindi, yerine safha testleri;
  kayıt/devam, görsel hatası, şema 2 ve geçiş, oyun kuralları (her arabanın
  5 parçası), board sığdırma (8 ekran × 5 ebat), 4×3/4×4 yerleşim ve tepsi,
  oyun sonu widget testleri (5. safha 4×4 gerçek parmakla, geçit, geri
  tuşu). 1137 test.
- **Mutasyonla kanıtlanan:** board hiç küçülmez; resim oyunda tekrar gelir;
  5. safhadan sonra safha dönmez; geçiş çıkartmaları atar; boyanmış parça
  kilitsiz; ekran son safhayı bildirmez; açılışta yarım ödül yok sayılır —
  hepsi kırmızı.
- **Ölçümle düzeltilen test iddiası:** "tepsi her zaman raf" 320 dp'de 4×3
  için geometrik olarak imkânsız; kod doğruydu.
- **Gözle görülen:** 12 ve 16 parçada emoji resimlerinin şeffaf kenarları
  yüzünden birçok parça neredeyse boş; onları yalnızca gradyan ayırıyor.
- **Emülatörde elle oynanmadı.** Kitap/mikroskop/dürbün görselleri hâlâ
  bekleniyor; gelince havuza eklenir (kademe gerekmez).

