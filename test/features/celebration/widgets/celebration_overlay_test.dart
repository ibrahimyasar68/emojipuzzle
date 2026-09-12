import 'package:emoji_puzzle_kids/features/celebration/widgets/celebration_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _shortCelebration = Duration(milliseconds: 300);

Future<int Function()> _pumpOverlay(
  WidgetTester tester, {
  Duration duration = _shortCelebration,
}) async {
  var finished = 0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          CelebrationOverlay(
            origin: const Offset(180, 200),
            duration: duration,
            onFinished: () => finished++,
          ),
        ],
      ),
    ),
  );
  return () => finished;
}

void main() {
  testWidgets('it plays, then hands back (§23)', (tester) async {
    final finished = await _pumpOverlay(tester);

    await tester.pump(const Duration(milliseconds: 100));
    expect(finished(), 0, reason: 'the picture gets its moment');

    await tester.pump(_shortCelebration);
    expect(finished(), 1);

    await tester.pump(const Duration(seconds: 1));
    expect(finished(), 1, reason: 'once, not once per frame');
  });

  testWidgets('a tap ends it at once (§23)', (tester) async {
    final finished = await _pumpOverlay(
      tester,
      duration: const Duration(seconds: 30),
    );

    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('celebration-overlay')));
    await tester.pump();

    expect(finished(), 1, reason: 'no child waits 30 seconds');

    // And the timer it cancelled does not come back to fire later.
    await tester.pump(const Duration(seconds: 31));
    expect(finished(), 1);
  });

  testWidgets('tapping twice still only finishes once', (tester) async {
    final finished = await _pumpOverlay(
      tester,
      duration: const Duration(seconds: 30),
    );

    final overlay = find.byKey(const ValueKey('celebration-overlay'));
    await tester.tap(overlay);
    await tester.pump();
    await tester.tap(overlay);
    await tester.pump();

    expect(finished(), 1);
  });

  testWidgets('it draws something over the finished picture', (tester) async {
    await _pumpOverlay(tester);
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.descendant(
        of: find.byType(CelebrationOverlay),
        matching: find.byType(CustomPaint),
      ),
      findsWidgets,
    );

    await tester.pump(_shortCelebration);
  });
}
