import 'dart:math' show Random;

import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/core/services/audio_service.dart';
import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/features/colouring/data/paint_colours.dart';
import 'package:emoji_puzzle_kids/features/colouring/models/car_model.dart';
import 'package:emoji_puzzle_kids/features/colouring/providers/colouring_book.dart';
import 'package:emoji_puzzle_kids/features/home/screens/home_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/game_rules.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/models/game_progress.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../support/recording_sound_player.dart';

const _referencePhone = Size(360, 640);

/// Opens Home on a device where the game already stands at [stored], and
/// presses play.
///
/// The colouring book is seeded to match: since K-18 the stage *is* the
/// number of painted parts of the current car, so a game standing at stage
/// four has four parts painted.
Future<GameProvider> _playFrom(
  WidgetTester tester,
  GameProgress stored,
) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(const {});
  late StorageService storage;
  await tester.runAsync(() async {
    storage = await StorageService.create();
    await ProgressRepository(storage).save(stored);
  });

  final audio = AudioService(player: RecordingSoundPlayer());
  addTearDown(audio.dispose);
  final book = ColouringBook(storage: storage);
  await tester.runAsync(() async {
    // From the end, so the body — the part these tests tap — is still
    // white and can be painted.
    for (final part in book.car.parts.reversed.take(stored.stage)) {
      await book.paint(part.id, PaintColours.paper.toARGB32());
    }
  });
  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
    progressRepository: ProgressRepository(storage),
    audio: audio,
    colouring: book,
    random: Random(4),
  );
  addTearDown(game.dispose);
  await tester.runAsync(game.resume);

  await tester.pumpWidget(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AudioService>.value(value: audio),
        ChangeNotifierProvider<GameProvider>.value(value: game),
      ],
      child: const MaterialApp(home: HomeScreen()),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('home-play')));
  await tester.pumpAndSettle();
  return game;
}

/// Solves the whole puzzle with explicit pumps — the celebration never
/// settles.
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

/// Celebration, balloons and the sticker, each played out to its end.
Future<void> _watchTheReward(WidgetTester tester) async {
  for (final step in const [
    PuzzleConfig.celebrationDuration,
    PuzzleConfig.balloonGameDuration,
    PuzzleConfig.stickerRewardDuration,
  ]) {
    await tester.pump(step);
    await tester.pump();
  }
  expect(find.byKey(const ValueKey('colouring-overlay')), findsOneWidget);
}

/// The real work behind a new puzzle (decoding its picture).
Future<void> _settleAsync(WidgetTester tester) async {
  await tester.runAsync(
    () => Future<void>.delayed(const Duration(milliseconds: 50)),
  );
  await tester.pumpAndSettle();
}

Future<void> _pressBack(WidgetTester tester) async {
  await tester.binding.defaultBinaryMessenger.handlePlatformMessage(
    'flutter/navigation',
    const JSONMethodCodec().encodeMethodCall(const MethodCall('popRoute')),
    (_) {},
  );
  await tester.pumpAndSettle();
}

/// Paints a part of the car: the body, with the colour ready from the
/// start. Since K-18 this is what ends a stage (a skipped page does not).
Future<void> _paintTheCard(WidgetTester tester) async {
  final card = tester.getRect(find.byKey(const ValueKey('colouring-card')));
  await tester.tapAt(
    card.topLeft +
        const Offset(50, 50) * (card.width / CarModel.designSize.width),
  );
  await tester.pump();
  await tester.pump(PuzzleConfig.colouringSettleDuration);
  await tester.pump(const Duration(milliseconds: 20));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'the fifth stage is 4×4, and after its paint the car drives '
      'off and the next car begins at 2×2 (K-15)', (tester) async {
    final game = await _playFrom(
      tester,
      const GameProgress(completedPuzzleIds: {}, stage: 4),
    );
    expect(game.grid, GameRules.stageGrids.last);
    expect(game.pieces, hasLength(16));

    await _solveWithFingers(tester, game);
    await _watchTheReward(tester);
    expect(game.isLastStageOfCar, isTrue);

    await _paintTheCard(tester);
    expect(
      find.byKey(const ValueKey('colouring-overlay')),
      findsOneWidget,
      reason: 'on the last stage the car drives off first (K-15)',
    );
    await tester.pump(PuzzleConfig.colouringDriveOffDuration);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('colouring-overlay')), findsNothing);
    await _settleAsync(tester);

    expect(game.carsFinished, 1);
    expect(game.stage, 0);
    expect(game.grid, GameRules.stageGrids.first);
    expect(game.colouring.carIndex, 1, reason: 'a new car to paint');
    final finished = game.colouring.recentCars.single;
    expect(
      finished.fills['body'],
      PaletteChoice.initial.colour.toARGB32(),
      reason: 'the part painted on the last stage',
    );
    expect(
      finished.fills,
      hasLength(finished.model.parts.length),
      reason: 'no white part on a car that drove off (K-18)',
    );
    expect(find.byKey(const ValueKey('car-parade')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'the third car ends the game: the cars parade, then home, '
      'then a new game (K-15)', (tester) async {
    final game = await _playFrom(
      tester,
      const GameProgress(completedPuzzleIds: {}, stage: 4, carsFinished: 2),
    );

    await _solveWithFingers(tester, game);
    await _watchTheReward(tester);
    await _paintTheCard(tester);
    await tester.pump(PuzzleConfig.colouringDriveOffDuration);
    await tester.pump(const Duration(milliseconds: 20));

    expect(find.byKey(const ValueKey('car-parade')), findsOneWidget);
    expect(game.isGameOver, isTrue);
    expect(find.byKey(const ValueKey('parade-car-0')), findsOneWidget);

    await tester.pump(PuzzleConfig.carParadeDuration);
    await tester.pump(const Duration(milliseconds: 20));
    await tester.pumpAndSettle();
    await _settleAsync(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.byKey(const ValueKey('car-parade')), findsNothing);
    expect(game.isGameOver, isFalse, reason: 'a new game is ready');
    expect(game.carsFinished, 0);
    expect(game.stage, 0);
    expect(game.grid, GameRules.stageGrids.first);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Back during the parade still ends the game kindly (§30)', (
    tester,
  ) async {
    final game = await _playFrom(
      tester,
      const GameProgress(completedPuzzleIds: {}, stage: 4, carsFinished: 2),
    );

    await _solveWithFingers(tester, game);
    await _watchTheReward(tester);
    await _paintTheCard(tester);
    await tester.pump(PuzzleConfig.colouringDriveOffDuration);
    await tester.pump(const Duration(milliseconds: 20));
    expect(find.byKey(const ValueKey('car-parade')), findsOneWidget);

    await _pressBack(tester);
    await _settleAsync(tester);

    expect(find.byType(HomeScreen), findsOneWidget);
    expect(game.isGameOver, isFalse);
    expect(game.carsFinished, 0);
    expect(game.progress.completedPuzzleIds, hasLength(1), reason: 'kept');
    expect(tester.takeException(), isNull);
  });
}
