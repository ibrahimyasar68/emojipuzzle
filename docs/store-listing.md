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
