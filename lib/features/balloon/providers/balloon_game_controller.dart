import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/balloon.dart';

/// Balon mini oyununun kuralları (§24): kaç balon olduğu, ne zaman
/// geldikleri, hangi ikisinin birlikte patladığı ve oyunun ne zaman
/// bittiği.
///
/// Oyun renk eşleştirmedir (K-5): bir balona dokunmak onu seçer, aynı
/// renkten ikinci bir balona dokunmak ikisini birlikte patlatır. Farklı
/// renkten bir balona dokunmak bir hata değildir; seçim sessizce oraya
/// geçer (§20).
///
/// Piksel de widget da tutmaz; böylece "altı renk çifti, aynı anda sekiz,
/// on beş saniye" bir birim testinde saniye saniye denetlenebilir. Saat, sade
/// bir zamanlayıcıdır ve [advance] ile elle sürülebilir — `HintController`
/// ile aynı kalıp (§21).
///
/// Burada hiçbir yerde başarısızlık yolu yoktur. Süre dolduğunda havada
/// kalan balonlar sayılmaz, bildirilmez ve anılmaz: oyun sadece biter
/// (§20, §24).
class BalloonGameController extends ChangeNotifier {
  BalloonGameController({
    this.total = PuzzleConfig.balloonTotal,
    this.maxActive = PuzzleConfig.balloonMaxActive,
    this.initialSpawn = PuzzleConfig.balloonInitialSpawn,
    this.spawnInterval = PuzzleConfig.balloonSpawnInterval,
    this.timeLimit = PuzzleConfig.balloonGameDuration,
    this.earlyFinishDelay = PuzzleConfig.balloonEarlyFinishDelay,
    this.tickInterval = PuzzleConfig.balloonTickInterval,
    this.partnerHintDelay = PuzzleConfig.balloonPartnerHintDelay,
    this.colourCount = 5,
    Random? random,
  })  : _random = random ?? Random(),
        assert(total > 0, 'a game with no balloons is not a game'),
        assert(total % 2 == 0, 'balloons come in pairs (K-5)'),
        assert(maxActive >= 2, 'at least one pair must fit'),
        assert(initialSpawn % 2 == 0, 'the opening is whole pairs'),
        assert(initialSpawn <= maxActive, 'the opening cannot break the cap');

  /// Oyunun toplamda kaç balon ürettiği.
  final int total;

  /// Aynı anda havada olabilecek balon sayısının tavanı.
  final int maxActive;

  /// Oyun açıldığında kaç tanesinin çoktan havada olduğu; her zaman çift.
  final int initialSpawn;

  /// Yer olduğunda bir çift ile diğeri arasındaki aralık.
  final Duration spawnInterval;

  /// Seçili bir balonun eşine ne zaman nabız attırılacağı.
  final Duration partnerHintDelay;

  /// Oyun nasıl gidiyor olursa olsun bu noktada biter.
  final Duration timeLimit;

  /// Son balonun patlaması ile oyunun kapanması arasındaki duraklama;
  /// çocuk hak ettiği patlamayı görsün diye.
  final Duration earlyFinishDelay;

  /// Saate ne sıklıkta bakıldığı.
  final Duration tickInterval;

  /// Widget'ın boyadığı balon paletinin boyutu.
  final int colourCount;

  /// Oyun alanı hücrelere bölünür ve iki balon aynı hücreyi paylaşmaz;
  /// böylece bir balon asla bir diğerinin arkasında yarı gizli kalmaz.
  /// Üst üste binen balonlar, çocuğun vurması gereken 72 px'i sessizce
  /// yer (§2).
  ///
  /// Üç sütun ve beş satır, en fazla sekiz balon için on beş yer demektir;
  /// bu da dizilimin ızgara gibi değil, dağınık görünmesini sağlar.
  static const int columns = 3;
  static const int rows = 4;

  final Random _random;

  /// İçinde kimse olmayan hücreler, kullanılacakları sırayla.
  final List<int> _freeCells = [];

  /// Her balonun hangi hücreyi aldığı; patlayınca geri versin diye.
  final Map<int, int> _cellOf = {};

  /// Paletin nereden başladığı; her oyun turuncuyla açılmasın diye.
  late final int _colourOffset = _random.nextInt(colourCount);

  /// Oyun nasıl biterse bitsin, bittiğinde bir kez çağrılır.
  VoidCallback? onFinished;

  Timer? _timer;
  final List<Balloon> _balloons = [];
  int _spawned = 0;
  int _popped = 0;
  Duration _elapsed = Duration.zero;
  Duration _sinceSpawn = Duration.zero;
  Duration? _closeAt;
  bool _finished = false;
  bool _paused = false;
  int? _selectedId;
  Duration? _selectedAt;

  /// Havadaki balonlar, geliş sıralarıyla.
  List<Balloon> get balloons => List.unmodifiable(_balloons);

  /// Şimdiye kadar kaç tane üretildiği, patlatılanlar dahil.
  int get spawnedCount => _spawned;

  /// Çocuğun kaç tanesini patlattığı.
  int get poppedCount => _popped;

  /// Çocuğun seçtiği ve eşini beklediği balon; yoksa null.
  int? get selectedId => _selectedId;

  /// Seçili balon [partnerHintDelay] kadar beklediyse, onunla aynı renkteki
  /// balonlardan biri — nabız atacak olan. Aksi halde null.
  ///
  /// Ekranda her rengin balon sayısı her an çift olduğu için seçili bir
  /// balonun eşi her zaman oradadır.
  int? get partnerHintId {
    final selectedId = _selectedId;
    final selectedAt = _selectedAt;
    if (selectedId == null || selectedAt == null) return null;
    if (_elapsed - selectedAt < partnerHintDelay) return null;

    final colour = _find(selectedId)?.colourIndex;
    for (final balloon in _balloons) {
      if (balloon.id != selectedId && balloon.colourIndex == colour) {
        return balloon.id;
      }
    }
    return null;
  }

  Duration get elapsed => _elapsed;
  bool get isRunning => _timer != null;
  bool get isFinished => _finished;
  bool get isPaused => _paused;

  /// §28 — uygulama arka plana gitti. Saat olduğu yerde durur: ödül,
  /// çocuğun uzakta kalıp kaybedebileceği bir şey değildir (§30).
  void pause() {
    if (_paused || _finished) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// Geri dönüldü; kalan süre ne idiyse tam olarak o kadar.
  void resume() {
    if (!_paused || _finished) return;
    _paused = false;
    _timer = Timer.periodic(tickInterval, (_) => advance(tickInterval));
  }

  /// Oyunu açar: ilk balonlar çoktan havadadır.
  void start() {
    if (_timer != null || _finished) return;
    _refillFreeCells();
    // Oyunu açan balonlar, yükselirken aynı anda havada olan tek gruptur;
    // bu yüzden sütunlara sırayla dağıtılır. Aynı sütuna düşen ikisi aynı
    // anda, aynı hızda yükselir ve aralarındaki mesafe hiç kapanmaz.
    final columnOrder = List<int>.generate(columns, (i) => i)..shuffle(_random);
    for (var i = 0; i < initialSpawn && _canSpawnPair; i += 2) {
      _spawnPair(
        preferredColumns: (
          columnOrder[i % columns],
          columnOrder[(i + 1) % columns],
        ),
      );
    }
    _timer = Timer.periodic(tickInterval, (_) => advance(tickInterval));
    notifyListeners();
  }

  /// Saati ilerletir. Zamanlayıcı bunu her tıkta çağırır; testler doğrudan
  /// çağırır, böylece on beş saniye hiç zaman almaz.
  @visibleForTesting
  void advance(Duration by) {
    if (_finished || _paused) return;
    _elapsed += by;

    // Erken bitiş çoktan ayarlandı: yeni bir şey gelmez, yalnızca son
    // patlamanın görülmesi beklenir.
    final closeAt = _closeAt;
    if (closeAt != null) {
      if (_elapsed >= closeAt) _finish();
      return;
    }

    if (_elapsed >= timeLimit) {
      _finish();
      return;
    }

    var spawned = false;
    _sinceSpawn += by;
    while (_sinceSpawn >= spawnInterval) {
      _sinceSpawn -= spawnInterval;
      // Aralık, ona yer olup olmadığına bakılmadan önce harcanır ve bu
      // bilinçlidir: dolu kalan bir ekran kredi biriktirip bir balon
      // patladığı anda topluca balon salmaz.
      if (!_canSpawnPair) break;
      _spawnPair();
      spawned = true;
    }

    if (spawned) notifyListeners();
  }

  /// Çocuk bir balona dokundu (K-5). Patlayanları döndürür: ya aynı
  /// renkten iki balon, ya da hiçbiri.
  ///
  /// * Seçili balon yoksa, bu balon seçilir.
  /// * Seçili balonun kendisine dokunmak hiçbir şey yapmaz; çift dokunuşun
  ///   bir anlamı yoktur (§2).
  /// * Seçili balonla aynı renkteyse ikisi birlikte patlar.
  /// * Farklı renkteyse seçim sessizce bu balona geçer. Sayılmaz, anılmaz
  ///   (§20).
  ///
  /// Bilinmeyen kimlikler yok sayılır: çoktan gitmiş bir balona dokunmak
  /// hata değil, çocuğun parmağıdır.
  List<Balloon> tap(int id) {
    if (_finished) return const [];
    final balloon = _find(id);
    if (balloon == null) return const [];

    final selectedId = _selectedId;
    final selected = selectedId == null ? null : _find(selectedId);
    if (selected != null && selected.id == id) return const [];

    if (selected == null || selected.colourIndex != balloon.colourIndex) {
      _selectedId = id;
      _selectedAt = _elapsed;
      notifyListeners();
      return const [];
    }

    _selectedId = null;
    _selectedAt = null;
    _remove(selected);
    _remove(balloon);

    // Üretilen bütün balonlar patlatıldı: erken bitirmenin ödülü, erken
    // bitirmektir (§24).
    if (_popped >= total) _closeAt = _elapsed + earlyFinishDelay;

    notifyListeners();
    return [selected, balloon];
  }

  Balloon? _find(int id) {
    for (final balloon in _balloons) {
      if (balloon.id == id) return balloon;
    }
    return null;
  }

  void _remove(Balloon balloon) {
    _balloons.remove(balloon);
    _popped++;

    // Durduğu yer yeniden boşaldı.
    final cell = _cellOf.remove(balloon.id);
    if (cell != null) _freeCells.add(cell);
  }

  bool get _canSpawnPair =>
      _spawned + 2 <= total &&
      _balloons.length + 2 <= maxActive &&
      _freeCells.length >= 2;

  /// Boş bir hücre; istenen sütunda boş varsa oradan.
  int _takeCell(int? preferredColumn) {
    var index = _random.nextInt(_freeCells.length);
    if (preferredColumn != null) {
      final inColumn =
          _freeCells.indexWhere((c) => c % columns == preferredColumn);
      if (inColumn >= 0) index = inColumn;
    }
    return _freeCells.removeAt(index);
  }

  void _refillFreeCells() {
    _freeCells
      ..clear()
      ..addAll(List<int>.generate(columns * rows, (i) => i));
    _freeCells.shuffle(_random);
  }

  /// Aynı renkten iki balon, aynı anda (K-5). Balonlar hep ikişer doğup
  /// ikişer patladığı için ekranda her rengin sayısı her an çifttir.
  ///
  /// Çiftler paletten çekilmek yerine palet üzerinde yürür: arka arkaya beş
  /// çift beş farklı renktir.
  void _spawnPair({(int, int)? preferredColumns}) {
    final colourIndex = (_spawned ~/ 2 + _colourOffset) % colourCount;
    _spawn(colourIndex, preferredColumn: preferredColumns?.$1);
    _spawn(colourIndex, preferredColumn: preferredColumns?.$2);
  }

  void _spawn(int colourIndex, {int? preferredColumn}) {
    final cell = _takeCell(preferredColumn);
    final column = cell % columns;
    final row = cell ~/ columns;

    // Hücrenin ortası; hücrelerin balon çevresinde bıraktığı boşluktan
    // biraz az kaydırılır, böylece sapma o boşluğu asla kapatamaz.
    final balloon = Balloon(
      id: _spawned,
      x: (column + 0.5) / columns + (_random.nextDouble() - 0.5) * 0.014,
      restY: (row + 0.5) / rows + (_random.nextDouble() - 0.5) * 0.014,
      colourIndex: colourIndex,
      sizeFactor: 0.92 + _random.nextDouble() * 0.14,
      bobPhase: _random.nextDouble(),
      bornAt: _elapsed,
    );
    _cellOf[balloon.id] = cell;
    _balloons.add(balloon);
    _spawned++;
  }

  void _finish() {
    if (_finished) return;
    _finished = true;
    _timer?.cancel();
    _timer = null;
    notifyListeners();
    onFinished?.call();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
