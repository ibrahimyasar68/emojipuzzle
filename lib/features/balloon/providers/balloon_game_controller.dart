import 'dart:async';
import 'dart:math' show Random;

import 'package:flutter/foundation.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/balloon.dart';

/// The rules of the balloon mini game (§24): how many balloons there are,
/// when they arrive, and when the game is over.
///
/// It holds no pixels and no widgets, so "twelve balloons, eight at a
/// time, fifteen seconds" can be checked second by second in a unit test.
/// The clock is a plain timer that can be driven by hand through
/// [advance] — the same shape as `HintController` (§21).
///
/// There is no failure path anywhere in here. Balloons left in the air
/// when the clock runs out are not counted, not reported, and not
/// mentioned: the game simply ends (§20, §24).
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

  /// How many balloons the whole game makes.
  final int total;

  /// The ceiling on balloons in the air at one time.
  final int maxActive;

  /// How many are already up when the game opens.
  final int initialSpawn;

  /// Gap between one balloon and the next, when there is room.
  final Duration spawnInterval;

  /// The game is over at this point however it is going.
  final Duration timeLimit;

  /// The pause between the last balloon popping and the game closing, so
  /// the child sees the pop they earned.
  final Duration earlyFinishDelay;

  /// How often the clock is looked at.
  final Duration tickInterval;

  /// Size of the balloon palette the widget paints from.
  final int colourCount;

  /// The play area is divided into cells and no two balloons share one, so
  /// a balloon is never half hidden behind another. Overlapping balloons
  /// would quietly eat into the 72 px a child has to hit (§2).
  ///
  /// Three columns and five rows is fifteen places for at most eight
  /// balloons, which leaves the arrangement looking scattered rather than
  /// like a grid.
  static const int columns = 3;
  static const int rows = 4;

  final Random _random;

  /// Cells with nobody in them, in the order they will be used.
  final List<int> _freeCells = [];

  /// Which cell each balloon took, so popping gives it back.
  final Map<int, int> _cellOf = {};

  /// Where the palette starts, so one game does not always open orange.
  late final int _colourOffset = _random.nextInt(colourCount);

  /// Called once when the game is over, either way it ends.
  VoidCallback? onFinished;

  Timer? _timer;
  final List<Balloon> _balloons = [];
  int _spawned = 0;
  int _popped = 0;
  Duration _elapsed = Duration.zero;
  Duration _sinceSpawn = Duration.zero;
  Duration? _closeAt;
  bool _finished = false;

  /// The balloons in the air, in the order they arrived.
  List<Balloon> get balloons => List.unmodifiable(_balloons);

  /// How many have been made so far, popped ones included.
  int get spawnedCount => _spawned;

  /// How many the child has popped.
  int get poppedCount => _popped;

  Duration get elapsed => _elapsed;
  bool get isRunning => _timer != null;
  bool get isFinished => _finished;

  /// Opens the game: the first balloons are already in the air.
  void start() {
    if (_timer != null || _finished) return;
    _refillFreeCells();
    // The balloons that open the game are the only ones ever in the air at
    // the same time while rising, so they are given a column each.
    final columnOrder = List<int>.generate(columns, (i) => i)..shuffle(_random);
    for (var i = 0; i < initialSpawn && _canSpawn; i++) {
      _spawn(preferredColumn: columnOrder[i % columns]);
    }
    _timer = Timer.periodic(tickInterval, (_) => advance(tickInterval));
    notifyListeners();
  }

  /// Moves the clock on. The timer calls this every tick; tests call it
  /// directly so fifteen seconds take no time at all.
  @visibleForTesting
  void advance(Duration by) {
    if (_finished) return;
    _elapsed += by;

    // An early finish is already booked: nothing new arrives, we are only
    // waiting for the last pop to be seen.
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
      // The interval is spent before the room for it is checked, on
      // purpose: a screen that stays full does not bank up credit and
      // release a burst of balloons the moment one pops.
      if (!_canSpawn) break;
      _spawn();
      spawned = true;
    }

    if (spawned) notifyListeners();
  }

  /// The child touched a balloon. Unknown ids are ignored: a second tap on
  /// a balloon that has already gone is not an error, it is a child's
  /// finger (§20).
  void pop(int id) {
    if (_finished) return;
    final index = _balloons.indexWhere((b) => b.id == id);
    if (index < 0) return;

    final balloon = _balloons.removeAt(index);
    _popped++;

    // The place it was standing in is free again.
    final cell = _cellOf.remove(balloon.id);
    if (cell != null) _freeCells.add(cell);

    // Every balloon made and every one of them popped: the reward for
    // finishing early is finishing early (§24).
    if (_popped >= total) _closeAt = _elapsed + earlyFinishDelay;

    notifyListeners();
  }

  bool get _canSpawn =>
      _spawned < total && _balloons.length < maxActive && _freeCells.isNotEmpty;

  /// A free cell, in the asked-for column when one is free there.
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

    // The middle of the cell, nudged by a little less than the gap the
    // cells leave around a balloon, so the jitter can never close it.
    final balloon = Balloon(
      id: _spawned,
      x: (column + 0.5) / columns + (_random.nextDouble() - 0.5) * 0.014,
      restY: (row + 0.5) / rows + (_random.nextDouble() - 0.5) * 0.014,
      // Walking the palette instead of drawing from it: five balloons in a
      // row are five different colours, never three purples.
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
