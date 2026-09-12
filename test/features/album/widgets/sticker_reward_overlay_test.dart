import 'package:emoji_puzzle_kids/core/constants/puzzle_config.dart';
import 'package:emoji_puzzle_kids/features/album/widgets/sticker_reward_overlay.dart';
import 'package:emoji_puzzle_kids/features/album/widgets/sticker_tile.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/puzzle_catalog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<int Function()> _pumpReward(WidgetTester tester) async {
  var finished = 0;
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Stack(
        children: [
          StickerRewardOverlay(
            puzzle: PuzzleCatalog.v1.byId('apple_01'),
            onFinished: () => finished++,
          ),
        ],
      ),
    ),
  );
  return () => finished;
}

void main() {
  testWidgets('it shows the sticker, then hands back (§23, §25)', (
    tester,
  ) async {
    final finished = await _pumpReward(tester);

    await tester.pump(const Duration(milliseconds: 100));
    final tile = tester.widget<StickerTile>(find.byType(StickerTile));
    expect(tile.puzzle.id, 'apple_01');
    expect(tile.earned, isTrue, reason: 'it has just been earned');
    expect(finished(), 0);

    await tester.pump(PuzzleConfig.stickerRewardDuration);
    expect(finished(), 1);

    await tester.pump(const Duration(seconds: 2));
    expect(finished(), 1, reason: 'once, not once per frame');
  });

  testWidgets('a tap ends it at once (§23)', (tester) async {
    final finished = await _pumpReward(tester);
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.byKey(const ValueKey('sticker-reward')));
    await tester.pump();

    expect(finished(), 1);

    await tester.pump(const Duration(seconds: 3));
    expect(finished(), 1, reason: 'the timer it cancelled stays cancelled');
  });

  testWidgets('tapping twice still only finishes once', (tester) async {
    final finished = await _pumpReward(tester);
    final reward = find.byKey(const ValueKey('sticker-reward'));

    await tester.tap(reward);
    await tester.pump();
    await tester.tap(reward);
    await tester.pump();

    expect(finished(), 1);
  });
}
