/// Ayarlanabilir puzzle sabitleri.
///
/// Her sabit, hangi spec bölümünden geldiğini belirtir (§46). Sabitler onları
/// ilk kullanan fazda eklenir; bu yüzden burada hiçbir şey spekülatif
/// değildir.
abstract final class PuzzleConfig {
  /// §7 — Tırnak taşması, hücrenin kısa kenarının bir oranı olarak.
  ///
  /// Kısa kenarı kullanmak, dar hücrelerde tırnakların şişmesini önler
  /// (örneğin kare bir board'da 2×3, 166,67 × 250 hücre verir).
  static const double tabSizeRatio = 0.20;

  /// §14 — Bir parça *boyanırken* uygulanan dışa taşma, mantıksal piksel.
  ///
  /// Matematiksel olarak birbirini tamamlayan iki path bile aralarında bir
  /// kıl çizgi bırakır: her iki taraf sınır pikselinin kabaca yarısını
  /// kaplar ve yarı örtülü iki yumuşatılmış kenar bir araya gelip opak bir
  /// kenar etmez. Her parçayı bir kıl payı büyük boyamak, komşuların
  /// örtüşmesini sağlar. Snap ve hit-test tam geometriyi kullanmaya devam
  /// eder.
  ///
  /// Yarım değil, tam bir piksel: taşma kontur boyunca çizgi olarak boyanır
  /// ve o çizginin de kendi yumuşatılmış dış kenarı vardır. Yarım piksel, en
  /// kötü sınır pikselini alfa 237'de bırakıyordu; tam piksel ise
  /// birleştirilmiş board'da hiçbir yerde saydam piksel bırakmıyor. Tahmin
  /// değil, ölçüm — bkz.
  /// `test/features/puzzle/widgets/puzzle_board_preview_test.dart`
  /// içindeki dikiş denetimi.
  static const double renderBleedPixels = 1;

  /// §6.1, §40 — Board bunun ötesine hiç büyümez, tablet dahil.
  static const double maxBoardSize = 500;

  /// §40 — Board'un alabileceği yükseklik payı; geri kalanı tepsinin
  /// sığması gereken yerdir (§16.1).
  static const double boardHeightFactor = 0.6;

  /// Board'un etrafındaki nefes payı. Spec tarafından dayatılmaz; 360 dp'lik
  /// bir ekranı §16.1'in 344'lük referans board'una çeviren şey budur.
  static const double boardMargin = 8;

  /// §2 — Çocuğun dokunmak zorunda olduğu hiçbir şey bundan küçük olamaz.
  /// Buna uyamayan yerleşim değişir, bu sayı değil.
  static const double minTouchTargetSize = 64;

  /// §16.1 — Tepsi parçaları board boyutlarının bu oranını hedefler. Bu bir
  /// hedeftir, alt sınır değil: çakıştıklarında [minTouchTargetSize] kazanır.
  static const double trayPreferredPieceScale = 0.70;

  /// §16.1 — Tepsi parçaları arasındaki en küçük boşluk.
  static const double trayItemSpacing = 12;

  /// §15 — Boş board'un içinden görünen resmin opaklığı.
  static const double ghostOpacity = 0.25;

  /// §15 — Her boş yuvanın etrafına çizilen kesikli kontur.
  ///
  /// Hücrenin düz kenarını değil, oraya ait parçanın şeklini izler, tırnaklar
  /// dahil: çocuğa yalnızca nerede değil, ne eksik olduğunu söyler. §15 bir
  /// konturun taşıması gereken nitelikleri sayar — ince, kesikli, anlaşılır,
  /// çocuğun kolay görebileceği — ve geometriyi açık bırakır.
  static const double slotOutlineStrokeWidth = 1.5;
  static const double slotOutlineDashLength = 7;
  static const double slotOutlineDashGap = 5;

  /// §17 — Parçayı alma: tepsi boyundan board boyuna büyürken yolda
  /// [dragEmphasisScale] kadar şişer ve yüzeyden kalkar.
  static const Duration dragLiftDuration = Duration(milliseconds: 120);
  static const double dragEmphasisScale = 1.1;
  static const double dragElevation = 6;

  /// §18 — Snap eşiği: hiçbir zaman [minSnapThreshold]'dan dar olmaz, onun
  /// dışında hücrenin kısa kenarının bir oranıdır.
  static const double minSnapThreshold = 24;
  static const double snapThresholdRatio = 0.35;

  /// §19 — Assist modu. *Aynı parçanın* bu kadar başarısız bırakmasından
  /// sonra snap eşiği [assistThresholdMultiplier] kadar genişler. Parça o
  /// zaman daha uzaktan gelip oturabilir; bu bilinçli bir takastır, çünkü
  /// takılıp kalan bir çocuk daha kötü bir sonuçtur.
  static const int assistFailedAttempts = 3;
  static const double assistThresholdMultiplier = 1.8;

  /// §20 — Yanlış bırakmanın tek karşılığı: eve dönerken yumuşak bir
  /// sallanma. Kırmızı yok, ses yok, titreşim yok, "tekrar dene" yok.
  static const Duration rubberBandDuration = Duration(milliseconds: 250);
  static const double rubberBandOvershoot = 1.08;
  static const double rubberBandUndershoot = 0.96;

  /// §22 — Doğru bırakma, tüm başarı geri bildirimine tanınan 400 ms'nin
  /// epey içinde yuvasına yerleşir.
  static const Duration snapSettleDuration = Duration(milliseconds: 160);

  /// §22 — bir parça için "aferin"in tamamı: pop sesi, parıltılar, dokunuş.
  /// Bu bir tavandır, hedef değil ve asla sonraki parçayı bekletmemelidir.
  static const Duration placementFeedbackDuration = Duration(milliseconds: 400);

  /// §22 — altı ila sekiz parıltı.
  static const int sparkleCount = 7;

  /// §22 — parçanın yuvasına düşerken yaptığı ezilme.
  static const double settlePopScale = 1.06;

  /// §21 — oyun yardım önermeden önce çocuğun board'a ne kadar
  /// bakabileceği ve giderek yükselen her teklif arasındaki aralık:
  /// 8, 16, 24, 32 saniye.
  static const Duration hintFirstDelay = Duration(seconds: 8);
  static const Duration hintStageInterval = Duration(seconds: 8);
  static const Duration hintTickInterval = Duration(milliseconds: 500);

  /// §21 — oyunun, önermeyi bırakıp dokunulmayı beklemeden önce arka arkaya
  /// kaç parçayı kendi yerleştireceği.
  ///
  /// Merdiven takılan bir çocuk için vardır. Boş bir odada çalışmaya
  /// bırakıldığında puzzle üstüne puzzle bitiriyordu; bu yardım değildir.
  static const int hintMaxAutoPlacesInARow = 2;

  /// §21 — bir ipucu nabzının tek vuruşu ve ne kadar şiştiği.
  static const Duration hintPulseDuration = Duration(milliseconds: 600);
  static const double hintPulseScale = 1.12;

  /// §21 — hayaletin tepsiden yuvaya süzülmesinin ne kadar sürdüğü.
  static const Duration hintGhostDuration = Duration(milliseconds: 1200);
  static const double hintGhostOpacity = 0.45;

  /// §23 — başka hiçbir şey olmadan önce tamamlanmış resim kendi anını
  /// yaşar.
  static const Duration completionAnimationDuration =
      Duration(milliseconds: 600);

  /// §23 — çocuk sadece izlerse kutlamanın tamamı. Bir dokunuş onu anında
  /// bitirir: kimse buna katlanmak zorunda bırakılmaz.
  static const Duration celebrationDuration = Duration(milliseconds: 2200);

  /// §42 — ekranın tamamı için parçacık bütçesi.
  static const int confettiParticles = 15;

  /// §2 — balon hareketli bir hedeftir, bu yüzden geri kalan her şeyin
  /// uyduğu 64 px'ten daha büyük bir vurma alanı alır.
  static const double balloonTouchTargetSize = 72;

  /// §24 — mini oyun toplamda on iki balon üretir ve aynı anda havada
  /// asla sekizden fazlası olmaz.
  static const int balloonTotal = 12;
  static const int balloonMaxActive = 8;

  /// §24 — oyun açıldığında üç tanesi bekliyordur, sonra yer oldukça kabaca
  /// her 1,2 saniyede bir tane gelir.
  static const int balloonInitialSpawn = 3;
  static const Duration balloonSpawnInterval = Duration(milliseconds: 1200);

  /// §24 — oyun nasıl gidiyor olursa olsun on beşinci saniyede biter.
  static const Duration balloonGameDuration = Duration(seconds: 15);

  /// §24 — on ikisini de patlatmak oyunu erken bitirir; duraklama, son
  /// patlamanın görülmesine yetecek kadardır.
  static const Duration balloonEarlyFinishDelay = Duration(milliseconds: 500);

  /// §24 — oyunun saatine ne sıklıkta baktığı. Bir iki kare şaşarak dakik
  /// ve ucuz.
  static const Duration balloonTickInterval = Duration(milliseconds: 50);

  /// §24 — bir balon bu süre boyunca oyun alanına süzülür, sonra yerinde
  /// salınır. Balonlar asla yukarıdan kaçmaz: on ikisini de patlatan bir
  /// çocuk erken bitişi hak etmiştir ve uçup giden bir balon bunu sessizce
  /// elinden alırdı.
  ///
  /// Balon kendi yerine süzülür ve süzülürken yavaşça belirir; ekran boyu
  /// yukarı uçmaz. Oyun alanını baştan sona kat etmek, onu çoktan orada
  /// duran balonların üzerinden geçirirdi ve örtülmüş bir balon, çocuğun
  /// vuramayacağı bir dokunma hedefidir (§2).
  static const Duration balloonRiseDuration = Duration(milliseconds: 1000);
  static const double balloonRiseDistance = 0.35;
  static const Duration balloonBobPeriod = Duration(milliseconds: 2600);
  static const double balloonBobAmplitude = 7;

  /// §24 — dokun ve patlat: balon şişer, sonra patlar.
  static const Duration balloonPopDuration = Duration(milliseconds: 260);
  static const double balloonPopScale = 1.25;

  /// §42 — bir patlama küçüktür; birkaçı üst üste binse bile 40 parçacık
  /// bütçesinin içinde yer kalır.
  static const int balloonPopParticles = 8;

  /// §23, §25 — çıkartmanın teslimi. Dizinin en kısa adımı: çıkartmalara
  /// bakılan yer albümdür, burası yalnızca birinin verildiği andır. Bir
  /// dokunuş onu daha erken bitirir.
  static const Duration stickerRewardDuration = Duration(milliseconds: 1600);
  static const Duration stickerRewardPopDuration = Duration(milliseconds: 650);
  static const double stickerRewardSize = 190;
}
