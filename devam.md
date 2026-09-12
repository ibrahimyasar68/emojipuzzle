# Devam Notu — Emoji Puzzle Kids

Bu dosya, yeni bir sohbette kaldığı yerden devam edebilmek için yazıldı.
Son güncelleme: 12 Eylül 2026, Faz 11 sonunda.

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
| **11** | **Kutlama + konfeti (atlanabilir)** | **⏳ onay bekliyor** |
| 12 | Balon mini oyunu | ⬜ sırada |
| 13 | Album, Home, Serbest Mod, progress reset | ⬜ |
| 14 | Navigation, Android Back, lifecycle | ⬜ |
| 15 | Responsive, tablet, accessibility | ⬜ |
| 16 | Asset/lisans denetimi, privacy, final cila | ⬜ |

**Durum:** `flutter analyze` temiz, `flutter test` yeşil — **721 test**.

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
7. **Dil:** kullanıcıya Türkçe, kod/yorum/commit İngilizce.
8. **İndirme veya sisteme kurulum öncesi izin istenir.**

---

## 4. Komutlar

```bash
flutter analyze
flutter test
dart format lib test tool
dart run tool/generate_sfx.dart     # ses dosyalarını yeniden üretir
```

Testler `build/` altına kanıt görselleri bırakır: `preview_2x2.png`,
`screen_3x3.png`, `solved_2x2.png`, `drag_overlay.png`, `hint_ghost.png`,
`placement_feedback.png`, `level2_banana.png`.

---

## 5. Dosya haritası

```text
docs/spec-v2.2.md                   # EMOJI PUZZLE KIDS v2.2 — tek kaynak (§0–§51)
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
    └── celebration/widgets/celebration_overlay.dart
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

---

## 8. Açık borçlar

1. **CI hiç çalışmadı.** `git init` yapıldı ama **commit yok**, GitHub remote
   yok. İlk commit + remote bağlanınca workflow devreye girer.
2. **OpenMoji attribution uygulamada görünmüyor.** Faz 13'te ebeveyn/hakkında
   alanına ve mağaza açıklamasına eklenmeli (`assets/LICENSES.md` metni hazır).
3. **§42 gerçek cihaz profiling'i yapılmadı.** Yalnızca yapısal kısmı test
   edildi (board rebuild yok, kare başına notify yok). `flutter run --profile`
   ile bakılmalı.
4. **Faz 14 için hazır ama bağlanmamış:** `HintController.pause()/resume()`
   (§28) ve `GameProvider.saveProgress()/pendingWrite` (§30).
5. **Cila (Faz 16):** konfetinin cihazdaki dağılımı, parıltıların açık
   görseller üzerinde sönük kalması, tamamlanınca kesikli slot çerçevesinin
   hâlâ görünmesi.

---

## 9. Sıradaki iş: Faz 12 — Balon mini oyunu (§24)

**Kabul kriteri:** "Balonlar çalışıyor, erken bitiş ve 15 sn timeout."

Spec'in istedikleri:

- Ayrı feature modülü (`features/balloon/`), puzzle feature'ına **bağımlı olmaz**.
- Toplam **12 balon** üretilir; aynı anda en fazla **8 aktif**.
- Spawn: başta 3 balon, sonra ~1,2 sn'de bir.
- Minimum dokunma hedefi **72 px** (§2 — puzzle'daki 64 px'ten büyük).
- Bitiş, hangisi önce olursa: 12 balonun hepsi patlatıldı → **500 ms sonra
  kapanır**; ya da **15 sn** doldu.
- Patlatılmamış balon kalması **başarısızlık değildir**, hiçbir geri bildirim
  verilmez (§20).
- Akış: idle floating → tap → scale → pop sound → particle → disappear.
- `AudioService.playBalloonPop()` ve `assets/audio/sfx/balloon_pop.wav` hazır.

**Nereye bağlanacak:** `puzzle_screen.dart` içindeki `_finishCelebration`.
§23'ün akışı şöyle: kutlama → **balon oyunu** → sticker (Faz 13) → sonraki
puzzle. Şu anda kutlama bitince doğrudan `game.startNextPuzzle()` çağrılıyor;
balon oyunu bu iki adımın arasına girecek.

**Önerilen yapı:** zamanlama ve spawn mantığı `BalloonGameController` gibi
zamanlayıcıdan bağımsız test edilebilir bir sınıfta (HintController'daki
kalıbın aynısı), görsel kısım ayrı widget'ta. Böylece "12 balon, 8 aktif,
15 sn, erken bitiş" kuralları saniye saniye test edilebilir.
