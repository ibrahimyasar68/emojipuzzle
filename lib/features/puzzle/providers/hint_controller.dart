import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../core/constants/puzzle_config.dart';
import '../models/hint_stage.dart';

/// Counts how long the child has been still, and says how much help to
/// offer (§21).
///
/// Only the timing lives here. Which piece to point at is a separate rule
/// (`HintTarget`), and what a hint looks like belongs to the widgets — so
/// the ladder itself can be tested second by second without a screen.
class HintController extends ChangeNotifier {
  HintController({
    this.firstDelay = PuzzleConfig.hintFirstDelay,
    this.stageInterval = PuzzleConfig.hintStageInterval,
    this.tickInterval = PuzzleConfig.hintTickInterval,
    this.maxAutoPlacesInARow = PuzzleConfig.hintMaxAutoPlacesInARow,
  });

  /// Silence before the first offer of help.
  final Duration firstDelay;

  /// Gap between one stage and the next.
  final Duration stageInterval;

  /// How often the clock is looked at. Small enough to be punctual, large
  /// enough to cost nothing.
  final Duration tickInterval;

  /// How many pieces the game will place by itself, one after another,
  /// before it stops offering.
  ///
  /// The ladder exists for a child who is stuck, not for an empty room. Left
  /// alone, it used to finish the puzzle, then the next one, and the one
  /// after that — a game playing itself on a table nobody is sitting at.
  /// After this many in a row it goes quiet and waits to be touched.
  final int maxAutoPlacesInARow;

  /// Called when the last stage is reached: the game places the piece
  /// itself (§21).
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

  /// True once the game has placed [maxAutoPlacesInARow] pieces with no
  /// sign of anybody there. Only a touch brings it back.
  bool get isDormant => _dormant;

  /// Starts watching. Safe to call twice.
  ///
  /// Does nothing while dormant: coming back from the background, or moving
  /// on to the next puzzle, is not evidence that a child is there. Only
  /// [registerInteraction] is.
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

  /// §28 — the app went to the background: the clock stops where it is.
  void pause() {
    if (_paused) return;
    _paused = true;
    _timer?.cancel();
    _timer = null;
  }

  /// §21.2 — coming back is a fresh start, not a continuation: the child
  /// has been away and should get their own time to look at the board.
  void resume() {
    _paused = false;
    _reset(notify: true);
    start();
  }

  /// Any touch at all means the child is busy (§21.2) — and, if the game
  /// had given up on the room being occupied, that it is occupied.
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

  /// Moves the clock on. The timer calls this; tests call it directly, so
  /// the ladder can be checked without waiting 32 real seconds.
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
        // Nobody has touched the screen through two whole ladders. The game
        // stops playing itself and waits (§21).
        _dormant = true;
        _timer?.cancel();
        _timer = null;
      }
      // Placing it is itself the end of this hint: the next piece gets the
      // full eight seconds of quiet (§21.2).
      _reset(notify: true);
      return;
    }
    notifyListeners();
  }

  /// The stage that belongs to a stretch of stillness (§21).
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
