import 'dart:io';
import 'dart:math' show Random;
import 'dart:ui' as ui;

import 'package:emoji_puzzle_kids/core/constants/debug_flags.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/coordinate_mapper.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/geometry/puzzle_generator.dart';
import 'package:emoji_puzzle_kids/features/puzzle/engine/tray_shuffler.dart';
import 'package:emoji_puzzle_kids/features/puzzle/providers/game_provider.dart';
import 'package:emoji_puzzle_kids/features/puzzle/screens/puzzle_screen.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/debug_overlay_painter.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/puzzle_board.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

/// Lets a test rasterise the screen mid-drag.
final _captureKey = GlobalKey();

const _referencePhone = Size(360, 640);
final _puzzle = PuzzleCatalog.v1.byId('apple_01');
final _grid = _puzzle.grid;

Future<GameProvider> _pumpGame(WidgetTester tester) async {
  tester.view.physicalSize = _referencePhone;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);

  final game = GameProvider(
    generator: PuzzleGenerator(random: Random(1)),
    shuffler: TrayShuffler(random: Random(1)),
  );
  addTearDown(game.dispose);
  await tester.runAsync(() => game.startPuzzle(_puzzle));

  await tester.pumpWidget(
    ChangeNotifierProvider<GameProvider>.value(
      value: game,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: RepaintBoundary(key: _captureKey, child: const PuzzleScreen()),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return game;
}

/// Pan gestures only start once the touch slop is exceeded.
const _slopBreaker = Offset(0, -30);

void main() {
  testWidgets('a dragged piece leaves the tray for the drag layer', (
    tester,
  ) async {
    await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(_slopBreaker);
    await tester.pump();

    expect(find.byKey(const ValueKey('drag-piece-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('tray-piece-0')), findsNothing);
    // The other pieces stay put in their own slots (§16.2).
    expect(find.byKey(const ValueKey('tray-piece-1')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('drag-piece-0')), findsNothing);
    expect(find.byKey(const ValueKey('tray-piece-0')), findsOneWidget);
  });

  testWidgets('the grab point stays under the finger (§9)', (tester) async {
    await _pumpGame(tester);

    final trayRect = tester.getRect(find.byKey(const ValueKey('tray-piece-0')));
    final boardRect =
        tester.getRect(find.byKey(const ValueKey('puzzle-board')));
    final pieceSize = CoordinateMapper.pieceSizeOf(
      CoordinateMapper.cellSizeOf(_grid, boardRect.size),
    );
    final trayScale = trayRect.width / pieceSize.width;

    // Grab near the top-left corner, nowhere near the centre.
    const grabLocal = Offset(12, 9);
    const travel = Offset(60, -140);
    final gesture = await tester.startGesture(trayRect.topLeft + grabLocal);
    await gesture.moveBy(travel);
    await tester.pumpAndSettle(); // let the lift animation finish at scale 1

    final pointer = trayRect.topLeft + grabLocal + travel;
    final expectedTopLeft = pointer - grabLocal / trayScale;
    final actualTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('drag-piece-0')),
    );

    expect(actualTopLeft.dx, closeTo(expectedTopLeft.dx, 0.5));
    expect(actualTopLeft.dy, closeTo(expectedTopLeft.dy, 0.5));

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
      'moving the finger rebuilds neither the board nor the '
      'provider (§17, §42)', (tester) async {
    final game = await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(_slopBreaker);
    await tester.pumpAndSettle();

    final boardBefore = tester.widget<PuzzleBoard>(find.byType(PuzzleBoard));
    var notifications = 0;
    game.addListener(() => notifications++);

    for (var step = 0; step < 12; step++) {
      await gesture.moveBy(const Offset(3, -4));
      await tester.pump();
    }

    expect(
      notifications,
      0,
      reason: 'the provider must not hear about every frame',
    );
    expect(
      identical(
        tester.widget<PuzzleBoard>(find.byType(PuzzleBoard)),
        boardBefore,
      ),
      isTrue,
      reason: 'the board widget was rebuilt during the drag',
    );
    // The piece did follow the finger, so the drag really was live.
    expect(find.byKey(const ValueKey('drag-piece-0')), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(notifications, 1, reason: 'only the drop reaches the provider');
  });

  testWidgets('the dragged piece sits above everything else', (tester) async {
    await _pumpGame(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(const Offset(0, -200));
    await tester.pumpAndSettle();

    // The drag layer paints after the board and the tray, so the piece in
    // the air is always on top of them (§10). Only the sparkles sit higher,
    // and they ignore touches (§22).
    final stack = tester.widget<Stack>(
      find
          .descendant(
              of: find.byType(PuzzleScreen), matching: find.byType(Stack))
          .first,
    );
    final order = stack.children.map((w) => w.runtimeType.toString()).toList();

    expect(order.indexOf('DragLayer'), greaterThan(order.indexOf('Column')));
    expect(order.last, 'FeedbackLayer');

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('the debug overlay is off by default and drawable on demand', (
    tester,
  ) async {
    await _pumpGame(tester);
    expect(find.byWidgetPredicate(_isOverlay), findsNothing);

    debugShowPuzzleOverlay = true;
    addTearDown(() => debugShowPuzzleOverlay = false);

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('tray-piece-0'))),
    );
    await gesture.moveBy(_slopBreaker);
    await tester.pumpAndSettle();

    expect(find.byWidgetPredicate(_isOverlay), findsOneWidget);

    // Leave a picture of a piece in flight: shadow, lifted scale, cell
    // bounds, snap radius and the grab-offset vector all in one frame.
    await tester.runAsync(() async {
      final boundary = _captureKey.currentContext!.findRenderObject()!
          as RenderRepaintBoundary;
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      Directory('build').createSync(recursive: true);
      File('build/drag_overlay.png')
          .writeAsBytesSync(png!.buffer.asUint8List());
    });

    await gesture.up();
    await tester.pumpAndSettle();
  });
}

bool _isOverlay(Widget widget) =>
    widget is CustomPaint && widget.painter is DebugOverlayPainter;
