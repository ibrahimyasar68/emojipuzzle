import 'package:emoji_puzzle_kids/core/services/haptic_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what the platform was asked to buzz.
List<String> _listenForHaptics() {
  final calls = <String>[];
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(SystemChannels.platform, (call) async {
    if (call.method == 'HapticFeedback.vibrate') {
      calls.add(call.arguments as String? ?? 'default');
    }
    return null;
  });
  addTearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null),
  );
  return calls;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('each moment has its own strength (§27)', () async {
    final calls = _listenForHaptics();
    const haptics = HapticService();

    haptics
      ..selection()
      ..light()
      ..medium();
    await Future<void>.delayed(Duration.zero);

    expect(calls, [
      'HapticFeedbackType.selectionClick',
      'HapticFeedbackType.lightImpact',
      'HapticFeedbackType.mediumImpact',
    ]);
  });

  test('a phone that cannot buzz is not a problem (§27)', () async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      throw PlatformException(code: 'unavailable');
    });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null),
    );

    const haptics = HapticService();

    // Nothing thrown, nothing awaited, nothing for the game to handle.
    expect(haptics.light, returnsNormally);
    await Future<void>.delayed(Duration.zero);
  });
}
