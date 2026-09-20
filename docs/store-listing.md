# Mağaza metni — EmojiPuzzle

Google Play ve App Store sayfalarında kullanılacak metinler ve görseller.
Attribution (§33) **zorunludur** ve açıklamanın içinde yer almalıdır.

Yayın adımlarının tamamı için: [play-store-release.md](play-store-release.md).

## Uygulama adı

EmojiPuzzle

Telefonda ikonun altında da bu ad görünür (`android:label`,
`CFBundleDisplayName`).

## Paket kimliği

`com.iylabs.emojipuzzle` — yayımlandıktan sonra **değiştirilemez**
(20 Eylül 2026, kullanıcı seçti).

## Görseller

| Ne | Dosya | Ölçü |
| -- | ----- | ---- |
| Mağaza ikonu (Play) | `docs/branding/play-store-icon-512.png` | 512×512 |
| App Store ikonu | `docs/branding/app-icon-1024.png` | 1024×1024 |
| Öne çıkan grafik (Play) | `docs/store/feature-graphic-1024x500.png` | 1024×500 |
| Telefon ekran görüntüleri | `docs/store/screenshots/*.png` | 1080×1920, 5 adet |

Öne çıkan grafiği `python3 tool/generate_store_graphics.py` üretir; içinde
yalnızca projenin kendi malzemesi vardır (uygulama ikonu, havuzdaki
resimler, oyunun renkleri) ve yazı tipi Flutter ile gelen Roboto'dur
(Apache 2.0). Ekran görüntüleri uygulamanın gerçek ekranlarıdır.

## Kısa açıklama (80 karakter sınırı)

3-5 yaş için sevimli emoji yapbozları. Reklamsız, çevrimdışı, kaybedilmez.

## Uzun açıklama

EmojiPuzzle, okuma yazma bilmeyen çocuklar için yapılmış sakin bir yapboz
oyunudur.

- **Kaybedilmez.** Yanlış yerleştirilen parça yumuşakça yerine döner. Kırmızı
  yok, uyarı sesi yok, süre yok, puan yok.
- **Yardım ister demeden gelir.** Çocuk bir süre duraksarsa oyun önce parçayı
  belirginleştirir, sonra yerini gösterir, en sonunda parçayı kendisi
  yerleştirir.
- **Her resim bir ödül.** Tamamlanan yapbozun ardından konfeti, balon
  eşleştirme oyunu ve albüme eklenen bir çıkartma gelir.
- **Boyama sayfası.** Her yapbozdan sonra bir arabanın bir parçası boyanır;
  renk serbest bir paletten seçilir. Beş parça bitince araba sürülüp gider.
- **Yavaş yavaş zorlaşır.** Yapbozlar 4 parçadan başlar, 16 parçaya kadar
  büyür. Resimler her oyunda havuzdan rastgele gelir: 21 resim, altı kategori.
- **Albüm.** Kazanılan her çıkartmaya dokunup o resmi yeniden oynayabilir.

Çocuk oynarken neyi çalıştırır:

- **Parça–bütün ilişkisi.** Bir resmin parçalardan oluştuğunu görmek ve
  eksik parçanın nereye ait olduğunu kestirmek.
- **Görsel ayırt etme.** Şekilleri, renkleri ve kenarları karşılaştırmak;
  balon oyununda aynı renkten iki balonu eşleştirmek.
- **El–göz koordinasyonu.** Parçayı tutmak, taşımak ve yerine bırakmak —
  parmak izleri her seferinde biraz daha isabetli olur.
- **Sabır ve deneme cesareti.** Yanlış bırakmanın bir cezası olmadığı için
  çocuk kendi hızında deneyebilir; oyun ancak duraksadığında yardım eder.
- **Renk seçimi ve karar verme.** Boyama sayfasında rengi serbest bir
  paletten kendisi seçer; doğrusu yanlışı yoktur.
- **Sınıflandırma ve sözcük dağarcığı.** Albüm resimleri meyveler,
  hayvanlar, taşıtlar, doğa, şekiller ve eşyalar diye ayırır; yetişkinle
  birlikte adlandırmak için iyi bir vesiledir.

Yapboz 4 parçadan başlar, 16 parçaya kadar büyür: zorluk çocuğun
ilerleyişiyle birlikte artar.

Ebeveynler için:

- Reklam yok, uygulama içi satın alma yok, hesap yok.
- İnternet bağlantısı istemez; hiçbir veri toplamaz ve göndermez.
- İlerleme yalnızca cihazda saklanır ve istendiğinde sıfırlanabilir.

## Attribution (zorunlu — §33)

> Emoji artwork: OpenMoji — the open-source emoji and icon project.
> Licence: CC BY-SA 4.0
> https://openmoji.org

Bu metin uygulamanın içinde de görünür (ⓘ → Görseller). Eşyalar
kategorisindeki üç resim (kitap, mikroskop, dürbün) projenin kendi
çizimidir; onlar için atıf gerekmez (K-16).

## Gizlilik politikası bağlantısı

<https://ibrahimyasar68.github.io/emojipuzzle/privacy-policy.html>

Metin `docs/privacy-policy.md` dosyasındadır; GitHub Pages ayarı açıldığında
yukarıdaki adresten yayımlanır.

## English listing (second language)

Play Console → Main store listing → Add translation → English (United
States). Use the same graphics.

### App name

EmojiPuzzle

### Short description (80 characters)

Gentle emoji jigsaws for ages 3-5. No ads, offline, nothing to lose.

### Full description

EmojiPuzzle is a calm jigsaw game made for children who cannot read yet.

- **Nothing to lose.** A piece dropped in the wrong place drifts softly back
  to the tray. No red crosses, no buzzers, no timer, no score.
- **Help arrives without being asked.** If the child hesitates, the game
  first highlights a piece, then shows where it goes, and finally places it.
- **Every picture is a reward.** A finished puzzle brings confetti, a
  balloon-matching game and a sticker for the album.
- **A colouring page.** After each puzzle the child paints one part of a
  car, in any colour from a free palette. Five parts and the car drives off.
- **It grows with the child.** Puzzles start at 4 pieces and grow to 16.
  Pictures come at random from a pool of 21, in six categories.
- **The album.** Tapping any sticker plays that picture again.

What the child practises while playing:

- **Part and whole.** Seeing that a picture is made of pieces, and working
  out where a missing piece belongs.
- **Visual discrimination.** Comparing shapes, colours and edges; matching
  two balloons of the same colour in the balloon game.
- **Hand-eye coordination.** Picking a piece up, carrying it and letting it
  go — the aim gets steadier with every puzzle.
- **Patience and willingness to try.** A wrong drop costs nothing, so the
  child can experiment at their own pace; the game only helps after a pause.
- **Choosing colours, making decisions.** On the colouring page the colour
  comes from a free palette, and no choice is wrong.
- **Sorting and vocabulary.** The album groups pictures into fruit, animals,
  vehicles, nature, shapes and objects — a good excuse to name things
  together with a grown-up.

Puzzles start at 4 pieces and grow to 16, so the challenge grows with the
child.

For parents:

- No ads, no in-app purchases, no accounts.
- No internet permission; the game collects and sends nothing.
- Progress is kept on the device only, and can be reset from the app.

Emoji artwork: OpenMoji — the open-source emoji and icon project.
Licence: CC BY-SA 4.0 · https://openmoji.org

## Sürüm notları (What's new)

Play Console her dil için ayrı ister ve **500 karakterde** keser (etiketler
bu sayıya girmez). Sürüm notu neyin değiştiğini söyler; mağaza
açıklamasının kısaltması değildir.

Çok dilli alana yapıştırırken metinler BCP-47 dil etiketleriyle sarılır:
Türkçe `<tr-TR>…</tr-TR>`, İngilizce (ABD) `<en-US>…</en-US>`. Etiket,
mağaza sayfasına **eklenmiş** dille birebir aynı olmalıdır — İngilizce
(Birleşik Krallık) eklendiyse `<en-GB>` — yoksa Play kabul etmez. Etiketler
büyük-küçük harfe duyarlıdır.

```text
<tr-TR>
… aşağıdaki Türkçe metin …
</tr-TR>
<en-US>
… aşağıdaki İngilizce metin …
</en-US>
```

### 1.0.0 — Türkçe

İlk sürüm. 3-5 yaş için sakin bir yapboz oyunu: 21 resim ve dört parçadan
on altı parçaya büyüyen yapbozlar. Her biten resimden sonra konfeti, balon
eşleştirme oyunu, albüme giren bir çıkartma ve bir boyama sayfası gelir.
Yanlış konan parça yumuşakça yerine döner; süre, puan ve kaybetmek yoktur.
Reklam yok, satın alma yok, internet izni yok; ilerleme yalnızca cihazda
saklanır.

### 1.0.0 — English

First release. A calm jigsaw game for ages 3-5: 21 pictures and puzzles
that grow from four pieces to sixteen. Every finished picture brings
confetti, a balloon-matching game, a sticker for the album and a colouring
page. A piece dropped in the wrong place drifts softly back; there is no
timer, no score and nothing to lose. No ads, no purchases, no internet
permission; progress stays on the device.

## Kategori ve hedef kitle

- Google Play: Eğitim (ya da Oyun → Bulmaca) / Designed for Families,
  hedef yaş **5 ve altı**
- App Store: Kids, 5 ve altı

## Veri güvenliği formunun cevapları (Play Console)

| Soru | Cevap |
| ---- | ----- |
| Uygulama veri topluyor mu? | Hayır |
| Uygulama veri paylaşıyor mu? | Hayır |
| Veriler aktarımda şifreleniyor mu? | Veri aktarılmıyor |
| Kullanıcı verisinin silinmesini isteyebilir mi? | Veri toplanmıyor; cihazdaki ilerleme uygulama içinden sıfırlanır |
| Reklam var mı? | Hayır |
| Üçüncü taraf analitik/çökme aracı? | Yok |

Bu cevaplar kodla doğrulanabilir: yayın manifestinde izin yoktur
(`test/architecture/asset_policy_test.dart`), uygulamada ağ çağrısı yapan
bir paket kullanılmaz (§37 listesi: provider, shared_preferences,
audioplayers, confetti).
