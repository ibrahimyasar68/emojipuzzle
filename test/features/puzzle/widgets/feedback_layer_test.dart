import 'package:emoji_puzzle_kids/features/puzzle/models/placement_burst.dart';
import 'package:emoji_puzzle_kids/features/puzzle/widgets/feedback_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Finder get _sparkles => find.descendant(
      of: find.byType(FeedbackLayer),
      matching: find.byType(CustomPaint),
    );

Future<ValueNotifier<PlacementBurst?>> _pumpLayer(WidgetTester tester) async {
  final burst = ValueNotifier<PlacementBurst?>(null);
  addTearDown(burst.dispose);

  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(children: [FeedbackLayer(burst: burst)]),
    ),
  );
  return burst;
}

void main() {
  testWidgets('nothing is drawn until a piece lands', (tester) async {
    await _pumpLayer(tester);

    expect(_sparkles, findsNothing);
  });

  testWidgets('a landing sparkles, then clears itself (§22)', (tester) async {
    final burst = await _pumpLayer(tester);

    burst.value = const PlacementBurst(id: 1, centre: Offset(120, 90));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(_sparkles, findsOneWidget);

    await tester.pumpAndSettle();

    expect(
      _sparkles,
      findsNothing,
      reason: 'the flourish is over well inside 400 ms',
    );
  });

  testWidgets('the next landing starts its own flourish', (tester) async {
    final burst = await _pumpLayer(tester);

    burst.value = const PlacementBurst(id: 1, centre: Offset(120, 90));
    await tester.pump();
    await tester.pumpAndSettle();
    expect(_sparkles, findsNothing);

    burst.value = const PlacementBurst(id: 2, centre: Offset(200, 140));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(_sparkles, findsOneWidget);
  });

  testWidgets('it never takes a touch away from the next piece (§22)', (
    tester,
  ) async {
    final burst = await _pumpLayer(tester);
    burst.value = const PlacementBurst(id: 1, centre: Offset(120, 90));
    await tester.pump();

    final ignorePointer = tester.widget<IgnorePointer>(
      find.descendant(
        of: find.byType(FeedbackLayer),
        matching: find.byType(IgnorePointer),
      ),
    );

    expect(ignorePointer.ignoring, isTrue);
  });
}
