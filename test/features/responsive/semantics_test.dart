import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/album/screens/album_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/piece_status.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

GameProvider _provider({AudioService? audio}) => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
      audio: audio,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the home buttons say what they do (§31)', (tester) async {
    final handle = tester.ensureSemantics();
    final audio = AudioService();
    addTearDown(audio.dispose);
    final game = _provider(audio: audio);
    addTearDown(game.dispose);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<AudioService>.value(value: audio),
          ChangeNotifierProvider<GameProvider>.value(value: game),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
    await tester.pump();

    for (final label in [
      'Oyna',
      'Çıkartma albümü',
      'Sesi kapat',
      'Ebeveynler için bilgi',
    ]) {
      expect(find.bySemanticsLabel(label), findsOneWidget, reason: label);
    }
    handle.dispose();
  });

  testWidgets('a sticker says which picture it is (§31)', (tester) async {
    final handle = tester.ensureSemantics();
    final game = _provider();
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
    );
    for (final piece in [...game.pieces]) {
      game.markPlaced(piece.id);
    }

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: game,
        child: const MaterialApp(home: AlbumScreen()),
      ),
    );
    await tester.pump();

    expect(find.bySemanticsLabel('Elma, tamamlandı'), findsOneWidget);
    expect(find.bySemanticsLabel('Kedi, henüz yapılmadı'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a tray piece is announced as one (§31)', (tester) async {
    final handle = tester.ensureSemantics();
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = _provider();
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: game,
        child: const MaterialApp(home: PuzzleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Puzzle parçası 1'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('turning semantics on does not disturb the game (§31)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    final game = _provider();
    addTearDown(game.dispose);
    await tester.runAsync(
      () => game.startPuzzle(PuzzleCatalog.v1.byId('apple_01')),
    );

    await tester.pumpWidget(
      ChangeNotifierProvider<GameProvider>.value(
        value: game,
        child: const MaterialApp(home: PuzzleScreen()),
      ),
    );
    await tester.pumpAndSettle();

    // A screen reader is switched on in the middle of a game.
    final handle = tester.ensureSemantics();
    await tester.pumpAndSettle();

    expect(game.puzzle.id, 'apple_01');
    expect(game.placedCount, 0);
    expect(game.pieces, hasLength(4));

    // And the game still plays: a piece can still be picked up and put down.
    final piece = game.pieces.first;
    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(ValueKey('tray-piece-${piece.id}'))),
    );
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    expect(game.stateOf(piece.id).status, PieceStatus.dragging);

    await gesture.up();
    await tester.pump();
    expect(tester.takeException(), isNull);
    handle.dispose();
  });
}
