import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_session_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

final _puzzle = PuzzleCatalog.v1.byId('apple_01');

Future<GameProvider> _started() async {
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  await game.startPuzzle(_puzzle);
  return game;
}

/// One complete miss: pick up, drop in the wrong place.
void _miss(GameProvider game, int pieceId) {
  game
    ..beginDrag(pieceId)
    ..dropFailed(pieceId);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a piece on its way into the slot is snapping', () async {
    final game = await _started();
    addTearDown(game.dispose);

    game
      ..beginDrag(0)
      ..beginSnap(0);

    expect(game.stateOf(0).status, PieceStatus.snapping);
    expect(game.sessionState, PuzzleSessionState.snapping);
    // It belongs to neither the tray nor the board while it flies.
    expect(game.trayPieces.map((p) => p.id), isNot(contains(0)));
    expect(game.placedPieces, isEmpty);
  });

  test('landing places it and wipes its counter (§19)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    _miss(game, 0);
    _miss(game, 0);
    expect(game.stateOf(0).failedAttempts, 2);

    game
      ..beginDrag(0)
      ..beginSnap(0)
      ..markPlaced(0);

    expect(game.stateOf(0).status, PieceStatus.placed);
    expect(game.stateOf(0).failedAttempts, 0);
  });

  group('a miss', () {
    test('sends the piece home and counts, quietly (§20)', () async {
      final game = await _started();
      addTearDown(game.dispose);

      final slot = game.stateOf(0).traySlotIndex;
      _miss(game, 0);

      expect(game.stateOf(0).status, PieceStatus.inTray);
      expect(game.stateOf(0).traySlotIndex, slot, reason: 'same slot (§16.2)');
      expect(game.stateOf(0).failedAttempts, 1);
      expect(game.sessionState, PuzzleSessionState.idle);
      expect(game.placedCount, 0, reason: 'nothing is lost by missing');
    });

    test('counts per piece and never spills over (§19)', () async {
      final game = await _started();
      addTearDown(game.dispose);

      _miss(game, 0);
      _miss(game, 0);
      _miss(game, 0);

      expect(game.stateOf(0).failedAttempts, 3, reason: 'assist territory');
      expect(game.stateOf(1).failedAttempts, 0);
      expect(game.stateOf(2).failedAttempts, 0);
      expect(game.stateOf(3).failedAttempts, 0);
    });

    test('cannot touch a piece that is already placed', () async {
      final game = await _started();
      addTearDown(game.dispose);

      game.markPlaced(0);
      game.dropFailed(0);

      expect(game.stateOf(0).status, PieceStatus.placed);
      expect(game.stateOf(0).failedAttempts, 0);
    });
  });

  test('restarting clears every counter (§19)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    _miss(game, 1);
    _miss(game, 1);
    game.restart();

    expect(game.stateOf(1).failedAttempts, 0);
    expect(game.stateOf(1).status, PieceStatus.inTray);
  });

  test('a drop costs at most two notifications', () async {
    final game = await _started();
    addTearDown(game.dispose);

    game.beginDrag(0);
    var notifications = 0;
    game.addListener(() => notifications++);

    game
      ..beginSnap(0)
      ..markPlaced(0);

    expect(notifications, 2);
  });
}
