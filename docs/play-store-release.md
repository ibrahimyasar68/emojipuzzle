# Play Store yayın kontrol listesi — EmojiPuzzle

20 Eylül 2026'da hazırlandı. Kodda yapılabilecek her şey yapıldı; kalanlar
Play Console'da ya da parola gerektirdiği için **sizin** yapmanız gereken
adımlardır.

## 1. Bende biten teknik hazırlık

| Konu | Durum |
| ---- | ----- |
| Paket kimliği | `com.iylabs.emojipuzzle` (yayından sonra değişmez) |
| Sürüm | `1.0.0+1` → versionName 1.0.0, versionCode 1 |
| Hedef SDK | 36 (Play en az 35 istiyor), min SDK 24 |
| 16 KB bellek sayfası uyumu | Bütün `.so` dosyaları hizalı (ölçüldü) |
| İzinler | Yayın manifestinde kullanıcıya görünen izin yok |
| Ekran yönü | Kilit kaldırıldı: dikey ve yatay çalışır |
| App Bundle | `flutter build appbundle --release` → 41 MB |
| Mağaza görselleri | İkon, öne çıkan grafik, 5 ekran görüntüsü hazır |
| Gizlilik metni | `docs/privacy-policy.md` |
| Mağaza metinleri | `docs/store-listing.md` |

Tek teknik engel imzadır (aşağıda).

## 2. Yayın anahtarı — sizin yapmanız gerekiyor

Yayın paketi şu an **debug anahtarıyla** imzalanıyor; Play bunu kabul etmez.
Anahtar parola ister, parolayı ben giremem. Terminalde şunu çalıştırın:

```bash
keytool -genkey -v -keystore ~/emojipuzzle-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

Sonra `android/key.properties` dosyasını şu içerikle oluşturun:

```properties
storePassword=<az önce verdiğiniz parola>
keyPassword=<az önce verdiğiniz parola>
keyAlias=upload
storeFile=/Users/<kullanıcı>/emojipuzzle-upload.jks
```

Bu dosya ve `.jks` **depoya girmez** (`android/.gitignore` içinde). Anahtarı
kaybederseniz uygulamayı bir daha güncelleyemezsiniz: yedekleyin.

Hazır olduğunda:

```bash
flutter build appbundle --release
```

Gradle `key.properties` yoksa uyarı basar ve debug anahtarına düşer; uyarıyı
görüyorsanız paketi yüklemeyin.

## 3. Play Console'da yapılacaklar

1. **Geliştirici hesabı.** Bireysel hesapla açılan yeni uygulamalarda Google,
   üretime çıkmadan önce **12 test kullanıcısıyla 14 gün kapalı test**
   istiyor. Kurumsal hesapta bu şart yok.
2. Uygulama oluştur: ad **EmojiPuzzle**, dil Türkçe, tür Uygulama/Oyun,
   ücretsiz.
3. **Mağaza sayfası**: kısa/uzun açıklama, ikon, öne çıkan grafik, ekran
   görüntüleri (`docs/store/`), kategori, iletişim e-postası.
4. **Gizlilik politikası adresi**: GitHub Pages'i açın (depo → Settings →
   Pages → Source: `main` / `docs`), sonra adresi yapıştırın:
   <https://ibrahimyasar68.github.io/emojipuzzle/privacy-policy.html>
5. **Veri güvenliği formu**: cevaplar `docs/store-listing.md` içinde.
6. **İçerik derecelendirme anketi**: şiddet yok, korku yok, kullanıcılar
   arası iletişim yok, konum yok, satın alma yok.
7. **Hedef kitle ve içerik**: hedef yaş **5 ve altı** → uygulama
   "Designed for Families" kurallarına girer; reklam yok seçeneğini işaretle.
8. **Reklamlar**: "Uygulamam reklam içermiyor".
9. **Uygulama erişimi**: tüm içerik girişsiz erişilebilir.
10. `app-release.aab` dosyasını yükleyin (önce kapalı test, sonra üretim).

## 4. Yayından önce bakılması iyi olacaklar

- **Gerçek cihazda elle oynama.** Faz 17–24 yalnızca testlerle doğrulandı;
  emülatörde en son Faz 16 oynandı.
- **Yatay ekran.** Kilit yeni kalktı; yatay yerleşimler testlerde geçiyor ama
  cihazda görülmedi.
- **Gizlilik metnindeki iletişim adresi** boş: mağaza sayfasında da zorunlu.
- **İkinci dil.** Uygulama Türkçe; mağaza sayfasına İngilizce açıklama da
  eklenirse erişim artar.
