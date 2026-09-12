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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('picking a piece up takes it out of the tray', () async {
    final game = await _started();
    addTearDown(game.dispose);

    game.beginDrag(0);

    expect(game.stateOf(0).status, PieceStatus.dragging);
    expect(game.sessionState, PuzzleSessionState.dragging);
    expect(game.trayPieces.map((p) => p.id), isNot(contains(0)));
    expect(game.placedPieces, isEmpty);
  });

  test('dropping sends it back to its own slot (§16.2)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    final slot = game.stateOf(0).traySlotIndex;
    game.beginDrag(0);
    game.returnToTray(0);

    expect(game.stateOf(0).status, PieceStatus.inTray);
    expect(game.stateOf(0).traySlotIndex, slot);
    expect(game.sessionState, PuzzleSessionState.idle);
    expect(game.trayPieces.map((p) => p.id), contains(0));
  });

  test('a drop is not a failed attempt (§28)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    game.beginDrag(0);
    game.returnToTray(0);

    expect(game.stateOf(0).failedAttempts, 0);
  });

  test('a placed piece cannot be picked up again (§10)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    game.markPlaced(0);
    game.beginDrag(0);

    expect(game.stateOf(0).status, PieceStatus.placed);
    expect(game.sessionState, isNot(PuzzleSessionState.dragging));
  });

  test('a whole drag costs exactly two notifications (§17)', () async {
    final game = await _started();
    addTearDown(game.dispose);

    var notifications = 0;
    game.addListener(() => notifications++);

    game.beginDrag(1);
    game.returnToTray(1);

    expect(notifications, 2, reason: 'one to lift, one to drop');
  });

  test('returning a piece that is not being dragged does nothing', () async {
    final game = await _started();
    addTearDown(game.dispose);

    var notifications = 0;
    game.addListener(() => notifications++);
    game.returnToTray(2);

    expect(notifications, 0);
    expect(game.stateOf(2).status, PieceStatus.inTray);
  });
}
