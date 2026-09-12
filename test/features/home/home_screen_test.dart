import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/features/album/screens/album_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/about_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/features/home/widgets/home_button.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/recording_sound_player.dart';

const _referencePhone = Size(360, 640);

class _Harness {
  _Harness(this.game, this.audio);

  final GameProvider game;
  final AudioService audio;
}

Future<_Harness> _pumpHome(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final audio = AudioService(player: RecordingSoundPlayer());
  addTearDown(audio.dispose);
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
    audio: audio,
  );
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
  return _Harness(game, audio);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('four things to touch, all of them big (§2)', (tester) async {
    await _pumpHome(tester);

    const keys = ['home-play', 'home-album', 'home-mute', 'home-about'];
    for (final key in keys) {
      final finder = find.byKey(ValueKey(key));
      expect(finder, findsOneWidget, reason: key);
      final size = tester.getSize(finder);
      expect(size.width, greaterThanOrEqualTo(64), reason: key);
      expect(size.height, greaterThanOrEqualTo(64), reason: key);
    }

    // §2 allows five; a fifth would be one too many to add without thought.
    expect(find.byType(HomeButton), findsNWidgets(keys.length));
    expect(keys.length, lessThanOrEqualTo(5));
  });

  testWidgets('the album opens and closes again (§25)', (tester) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-album')));
    await tester.pumpAndSettle();
    expect(find.byType(AlbumScreen), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('album-back')));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);
  });

  testWidgets('the sound switch flips and sticks (K-2, §27)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await _pumpHome(tester);

    expect(harness.audio.muted, isFalse);
    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-mute')));
    await tester.pump();

    expect(harness.audio.muted, isTrue);
    expect(
      find.byIcon(Icons.volume_off_rounded),
      findsOneWidget,
      reason: 'the button shows the state, not the action',
    );

    await tester.tap(find.byKey(const ValueKey('home-mute')));
    await tester.pump();
    expect(harness.audio.muted, isFalse);
  });

  testWidgets('the grown-ups door leads to the attribution (§33)', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-about')));
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('about-attribution')), findsOneWidget);
    expect(find.textContaining('OpenMoji'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
  });

  testWidgets('resetting needs a long press, not a tap (§26)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await _pumpHome(tester);
    await tester.runAsync(() => harness.game.startNextPuzzle());
    for (final piece in [...harness.game.pieces]) {
      harness.game.markPlaced(piece.id);
    }
    expect(harness.game.progress.completedPuzzleIds, isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('home-about')));
    await tester.pumpAndSettle();

    // Deliberately the last thing on a page of grown-ups' text: a child who
    // gets this far has scrolled past three paragraphs to reach it.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('about-reset')),
      120,
      scrollable: find.byType(Scrollable).first,
    );

    // A child who finds this screen and prods the button loses nothing.
    await tester.tap(find.byKey(const ValueKey('about-reset')));
    await tester.pump();
    expect(harness.game.progress.completedPuzzleIds, isNotEmpty);

    await tester.longPress(find.byKey(const ValueKey('about-reset')));
    await tester.pumpAndSettle();

    expect(harness.game.progress.completedPuzzleIds, isEmpty);
    expect(harness.game.progress.unlockedLevel, 1);
    expect(harness.game.progress.lastPlayedPuzzleId, isNull);
  });
}
