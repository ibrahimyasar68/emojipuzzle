import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/features/album/screens/album_screen.dart';
import 'package:emoji_puzzle_kids/features/album/widgets/sticker_tile.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/puzzle_definition.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

GameProvider _provider() => GameProvider(
      generator: PuzzleGenerator(random: Random(1)),
      shuffler: TrayShuffler(random: Random(1)),
    );

Future<void> _finish(GameProvider game, String puzzleId) async {
  await game.startPuzzle(PuzzleCatalog.v1.byId(puzzleId));
  for (final piece in [...game.pieces]) {
    game.markPlaced(piece.id);
  }
}

Future<List<PuzzleDefinition>> _pumpAlbum(
  WidgetTester tester,
  GameProvider game,
) async {
  final played = <PuzzleDefinition>[];
  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(home: AlbumScreen(onPlay: played.add)),
    ),
  );
  await tester.pump();
  return played;
}

Finder _sticker(String id) => find.byKey(ValueKey('sticker-$id'));

/// The album scrolls: twenty-one stickers under six headings do not fit on a
/// phone, and a `ListView` never builds what is below the fold.
Future<void> _scrollTo(WidgetTester tester, Finder target) =>
    tester.scrollUntilVisible(
      target,
      120,
      scrollable: find.byType(Scrollable).first,
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('every puzzle has a sticker, earned or not (§25)', (
    tester,
  ) async {
    final game = _provider();
    addTearDown(game.dispose);

    await _pumpAlbum(tester, game);

    // Walked in the album's own order — category by category — because
    // `scrollUntilVisible` only ever scrolls one way.
    for (final puzzles in PuzzleCatalog.v1.byCategory.values) {
      for (final puzzle in puzzles) {
        await _scrollTo(tester, _sticker(puzzle.id));
        expect(_sticker(puzzle.id), findsOneWidget, reason: puzzle.id);
      }
    }
  });

  testWidgets('an unearned sticker is a silhouette and does nothing (§20)', (
    tester,
  ) async {
    final game = _provider();
    addTearDown(game.dispose);

    final played = await _pumpAlbum(tester, game);
    await _scrollTo(tester, _sticker('lion_01'));
    await tester.tap(_sticker('lion_01'));
    await tester.pump();

    expect(played, isEmpty, reason: 'no scolding, no sound, no navigation');
    final tile = tester.widget<StickerTile>(_sticker('lion_01'));
    expect(tile.earned, isFalse);
    expect(tile.onTap, isNull);
  });

  testWidgets('finishing a puzzle earns its sticker (§25)', (tester) async {
    final game = _provider();
    addTearDown(game.dispose);
    await tester.runAsync(() => _finish(game, 'apple_01'));

    await _pumpAlbum(tester, game);

    final apple = tester.widget<StickerTile>(_sticker('apple_01'));
    expect(apple.earned, isTrue);
    expect(game.progress.unlockedStickerIds, contains('apple_01'));
  });

  testWidgets('tapping an earned sticker plays it again (§4)', (tester) async {
    final game = _provider();
    addTearDown(game.dispose);
    await tester.runAsync(() => _finish(game, 'apple_01'));

    final played = await _pumpAlbum(tester, game);
    await tester.tap(_sticker('apple_01'));
    await tester.pump();

    expect(played.map((p) => p.id), ['apple_01']);
  });

  testWidgets('the stickers are grouped by category (§25)', (tester) async {
    final game = _provider();
    addTearDown(game.dispose);
    await _pumpAlbum(tester, game);

    // Grouping is by category, not by level: the two fruit puzzles live in
    // different levels but sit side by side here.
    final apple = tester.getTopLeft(_sticker('apple_01'));
    final banana = tester.getTopLeft(_sticker('banana_01'));
    expect(apple.dy, banana.dy, reason: 'same row');

    // Six categories since K-14, each with its own symbol, in enum order.
    // Icons from Flutter's own font: §33 rules out emoji characters, which
    // are the platform's glyphs and differ from device to device.
    const icons = [
      Icons.local_dining_rounded,
      Icons.pets_rounded,
      Icons.directions_car_rounded,
      Icons.wb_sunny_rounded,
      Icons.circle_rounded,
      Icons.category_rounded,
    ];
    for (final icon in icons) {
      await _scrollTo(tester, find.byIcon(icon));
      expect(find.byIcon(icon), findsOneWidget, reason: '$icon');
    }
  });

  testWidgets('the way out is big enough to hit (§2)', (tester) async {
    final game = _provider();
    addTearDown(game.dispose);
    await _pumpAlbum(tester, game);

    final size = tester.getSize(find.byKey(const ValueKey('album-back')));
    expect(size.width, greaterThanOrEqualTo(64));
    expect(size.height, greaterThanOrEqualTo(64));
  });
}
