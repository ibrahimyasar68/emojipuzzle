import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/hint_stage.dart';

/// Çocuğun ne kadar süredir kıpırdamadığını sayar ve ne kadar yardım
/// önerileceğini söyler (§21).
///
/// Burada yalnızca zamanlama yaşar. Hangi parçanın gösterileceği ayrı bir
/// kuraldır (`HintTarget`) ve bir ipucunun neye benzediği widget'lara
/// aittir — böylece merdivenin kendisi ekransız, saniye saniye test
/// edilebilir.
class HintController extends ChangeNotifier {
  HintController({
    this.firstDelay = PuzzleConfig.hintFirstDelay,
    this.stageInterval = PuzzleConfig.hintStageInterval,
    this.tickInterval = PuzzleConfig.hintTickInterval,
    this.maxAutoPlacesInARow = PuzzleConfig.hintMaxAutoPlacesInARow,
  });

  /// İlk yardım teklifinden önceki sessizlik.
  final Duration firstDelay;

  /// Bir aşama ile diğeri arasındaki aralık.
  final Duration stageInterval;

  /// Saate ne sıklıkta bakıldığı. Dakik olacak kadar küçük, hiçbir şeye mal
  /// olmayacak kadar büyük.
  final Duration tickInterval;

  /// Oyunun, önermeyi bırakmadan önce arka arkaya kaç parçayı kendi
  /// yerleştireceği.
  ///
  /// Merdiven takılan bir çocuk için vardır, boş bir oda için değil. Kendi
  /// haline bırakıldığında puzzle'ı, sonra bir sonrakini, sonra ondan
  /// sonrakini bitiriyordu — kimsenin oturmadığı bir masada kendi kendine
  /// oynayan bir oyun. Arka arkaya bu sayıya ulaşınca susar ve dokunulmayı
  /// bekler.
  final int maxAutoPlacesInARow;

  /// Son aşamaya gelindiğinde çağrılır: oyun parçayı kendisi yerleştirir
  /// (§21).
  VoidCallback? onAutoPlace;

  Timer? _timer;
  Duration _idleFor = Duration.zero;
  HintStage _stage = HintStage.none;
  bool _paused = false;
  bool _dormant = false;
  int _autoPlacesInARow = 0;

  HintStage get stage => _stage;
  Duration get idleFor => _idleFor;
  bool get isRunning => _timer != null;
  bool get isPaused => _paused;

  /// Oyun, orada kimsenin olduğuna dair bir işaret olmadan
  /// [maxAutoPlacesInARow] parça yerleştirdiğinde true olur. Yalnızca bir
  /// dokunuş onu geri getirir.
  bool get isDormant => _dormant;

  /// İzlemeye başlar. İki kez çağrılması güvenlidir.
  ///
  /// Uyku modundayken hiçbir şey yapmaz: arka plandan dönmek ya da sonraki
  /// puzzle'a geçmek, orada bir çocuk olduğunun kanıtı değildir. Kanıt
  /// yalnızca [registerInteraction]'dır.
  void start() {
    if (_timer != null || _dormant) return;
    _paused = false;
    _timer = Timer.periodic(tickInterval, (_) => advance(tickInterval));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _dormant = false;
    _autoPlacesInARow = 0;
    _reset(notify: false);
  }

  /// §28 — uygulama arka plana gitti: saat olduğu yerde durur.
  void pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// §21.2 — dönüş bir devam değil, temiz bir başlangıçtır: çocuk uzakta
  /// kalmıştır ve board'a bakmak için kendi süresini hak eder.
  void resume() {
    _paused = false;
    _reset(notify: true);
    start();
  }

  /// Herhangi bir dokunuş çocuğun meşgul olduğu anlamına gelir (§21.2) —
  /// ve oyun odanın dolu olduğundan ümidi kestiyse, dolu olduğu anlamına.
  void registerInteraction() {
    _autoPlacesInARow = 0;
    if (_dormant) {
      _dormant = false;
      _reset(notify: true);
      start();
      return;
    }
    if (_idleFor == Duration.zero && _stage == HintStage.none) return;
    _reset(notify: true);
  }

  /// Saati ilerletir. Zamanlayıcı bunu çağırır; testler doğrudan çağırır,
  /// böylece merdiven gerçek 32 saniye beklemeden denetlenebilir.
  @visibleForTesting
  void advance(Duration by) {
    if (_paused || _dormant) return;
    _idleFor += by;

    final next = stageFor(_idleFor);
    if (next == _stage) return;
    _stage = next;

    if (next == HintStage.autoPlace) {
      onAutoPlace?.call();
      _autoPlacesInARow++;
      if (_autoPlacesInARow >= maxAutoPlacesInARow) {
        // İki tam merdiven boyunca ekrana kimse dokunmadı. Oyun kendi
        // kendine oynamayı bırakır ve bekler (§21).
        _dormant = true;
        _timer?.cancel();
        _timer = null;
      }
      // Yerleştirmenin kendisi bu ipucunun sonudur: sonraki parça tam sekiz
      // saniyelik sessizliği alır (§21.2).
      _reset(notify: true);
      return;
    }
    notifyListeners();
  }

  /// Belirli bir hareketsizlik süresine karşılık gelen aşama (§21).
  HintStage stageFor(Duration idle) {
    if (idle < firstDelay) return HintStage.none;
    final steps = (idle - firstDelay).inMilliseconds ~/
            math.max(1, stageInterval.inMilliseconds) +
        1;
    return HintStage.values[math.min(steps, HintStage.values.length - 1)];
  }

  void _reset({required bool notify}) {
    final changed = _stage != HintStage.none || _idleFor != Duration.zero;
    _idleFor = Duration.zero;
    _stage = HintStage.none;
    if (notify && changed) notifyListeners();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _timer = null;
    super.dispose();
  }
}
