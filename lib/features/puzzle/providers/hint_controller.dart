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
  });

  /// Silence before the first offer of help.
  final Duration firstDelay;

  /// Gap between one stage and the next.
  final Duration stageInterval;

  /// How often the clock is looked at. Small enough to be punctual, large
  /// enough to cost nothing.
  final Duration tickInterval;

  /// Called when the last stage is reached: the game places the piece
  /// itself (§21).
  VoidCallback? onAutoPlace;

  Timer? _timer;
  Duration _idleFor = Duration.zero;
  HintStage _stage = HintStage.none;
  bool _paused = false;

  HintStage get stage => _stage;
  Duration get idleFor => _idleFor;
  bool get isRunning => _timer != null;
  bool get isPaused => _paused;

  /// Starts watching. Safe to call twice.
  void start() {
    if (_timer != null) return;
    _paused = false;
    _timer = Timer.periodic(tickInterval, (_) => advance(tickInterval));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
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

  /// Any touch at all means the child is busy (§21.2).
  void registerInteraction() {
    if (_idleFor == Duration.zero && _stage == HintStage.none) return;
    _reset(notify: true);
  }

  /// Moves the clock on. The timer calls this; tests call it directly, so
  /// the ladder can be checked without waiting 32 real seconds.
  @visibleForTesting
  void advance(Duration by) {
    if (_paused) return;
    _idleFor += by;

    final next = stageFor(_idleFor);
    if (next == _stage) return;
    _stage = next;

    if (next == HintStage.autoPlace) {
      onAutoPlace?.call();
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
