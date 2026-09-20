import 'dart:io';
import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/app/themed_app.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/core/theme/app_theme.dart';
import 'package:emoji_puzzle_kids/core/theme/theme_settings.dart';
import 'package:emoji_puzzle_kids/features/album/screens/album_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/about_screen.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/home/widgets/home_button.dart';
import 'package:emoji_puzzle_kids/features/home/widgets/play_puzzle_button.dart';
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
  _Harness(this.game, this.audio, this.theme);

  final GameProvider game;
  final AudioService audio;
  final ThemeSettings theme;
}

Future<_Harness> _pumpHome(
  WidgetTester tester, {
  Size screen = _referencePhone,
}) async {
  tester.view.physicalSize = screen;
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
  final theme = ThemeSettings();
  addTearDown(theme.dispose);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
        ChangeNotifierProvider<GameProvider>.value(value: game),
        ChangeNotifierProvider<ThemeSettings>.value(value: theme),
      ],
      child: const ThemedApp(home: HomeScreen()),
    ),
  );
  await tester.pump();
  return _Harness(game, audio, theme);
}

/// The grown-ups' door is a hold, not a tap (K-21): two seconds with a
/// finger on the ⓘ. A child does not do that by accident.
Future<void> _openAbout(WidgetTester tester) async {
  final gesture = await tester.startGesture(
    tester.getCenter(find.byKey(const ValueKey('home-about'))),
  );
  // The tap recognizer reports the press only once it has won the arena,
  // so the hold starts on the *next* frame, not on this one.
  await tester.pump(const Duration(milliseconds: 150));
  await tester.pump(PuzzleConfig.homeAboutHoldDuration);
  // An AnimationController is done once its duration is passed, not when
  // it is reached.
  await tester.pump(const Duration(milliseconds: 20));
  await gesture.up();
  await tester.pumpAndSettle();
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
    // Play is its own widget since K-21 — a finished four-piece puzzle of a
    // smiling face — so the count is three round buttons plus that one.
    expect(find.byType(HomeButton), findsNWidgets(keys.length - 1));
    expect(find.byType(PlayPuzzleButton), findsOneWidget);
    expect(keys.length, lessThanOrEqualTo(5));
  });

  group('home fills a tablet the way it fills a phone (§40)', () {
    const screens = <String, Size>{
      'small phone': Size(320, 568),
      'reference phone': Size(360, 640),
      'phone, turned sideways': Size(640, 360),
      'tablet': Size(768, 1024),
      'big tablet': Size(1024, 1366),
      'tablet, turned sideways': Size(1024, 768),
    };

    for (final screen in screens.entries) {
      testWidgets(screen.key, (tester) async {
        await _pumpHome(tester, screen: screen.value);

        Rect rectOf(String key) => tester.getRect(find.byKey(ValueKey(key)));
        final play = rectOf('home-play');
        final album = rectOf('home-album');
        final mute = rectOf('home-mute');
        final about = rectOf('home-about');
        final group = play.expandToInclude(album).expandToInclude(mute);
        final shortSide = screen.value.shortestSide;

        // Fixed sizes left the three buttons covering a fifth of a 1024 dp
        // tablet, measured; on the reference phone they cover three fifths.
        expect(
          group.width / shortSide,
          greaterThanOrEqualTo(0.4),
          reason: 'the buttons sit lost in the middle of ${screen.key}',
        );

        // And growing never costs the phone anything.
        expect(play.width, greaterThanOrEqualTo(160), reason: 'play');
        expect(album.width, greaterThanOrEqualTo(96), reason: 'album');
        expect(play.width, greaterThan(album.width), reason: 'play leads');

        final bounds = Offset.zero & screen.value;
        for (final rect in [play, album, mute, about]) {
          expect(bounds.intersect(rect), rect, reason: 'on screen: $rect');
        }
        expect(play.overlaps(album) || play.overlaps(mute), isFalse);
        expect(album.overlaps(mute), isFalse);
        expect(group.overlaps(about), isFalse, reason: 'the grown-ups door');
        expect(tester.takeException(), isNull);
      });
    }
  });

  testWidgets('a tap on the grown-ups door does nothing (K-21)', (
    tester,
  ) async {
    await _pumpHome(tester);

    await tester.tap(find.byKey(const ValueKey('home-about')));
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsNothing);

    // And it does not open a moment later either: a tap that only *starts*
    // the hold would open the door two seconds after the child let go.
    await tester.pump(PuzzleConfig.homeAboutHoldDuration * 2);
    await tester.pumpAndSettle();
    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('letting go too early keeps the door shut (K-21)', (
    tester,
  ) async {
    await _pumpHome(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('home-about'))),
    );
    await tester.pump(const Duration(milliseconds: 150));
    await tester.pump(PuzzleConfig.homeAboutHoldDuration ~/ 2);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byType(AboutScreen), findsNothing);
  });

  testWidgets('the door says what it is for, and how long (K-21)', (
    tester,
  ) async {
    await _pumpHome(tester);

    // Two seconds is the promise the config makes; the screen must use it.
    final button = tester.widget<HomeButton>(
      find.byKey(const ValueKey('home-about')),
    );
    expect(button.holdDuration, PuzzleConfig.homeAboutHoldDuration);
    expect(PuzzleConfig.homeAboutHoldDuration, const Duration(seconds: 2));
  });

  testWidgets('the play button is a finished four-piece puzzle (K-21)', (
    tester,
  ) async {
    await _pumpHome(tester);

    final play = tester.widget<PlayPuzzleButton>(
      find.byKey(const ValueKey('home-play')),
    );
    expect(PlayPuzzleButton.grid.pieceCount, 4);
    expect(play.size, greaterThanOrEqualTo(64), reason: '§2');
    expect(
      File(PlayPuzzleButton.facePath).existsSync(),
      isTrue,
      reason: 'the face ships with the app',
    );

    // The red play badge sits on it, and it is big enough to see.
    final badge = find.descendant(
      of: find.byKey(const ValueKey('home-play')),
      matching: find.byIcon(Icons.play_arrow_rounded),
    );
    expect(badge, findsOneWidget);
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

    await _openAbout(tester);

    expect(find.byType(AboutScreen), findsOneWidget);

    // The screen is a ListView and K-21 put a description above the
    // attribution, so it starts below the fold; a ListView never builds
    // what is not on screen.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('about-attribution')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('about-attribution')), findsOneWidget);
    expect(find.textContaining('OpenMoji'), findsOneWidget);
    expect(find.textContaining('CC BY-SA 4.0'), findsOneWidget);
  });

  testWidgets(
      'the grown-ups corner says what the game is, who made it '
      'and how to reach them (K-21)', (tester) async {
    await _pumpHome(tester);
    await _openAbout(tester);

    expect(find.byKey(const ValueKey('about-summary')), findsOneWidget);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('about-summary')))
          .data!
          .length,
      greaterThan(80),
      reason: 'a real description, not a label',
    );
    expect(find.text(AboutScreen.maker), findsOneWidget);
    expect(find.text(AboutScreen.contactEmail), findsOneWidget);
    expect(AboutScreen.contactEmail, contains('@'));
  });

  testWidgets('the grown-ups pick the phone\'s look, light or dark', (
    tester,
  ) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    final harness = await _pumpHome(tester);

    Color background() =>
        tester.widget<Scaffold>(find.byType(Scaffold).last).backgroundColor!;

    bool framed(String mode) {
      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(ValueKey('about-theme-$mode')),
              matching: find.byType(Container),
            )
            .first,
      );
      return (box.decoration! as BoxDecoration).border != null;
    }

    await _openAbout(tester);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('about-theme-dark')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.ensureVisible(find.byKey(const ValueKey('about-theme-dark')));
    await tester.pumpAndSettle();

    expect(harness.theme.mode, ThemeMode.system);
    expect(background(), AppPalette.light.background, reason: 'phone is light');

    await tester.tap(find.byKey(const ValueKey('about-theme-dark')));
    await tester.pumpAndSettle();
    expect(harness.theme.mode, ThemeMode.dark);
    expect(background(), AppPalette.dark.background);
    expect(framed('dark'), isTrue, reason: 'the chosen option is framed');
    expect(framed('light'), isFalse);
    expect(framed('system'), isFalse);

    await tester.tap(find.byKey(const ValueKey('about-theme-light')));
    await tester.pumpAndSettle();
    expect(harness.theme.mode, ThemeMode.light);
    expect(background(), AppPalette.light.background);

    await tester.tap(find.byKey(const ValueKey('about-theme-system')));
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    await tester.pumpAndSettle();
    expect(harness.theme.mode, ThemeMode.system);
    expect(
      background(),
      AppPalette.dark.background,
      reason: 'the phone went dark, and the game follows it',
    );
  });

  testWidgets('resetting needs a long press, not a tap (§26)', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final harness = await _pumpHome(tester);
    await tester.runAsync(() => harness.game.startNextPuzzle());
    for (final piece in [...harness.game.pieces]) {
      harness.game.markPlaced(piece.id);
    }
    expect(harness.game.progress.completedPuzzleIds, isNotEmpty);
    await harness.game.colouring.startNextCar();
    await harness.game.colouring.paint('cab', 0xFF43A047);

    await _openAbout(tester);

    // Deliberately the last thing on a page of grown-ups' text: a child who
    // gets this far has scrolled past three paragraphs to reach it.
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('about-reset')),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    // The appearance picker made the page longer: a button that is only half
    // on screen can have its centre off the bottom.
    await tester.ensureVisible(find.byKey(const ValueKey('about-reset')));
    await tester.pumpAndSettle();

    // A child who finds this screen and prods the button loses nothing.
    await tester.tap(find.byKey(const ValueKey('about-reset')));
    await tester.pump();
    expect(harness.game.progress.completedPuzzleIds, isNotEmpty);

    await tester.longPress(find.byKey(const ValueKey('about-reset')));
    await tester.pumpAndSettle();

    expect(harness.game.progress.completedPuzzleIds, isEmpty);
    expect(harness.game.progress.stage, 0);
    expect(harness.game.progress.carsFinished, 0);
    expect(harness.game.progress.lastPlayedPuzzleId, isNull);
    // The car goes back to a blank first model too (§24.2).
    expect(harness.game.colouring.carIndex, 0);
    expect(harness.game.colouring.fills, isEmpty);
  });
}
