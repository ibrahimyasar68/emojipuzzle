import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/app_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_session_state.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter_test/flutter_test.dart';

/// A real catalogue entry: the first 2×2 puzzle a child ever sees.
final _puzzle = PuzzleCatalog.v1.byId('apple_01');

GameProvider _provider() => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );

void main() {
  // The placeholder picture is rasterised through dart:ui.
  TestWidgetsFlutterBinding.ensureInitialized();

  group('starting a puzzle', () {
    test('ends ready, with every piece in its own tray slot', () async {
      final game = _provider();
      addTearDown(game.dispose);

      expect(game.appState, AppState.loading);
      await game.startPuzzle(_puzzle);

      expect(game.appState, AppState.ready);
      expect(game.image, isNotNull);
      expect(game.pieces, hasLength(4));
      expect(game.sessionState, PuzzleSessionState.idle);

      final slots =
          game.pieces.map((p) => game.stateOf(p.id).traySlotIndex).toList();
      expect(slots.toSet(), hasLength(4), reason: 'slots must be unique');
      for (final piece in game.pieces) {
        expect(game.stateOf(piece.id).status, PieceStatus.inTray);
      }
    });

    test('tray pieces come back in slot order (§16.2)', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      final slots =
          game.trayPieces.map((p) => game.stateOf(p.id).traySlotIndex).toList();
      expect(slots, [...slots]..sort());
    });

    test('an unknown piece id is an error, not a null', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      expect(() => game.stateOf(99), throwsArgumentError);
    });

    test('reading the grid before starting throws', () {
      final game = _provider();
      addTearDown(game.dispose);

      expect(() => game.grid, throwsStateError);
    });
  });

  group('placing pieces', () {
    test('a placed piece leaves the tray and lands on the board', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      game.markPlaced(0);

      expect(game.stateOf(0).status, PieceStatus.placed);
      expect(game.placedCount, 1);
      expect(game.placedPieces.single.id, 0);
      expect(game.trayPieces.map((p) => p.id), isNot(contains(0)));
      expect(game.isComplete, isFalse);
      expect(game.sessionState, PuzzleSessionState.idle);
    });

    test('placing the last piece completes the session', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      for (final piece in [...game.pieces]) {
        game.markPlaced(piece.id);
      }

      expect(game.isComplete, isTrue);
      expect(game.trayPieces, isEmpty);
      expect(game.sessionState, PuzzleSessionState.completed);
    });

    test('placing the same piece twice changes nothing', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      game.markPlaced(0);
      var notifications = 0;
      game.addListener(() => notifications++);
      game.markPlaced(0);

      expect(notifications, 0);
      expect(game.placedCount, 1);
    });

    test('listeners hear about a placement', () async {
      final game = _provider();
      addTearDown(game.dispose);
      await game.startPuzzle(_puzzle);

      var notifications = 0;
      game.addListener(() => notifications++);
      game.markPlaced(1);

      expect(notifications, 1);
    });
  });

  test('restart sends every piece back to its own slot', () async {
    final game = _provider();
    addTearDown(game.dispose);
    await game.startPuzzle(_puzzle);

    final slotsBefore = {
      for (final piece in game.pieces)
        piece.id: game.stateOf(piece.id).traySlotIndex,
    };
    game.markPlaced(0);
    game.markPlaced(1);
    game.restart();

    expect(game.placedCount, 0);
    expect(game.trayPieces, hasLength(4));
    expect(game.sessionState, PuzzleSessionState.idle);
    for (final piece in game.pieces) {
      expect(game.stateOf(piece.id).traySlotIndex, slotsBefore[piece.id]);
    }
  });
}
