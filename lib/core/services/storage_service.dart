import 'package:shared_preferences/shared_preferences.dart';

/// Cihazın anahtar-değer deposu etrafında ince bir sarmalayıcı (§25).
///
/// Ne saklandığını bilmez — o, verinin sahibinin işidir; böylece oyunun
/// ilerleme yapısı `core`'a sızmaz. Üstlendiği şey işin zahmetli kısmıdır:
/// depo açılırken asenkron, okunurken senkrondur ve üstündeki her şey onu
/// çoktan açılmış ister.
class StorageService {
  StorageService(this._preferences);

  /// Depoyu açar. Açılışta bir kez çağrılır.
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
