import 'package:shared_preferences/shared_preferences.dart';

/// Thin wrapper around the device's key-value store (§25).
///
/// It knows nothing about what is stored — that belongs to whoever owns the
/// data, so the shape of the game's progress cannot leak into `core`. What
/// it does own is the awkward part: the store is asynchronous to open and
/// synchronous to read, and everything above wants it already open.
class StorageService {
  StorageService(this._preferences);

  /// Opens the store. Call once, during start-up.
  static Future<StorageService> create() async =>
      StorageService(await SharedPreferences.getInstance());

  final SharedPreferences _preferences;

  String? readString(String key) => _preferences.getString(key);

  Future<bool> writeString(String key, String value) =>
      _preferences.setString(key, value);

  bool? readBool(String key) => _preferences.getBool(key);

  Future<bool> writeBool(String key, {required bool value}) =>
      _preferences.setBool(key, value);

  Future<bool> remove(String key) => _preferences.remove(key);

  bool contains(String key) => _preferences.containsKey(key);
}
