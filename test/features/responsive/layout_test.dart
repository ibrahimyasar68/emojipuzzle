import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/album/screens/album_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/about_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// The screens §40 asks for, plus the landscape ones it does not mention.
const _screens = <String, Size>{
  'small phone': Size(320, 568),
  'reference phone': Size(360, 640),
  'normal phone': Size(414, 896),
  'tablet': Size(768, 1024),
  'big tablet': Size(1024, 1366),
  'phone, turned sideways': Size(640, 360),
  'tablet, turned sideways': Size(1024, 768),
};

/// One puzzle per level: four, six and nine pieces (§4).
const _puzzles = ['apple_01', 'banana_01', 'lion_01'];

Future<GameProvider> _pumpPuzzle(
  WidgetTester tester,
  Size screen,
  String puzzleId, {
  double textScale = 1,
}) async {
  tester.view.physicalSize = screen;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  addTearDown(game.dispose);
  await tester.runAsync(
    () => game.startPuzzle(PuzzleCatalog.v1.byId(puzzleId)),
  );

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
          child: const PuzzleScreen(),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return game;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('the board (§6.1, §40)', () {
    for (final screen in _screens.entries) {
      for (final puzzleId in _puzzles) {
        testWidgets('${screen.key}, $puzzleId', (tester) async {
          await _pumpPuzzle(tester, screen.value, puzzleId);
          final board = tester.getRect(
            find.byKey(const ValueKey('puzzle-board')),
          );

          expect(board.width, board.height, reason: 'the board is square');
          expect(
            board.width,
            lessThanOrEqualTo(PuzzleConfig.maxBoardSize),
            reason: 'a tablet does not get a two-foot puzzle',
          );
          expect(board.width, greaterThan(0));

          // Centred across the width, whatever is left over.
          final left = board.left;
          final right = screen.value.width - board.right;
          expect(left, closeTo(right, 1), reason: 'centred');

          expect(
            board.right,
            lessThanOrEqualTo(screen.value.width + 0.01),
            reason: 'nothing hangs off the side',
          );
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('every piece stays big enough to hit (§2, §16.1)', () {
    for (final screen in _screens.entries) {
      for (final puzzleId in _puzzles) {
        testWidgets('${screen.key}, $puzzleId', (tester) async {
          final game = await _pumpPuzzle(tester, screen.value, puzzleId);

          for (final piece in game.pieces) {
            final size = tester.getSize(
              find.byKey(ValueKey('tray-piece-${piece.id}')),
            );
            expect(
              size.width,
              greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
              reason: '${screen.key} / $puzzleId / piece ${piece.id}',
            );
            expect(
              size.height,
              greaterThanOrEqualTo(PuzzleConfig.minTouchTargetSize),
              reason: '${screen.key} / $puzzleId / piece ${piece.id}',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('the tray stays a shelf (§16.1, §40)', () {
    for (final screen in _screens.entries) {
      for (final puzzleId in _puzzles) {
        testWidgets('${screen.key}, $puzzleId', (tester) async {
          final game = await _pumpPuzzle(tester, screen.value, puzzleId);

          final rects = [
            for (final piece in game.pieces)
              tester.getRect(find.byKey(ValueKey('tray-piece-${piece.id}'))),
          ];

          // How many distinct rows and columns the pieces actually occupy.
          final rows = rects.map((r) => r.top.round()).toSet().length;
          final columns = rects.map((r) => r.left.round()).toSet().length;
          expect(
            columns,
            greaterThanOrEqualTo(rows),
            reason: 'a tray is looked along, not down — '
                '${screen.key} / $puzzleId came out ${rows}x$columns',
          );

          // And it stays on the screen.
          for (final rect in rects) {
            expect(rect.left, greaterThanOrEqualTo(-0.01));
            expect(
              rect.right,
              lessThanOrEqualTo(screen.value.width + 0.01),
              reason: '${screen.key} / $puzzleId',
            );
            expect(
              rect.bottom,
              lessThanOrEqualTo(screen.value.height + 0.01),
              reason: '${screen.key} / $puzzleId',
            );
          }
          expect(tester.takeException(), isNull);
        });
      }
    }

    testWidgets('the tray keeps a margin around the outside when it can', (
      tester,
    ) async {
      // Screens where the width is what limits the pieces, so the tray
      // really does reach both edges. On a screen limited by height the
      // content is centred with slack to spare and proves nothing.
      for (final screen in [const Size(414, 896), const Size(1024, 1366)]) {
        final game = await _pumpPuzzle(tester, screen, 'lion_01');
        final rects = [
          for (final piece in game.pieces)
            tester.getRect(find.byKey(ValueKey('tray-piece-${piece.id}'))),
        ];

        final leftmost =
            rects.map((r) => r.left).reduce((a, b) => a < b ? a : b);
        final rightmost =
            rects.map((r) => r.right).reduce((a, b) => a > b ? a : b);

        // A jigsaw tab needs somewhere to stick out; flush against the
        // screen it has nowhere to go and is simply cut off.
        expect(
          leftmost,
          greaterThanOrEqualTo(PuzzleConfig.trayItemSpacing - 0.01),
          reason: '$screen',
        );
        expect(
          rightmost,
          lessThanOrEqualTo(screen.width - PuzzleConfig.trayItemSpacing + 0.01),
          reason: '$screen',
        );
      }
    });

    testWidgets('nine pieces still land in a 3x3 tray on a phone (§41)', (
      tester,
    ) async {
      final game = await _pumpPuzzle(
        tester,
        const Size(360, 640),
        'lion_01',
      );
      final rects = [
        for (final piece in game.pieces)
          tester.getRect(find.byKey(ValueKey('tray-piece-${piece.id}'))),
      ];

      expect(rects.map((r) => r.top.round()).toSet(), hasLength(3));
      expect(rects.map((r) => r.left.round()).toSet(), hasLength(3));
    });
  });

  group('system font scaling does not break a screen (§31)', () {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('the puzzle at ${scale}x', (tester) async {
        await _pumpPuzzle(
          tester,
          const Size(320, 568),
          'lion_01',
          textScale: scale,
        );
        expect(tester.takeException(), isNull);
      });

      testWidgets('home, album and about at ${scale}x', (tester) async {
        tester.view.physicalSize = const Size(320, 568);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.reset);

        final audio = AudioService();
        addTearDown(audio.dispose);
        final game = GameProvider(
          generator: PuzzleGenerator(random: Random(1)),
          shuffler: TrayShuffler(random: Random(1)),
          audio: audio,
        );
        addTearDown(game.dispose);

        for (final screen in <Widget>[
          const HomeScreen(),
          const AlbumScreen(),
          const AboutScreen(),
        ]) {
          await tester.pumpWidget(
            MultiProvider(
              providers: [
                ChangeNotifierProvider<AudioService>.value(value: audio),
                ChangeNotifierProvider<GameProvider>.value(value: game),
              ],
              child: MaterialApp(
                home: MediaQuery(
                  data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                  child: screen,
                ),
              ),
            ),
          );
          await tester.pump(const Duration(milliseconds: 100));
          expect(
            tester.takeException(),
            isNull,
            reason: '${screen.runtimeType} at ${scale}x',
          );
        }
      });
    }
  });

  group('safe areas (§40)', () {
    testWidgets('every screen keeps out of the system insets', (tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      final audio = AudioService();
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

      for (final screen in <Widget>[
        const HomeScreen(),
        const AlbumScreen(),
        const AboutScreen(),
        const PuzzleScreen(),
      ]) {
        await tester.pumpWidget(
          MultiProvider(
            providers: [
              ChangeNotifierProvider<AudioService>.value(value: audio),
              ChangeNotifierProvider<GameProvider>.value(value: game),
            ],
            child: MaterialApp(home: screen),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(SafeArea),
          findsWidgets,
          reason: '${screen.runtimeType} must sit inside a SafeArea',
        );
      }
    });
  });
}
