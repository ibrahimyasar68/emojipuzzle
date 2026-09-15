import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/paint_colours.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../../../support/recording_sound_player.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';

const _referencePhone = Size(360, 640);

/// What a part is painted with when the child does not touch the palette.
final _initialPaint = PaletteChoice.initial.colour.toARGB32();

class _Harness {
  _Harness(this.game, this.player);

  final GameProvider game;
  final RecordingSoundPlayer player;
}

Future<_Harness> _pumpPuzzle(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final player = RecordingSoundPlayer();
  final audio = AudioService(player: player);
  addTearDown(audio.dispose);
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
    audio: audio,
  );
  addTearDown(game.dispose);
  await tester.runAsync(
    () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
  );

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
        ChangeNotifierProvider<GameProvider>.value(value: game),
      ],
      child: const MaterialApp(home: PuzzleScreen()),
    ),
  );
  await tester.pumpAndSettle();
  return _Harness(game, player);
}

/// Picks a tray piece up and holds it over the board, finger still down.
Future<TestGesture> _pickUp(WidgetTester tester, GameProvider game) async {
  final piece = game.pieces.first;
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(ValueKey('tray-piece-${piece.id}'))),
  );
  await gesture.moveBy(const Offset(0, -30)); // break the touch slop
  await tester.pump();
  await gesture.moveBy(const Offset(20, -120));
  await tester.pump();
  return gesture;
}

/// The real sequence the framework sends on the way out and back.
Future<void> _background(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.inactive,
    AppLifecycleState.hidden,
    AppLifecycleState.paused,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

Future<void> _foreground(WidgetTester tester) async {
  for (final state in [
    AppLifecycleState.hidden,
    AppLifecycleState.inactive,
    AppLifecycleState.resumed,
  ]) {
    tester.binding.handleAppLifecycleStateChanged(state);
    await tester.pump();
  }
}

/// The Android Back button, as the system sends it.
Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(
      const MethodCall('popRoute'),
    ),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Solves the whole puzzle with explicit pumps — no `pumpAndSettle`, since
/// the celebration never settles.
Future<void> _solveWithFingers(WidgetTester tester, GameProvider game) async {
  final boardRect = tester.getRect(find.byKey(const ValueKey('puzzle-board')));
  for (final piece in [...game.pieces]) {
    final cell = CoordinateMapper.cellSizeOf(game.grid, boardRect.size);
    final target = boardRect.topLeft +
        CoordinateMapper.pixelOf(piece.normalizedPosition, boardRect.size) +
        Offset(cell.width / 2, cell.height / 2);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-piece-${piece.id}'))),
    );
    await gesture.moveBy(const Offset(0, -30));
    await tester.pump();
    await gesture.moveTo(target);
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump(PuzzleConfig.snapSettleDuration);
    await tester.pump(const Duration(milliseconds: 20));
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('interruption (§28)', () {
    testWidgets('a held piece goes back to its slot', (tester) async {
      final game = (await _pumpPuzzle(tester)).game;
      final piece = game.pieces.first;

      final gesture = await _pickUp(tester, game);
      expect(game.stateOf(piece.id).status, PieceStatus.dragging);

      await _background(tester);

      expect(
        game.stateOf(piece.id).status,
        PieceStatus.inTray,
        reason: 'nothing is left stranded on the board',
      );
      expect(find.byKey(ValueKey('tray-piece-${piece.id}')), findsOneWidget);

      // The finger lifts somewhere the app never hears about.
      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('the interruption is not counted as a try (§19, §28)', (
      tester,
    ) async {
      final game = (await _pumpPuzzle(tester)).game;
      final piece = game.pieces.first;

      final gesture = await _pickUp(tester, game);
      await _background(tester);
      await gesture.up();
      await tester.pump();

      expect(
        game.stateOf(piece.id).failedAttempts,
        0,
        reason: 'being interrupted is not the same as missing',
      );
    });

    testWidgets('hints stop while away and start over on return (§21.2)', (
      tester,
    ) async {
      final harness = await _pumpPuzzle(tester);
      final game = harness.game;

      // Most of the way to the first hint, which arrives at eight seconds.
      await tester.pump(const Duration(seconds: 7));
      expect(harness.player.played, isEmpty);

      await _background(tester);

      // Long enough in the background to have climbed the whole ladder and
      // placed a piece by itself, if the clock were still running (§21).
      await tester.pump(const Duration(seconds: 40));
      expect(
        harness.player.played,
        isEmpty,
        reason: 'the clock is stopped, not running in the dark',
      );
      expect(
        game.placedCount,
        0,
        reason: 'nothing plays itself while nobody is watching',
      );

      await _foreground(tester);

      // The second left over from before is gone: coming back buys a whole
      // eight seconds, not one.
      await tester.pump(const Duration(seconds: 6));
      expect(
        harness.player.played,
        isEmpty,
        reason: 'seven seconds of credit would have fired this already',
      );

      await tester.pump(const Duration(seconds: 3));
      expect(
        harness.player.played,
        [Sfx.hint],
        reason: 'eight seconds after coming back, help is offered',
      );
    });

    testWidgets('progress is written on the way out (§25, §30)', (
      tester,
    ) async {
      final game = (await _pumpPuzzle(tester)).game;
      await _background(tester);
      await tester.runAsync(() => game.pendingWrite);

      expect(game.progress.lastPlayedPuzzleId, 'apple_01');
    });
  });

  group('Android Back (§30)', () {
    testWidgets('it goes straight home, with no question asked', (
      tester,
    ) async {
      final game = (await _pumpPuzzle(tester)).game;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioService>.value(value: game.audio),
            ChangeNotifierProvider<GameProvider>.value(value: game),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await tester.pumpAndSettle();
      expect(find.byType(PuzzleScreen), findsOneWidget);

      await _pressBack(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(PuzzleScreen), findsNothing);
      expect(
        find.byType(AlertDialog),
        findsNothing,
        reason: 'a child cannot read a dialog, so there is never one',
      );
    });

    testWidgets('leaving during the colouring keeps the paint (§30)', (
      tester,
    ) async {
      final harness = await _pumpPuzzle(tester);
      final game = harness.game;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioService>.value(value: game.audio),
            ChangeNotifierProvider<GameProvider>.value(value: game),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await tester.pumpAndSettle();

      await _solveWithFingers(tester, game);
      await tester.pump(PuzzleConfig.celebrationDuration);
      await tester.pump();
      await tester.pump(PuzzleConfig.balloonGameDuration);
      await tester.pump();
      await tester.pump(PuzzleConfig.stickerRewardDuration);
      await tester.pump();
      expect(find.byKey(const ValueKey('colouring-overlay')), findsOneWidget);

      // Paint, and press Back before the page has moved on by itself.
      final card = tester.getRect(find.byKey(const ValueKey('colouring-card')));
      await tester
          .tapAt(card.topLeft + Offset(card.width / 2, card.height * 0.625));
      await tester.pump();
      expect(game.colouring.colourOf('body'), _initialPaint);
      await _pressBack(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        game.colouring.colourOf('body'),
        _initialPaint,
        reason: 'Back takes nothing away (§30)',
      );
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(game.puzzle.id, isNot('apple_01'),
          reason: 'not left on a solved board');
      expect(game.stage, 1, reason: 'the stage moved on (K-15)');
      expect(tester.takeException(), isNull);
    });

    testWidgets('leaving mid-celebration keeps the sticker (§30)', (
      tester,
    ) async {
      final harness = await _pumpPuzzle(tester);
      final game = harness.game;

      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<AudioService>.value(value: game.audio),
            ChangeNotifierProvider<GameProvider>.value(value: game),
          ],
          child: const MaterialApp(home: HomeScreen()),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('home-play')));
      await tester.pumpAndSettle();

      await _solveWithFingers(tester, game);
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byKey(const ValueKey('celebration-overlay')), findsOneWidget);

      // Back, right in the middle of the reward.
      await _pressBack(tester);

      expect(find.byType(HomeScreen), findsOneWidget);
      expect(
        game.isPuzzleCompleted('apple_01'),
        isTrue,
        reason: 'Back is not a penalty: the sticker stays earned (§30)',
      );
      expect(game.progress.completedPuzzleIds, contains('apple_01'));

      // And the game is left somewhere playable, not on a solved board.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 50)),
      );
      await tester.pumpAndSettle();
      expect(game.puzzle.id, isNot('apple_01'),
          reason: 'not left on a solved board');
      expect(game.stage, 1, reason: 'the stage moved on (K-15)');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a held piece is put down first (§28, §30)', (tester) async {
      final game = (await _pumpPuzzle(tester)).game;
      final piece = game.pieces.first;
      final gesture = await _pickUp(tester, game);

      await _pressBack(tester);

      expect(game.stateOf(piece.id).status, PieceStatus.inTray);
      expect(game.stateOf(piece.id).failedAttempts, 0);

      await gesture.up();
      await tester.pump();
      expect(tester.takeException(), isNull);
    });
  });
}
