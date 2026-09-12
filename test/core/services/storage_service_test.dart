import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<StorageService> _storage([
  Map<String, Object> initial = const {},
]) async {
  SharedPreferences.setMockInitialValues(initial);
  return StorageService.create();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a missing key reads as null, not as an error', () async {
    final storage = await _storage();

    expect(storage.readString('nothing'), isNull);
    expect(storage.readBool('nothing'), isNull);
    expect(storage.contains('nothing'), isFalse);
  });

  test('what goes in comes back out', () async {
    final storage = await _storage();

    await storage.writeString('greeting', 'merhaba');
    await storage.writeBool('muted', value: true);

    expect(storage.readString('greeting'), 'merhaba');
    expect(storage.readBool('muted'), isTrue);
    expect(storage.contains('greeting'), isTrue);
  });

  test('reads values that were already on the device', () async {
    final storage = await _storage({'greeting': 'selam'});

    expect(storage.readString('greeting'), 'selam');
  });

  test('remove forgets a key', () async {
    final storage = await _storage({'greeting': 'selam'});

    await storage.remove('greeting');

    expect(storage.readString('greeting'), isNull);
    expect(storage.contains('greeting'), isFalse);
  });
}
