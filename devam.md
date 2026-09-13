# Devam Notu — Emoji Puzzle Kids

Bu dosya, yeni bir sohbette kaldığı yerden devam edebilmek için yazıldı.
Son güncelleme: 13 Eylül 2026, Faz 16 sırasında.

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
| **16** | **Asset/lisans denetimi, privacy, final cila** | **⏳ sürüyor** |

**Durum:** `flutter analyze` temiz, `flutter test` yeşil — **878 test**.
`lib/` altındaki bütün kod yorumları Türkçe.
Dokuz commit, **GitHub'da yayında**:
<https://github.com/ibrahimyasar68/emojipuzzle> (public). CI push'ta çalışıyor.

---

## 2. Verilmiş kararlar (tekrar sorma)

- **K-1 = A** — 3 kademe × 3 puzzle: 2×2, 2×3, 3×3. Engine 1×3 ve 3×4'ü
  desteklemeye devam ediyor ama içerikte yoklar.
- **K-2 = evet** — mute `AudioService` içinde ve kalıcı. Home'daki düğme Faz 13'te.
- **K-3 = evet** — `.github/workflows/ci.yml` hazır (format + analyze + test).
- **K-4 = evet** — debug overlay yapıldı, `debugShowPuzzleOverlay` bayrağıyla.
- **Görseller = OpenMoji**, CC BY-SA 4.0, **618×618** (kullanıcı §34'ün 1024
  hedefinden sapmayı onayladı; SVG'den render için `librsvg` kurulu değil).
- **Sesler = sentezlenmiş**, indirilmedi: `dart run tool/generate_sfx.dart`.

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
docs/privacy-policy.md              # §35 — yayımlanacak metin
docs/store-listing.md               # §33 attribution + mağaza açıklaması
lib/
├── app/app.dart                    # servisleri kurar, MultiProvider
├── main.dart                       # StorageService açılır, sonra runApp
├── core/
│   ├── constants/puzzle_config.dart   # TÜM eşikler ve süreler, §atıflarıyla
│   ├── constants/debug_flags.dart     # debugShowPuzzleOverlay (K-4)
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
    │   │   │              # snap_calculator, tray_layout_calculator,
    │   │   │              # piece_image_mapper
    │   │   ├── path/      # jigsaw_path_generator, piece_paths
    │   │   ├── tray_shuffler.dart
    │   │   └── hint_target.dart
    │   ├── data/        # puzzle_catalog, puzzle_palette, progress_repository
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
    └── home/
        ├── screens/home_screen.dart    # §29 giriş ekranı
        ├── screens/about_screen.dart   # §26 sıfırlama + §33 attribution
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
- Balon testinde `pump(1500ms)` dördüncü balonu da getirir (spawn 1.2 sn).
  "Açılışta üç balon" iddiası için 1100 ms pump'lanır.
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
- **Album ve About kaydırılabilir**; `ListView` ekran dışındaki çocukları hiç
  kurmaz. Testler `scrollUntilVisible` kullanır ve **yalnızca tek yöne**
  kaydırır — sticker'lar katalog sırasında değil, album (kategori) sırasında
  gezilmeli, yoksa liste bir aşağı bir yukarı gitmek zorunda kalır ve test
  "Bad state: No element" ile patlar.

---

## 8. Açık borçlar

1. ~~CI hiç çalışmadı.~~ **Çözüldü** (13 Eylül): depo
   <https://github.com/ibrahimyasar68/emojipuzzle> (public), dokuz commit
   push edildi, `.github/workflows/ci.yml` her push'ta çalışıyor.
2. ~~OpenMoji attribution uygulamada görünmüyor.~~ **Faz 13'te yapıldı**:
   Home → ⓘ → Hakkında ekranı. **Mağaza açıklamasına eklenmesi hâlâ
   yapılmadı** (Faz 16).
3. **§42 gerçek cihaz profiling'i yapılmadı.** Faz 12 sonunda Pixel 6
   emülatöründe uygulama baştan sona elle oynandı (puzzle → kutlama →
   balon → sonraki puzzle, hepsi çalışıyor) ama bu bir profiling değildi.
   Yalnızca yapısal kısmı test edildi (board rebuild yok, kare başına
   notify yok). `flutter run --profile`
   ile bakılmalı.
4. ~~Faz 14 için hazır ama bağlanmamış.~~ **Faz 14'te bağlandı**:
   `WidgetsBindingObserver`, `PopScope`, drag iptali, progress kaydı.
   §28'in "müzik durur/devam eder" maddesi **boş geçildi — müzik yok**.
5. **Idle hint gözetimsiz oyunu kendi bitiriyor.** Emülatörde uygulama açık
   bırakıldı, §21'in 32 sn'lik auto-place merdiveni arka arkaya beş puzzle'ı
   kendi tamamladı. Spec'e uygun davranış ama Faz 16'da gözden geçirmeye
   değer: kimse oynamıyorken de ilerliyor.
5. **Cila (Faz 16):** konfetinin cihazdaki dağılımı, parıltıların açık
   görseller üzerinde sönük kalması, tamamlanınca kesikli slot çerçevesinin
   hâlâ görünmesi, Home'un tablette seyrek durması. (Tepsi parçalarındaki
   şekil bozukluğu Faz 15 sonunda düzeltildi.)

---

## 8b. Faz 13'e girerken verilmiş kararlar

- **"Her şey bitti" boş ekranı Faz 13'te düzgün çözülecek** (ara çözüm yok).
  Emülatörde yaşandı: dokuz puzzle da tamamlanınca `resume()` →
  `startNextPuzzle()` → `nextPuzzle == null` → sessiz çıkış → `appState`
  sonsuza dek `loading` → boş ekran. Spec'in cevabı §4'ün Serbest Mod'u.
- **Tepsi parçalarındaki hizalama kusuru Faz 16'ya bırakıldı.** Tepsideki
  her parçanın arkasındaki `PuzzlePalette` karesi ile jigsaw şekli hizasız;
  tırnaklar karenin dışında boyasız kalıyor. Board'da sorun yok.

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

**Kalanlar:**

1. ~~Idle hint gözetimsiz oyunu bitiriyor.~~ **Düzeltildi** (kullanıcı
   13 Eylül'de onayladı): `hintMaxAutoPlacesInARow = 2`. Üst üste iki
   auto-place'ten sonra merdiven uykuya geçer; **yalnızca ekrana dokunmak**
   uyandırır. Arka plandan dönmek ve sonraki puzzle'a geçmek uyandırmaz —
   uyandırsaydı gözlemlenen sonsuz döngü aynen sürerdi.
2. ~~GitHub remote yok.~~ **Çözüldü**, depo public ve push edildi.
3. **Gerçek cihazda profiling** — emülatör yeterli değil.
4. Küçük cila: Home tablette seyrek duruyor; parça sınırlarında 1 piksellik
   ton farkı kalıyor (delik yok, ölçüldü).
5. `docs/assets-inbox/frame6.png` — kullanıcının eklediği, kaynağı ve
   lisansı bilinmeyen 122×90 logo benzeri görsel. Pakete girmiyor, git'e de
   eklenmedi (depo public). Kaynağı belli olunca `assets/LICENSES.md`'ye
   işlenip yeri belirlenmeli.
