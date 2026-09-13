import 'package:emoji_puzzle_kids/core/services/storage_service.dart';
import 'package:emoji_puzzle_kids/core/theme/theme_settings.dart';
import 'package:emoji_puzzle_kids/features/puzzle/data/progress_repository.dart';
import 'package:flutter/material.dart';
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

  test('follows the phone until someone chooses', () async {
    final settings = ThemeSettings(storage: await _storage())..load();
    addTearDown(settings.dispose);

    expect(settings.mode, ThemeMode.system);
  });

  test('a choice survives closing the app', () async {
    final storage = await _storage();
    final first = ThemeSettings(storage: storage);
    await first.setMode(ThemeMode.dark);
    first.dispose();

    final second = ThemeSettings(storage: storage)..load();
    addTearDown(second.dispose);

    expect(second.mode, ThemeMode.dark);
  });

  test('tells listeners only when something changed', () async {
    final settings = ThemeSettings();
    addTearDown(settings.dispose);
    var notifications = 0;
    settings.addListener(() => notifications++);

    await settings.setMode(ThemeMode.light);
    await settings.setMode(ThemeMode.light);
    await settings.setMode(ThemeMode.system);

    expect(notifications, 2);
  });

  test('a value it does not know falls back to the phone (§25.1)', () async {
    final settings = ThemeSettings(
      storage: await _storage({ThemeSettings.storageKey: 'sepia'}),
    )..load();
    addTearDown(settings.dispose);

    expect(settings.mode, ThemeMode.system);
  });

  test('resetting the progress leaves the look alone (§26)', () async {
    final storage = await _storage();
    final settings = ThemeSettings(storage: storage);
    await settings.setMode(ThemeMode.light);
    settings.dispose();

    await ProgressRepository(storage).clear();

    final reopened = ThemeSettings(storage: storage)..load();
    addTearDown(reopened.dispose);
    expect(reopened.mode, ThemeMode.light);
  });
}
