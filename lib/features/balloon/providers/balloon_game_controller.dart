import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/balloon.dart';

/// Balon mini oyununun kuralları (§24): kaç balon olduğu, ne zaman
/// geldikleri ve oyunun ne zaman bittiği.
///
/// Piksel de widget da tutmaz; böylece "on iki balon, aynı anda sekiz, on
/// beş saniye" bir birim testinde saniye saniye denetlenebilir. Saat, sade
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
    this.colourCount = 5,
    Random? random,
  })  : _random = random ?? Random(),
        assert(total > 0, 'a game with no balloons is not a game'),
        assert(maxActive > 0, 'at least one balloon must fit'),
        assert(initialSpawn <= maxActive, 'the opening cannot break the cap');

  /// Oyunun toplamda kaç balon ürettiği.
  final int total;

  /// Aynı anda havada olabilecek balon sayısının tavanı.
  final int maxActive;

  /// Oyun açıldığında kaç tanesinin çoktan havada olduğu.
  final int initialSpawn;

  /// Yer olduğunda bir balon ile diğeri arasındaki aralık.
  final Duration spawnInterval;

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

  /// Havadaki balonlar, geliş sıralarıyla.
  List<Balloon> get balloons => List.unmodifiable(_balloons);

  /// Şimdiye kadar kaç tane üretildiği, patlatılanlar dahil.
  int get spawnedCount => _spawned;

  /// Çocuğun kaç tanesini patlattığı.
  int get poppedCount => _popped;

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
    // bu yüzden her birine ayrı bir sütun verilir.
    final columnOrder = List<int>.generate(columns, (i) => i)..shuffle(_random);
    for (var i = 0; i < initialSpawn && _canSpawn; i++) {
      _spawn(preferredColumn: columnOrder[i % columns]);
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
      if (!_canSpawn) break;
      _spawn();
      spawned = true;
    }

    if (spawned) notifyListeners();
  }

  /// Çocuk bir balona dokundu. Bilinmeyen kimlikler yok sayılır: çoktan
  /// gitmiş bir balona ikinci kez dokunmak hata değil, çocuğun parmağıdır
  /// (§20).
  void pop(int id) {
    if (_finished) return;
    final index = _balloons.indexWhere((b) => b.id == id);
    if (index < 0) return;

    final balloon = _balloons.removeAt(index);
    _popped++;

    // Durduğu yer yeniden boşaldı.
    final cell = _cellOf.remove(balloon.id);
    if (cell != null) _freeCells.add(cell);

    // Üretilen bütün balonlar patlatıldı: erken bitirmenin ödülü, erken
    // bitirmektir (§24).
    if (_popped >= total) _closeAt = _elapsed + earlyFinishDelay;

    notifyListeners();
  }

  bool get _canSpawn =>
      _spawned < total && _balloons.length < maxActive && _freeCells.isNotEmpty;

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

  void _spawn({int? preferredColumn}) {
    final cell = _takeCell(preferredColumn);
    final column = cell % columns;
    final row = cell ~/ columns;

    // Hücrenin ortası; hücrelerin balon çevresinde bıraktığı boşluktan
    // biraz az kaydırılır, böylece sapma o boşluğu asla kapatamaz.
    final balloon = Balloon(
      id: _spawned,
      x: (column + 0.5) / columns + (_random.nextDouble() - 0.5) * 0.014,
      restY: (row + 0.5) / rows + (_random.nextDouble() - 0.5) * 0.014,
      // Paletten çekmek yerine palet üzerinde yürünür: arka arkaya beş
      // balon beş farklı renktir, üç tane mor değil.
      colourIndex: (_spawned + _colourOffset) % colourCount,
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
