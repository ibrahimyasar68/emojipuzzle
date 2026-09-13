import 'package:flutter/material.dart';

import '../services/storage_service.dart';

/// Ebeveynin seçtiği görünüm: telefonun ayarı, açık ya da koyu.
///
/// Sesin açık/kapalı ayarı gibi cihazda saklanır (K-2). İlerleme
/// sıfırlandığında silinmez: §26 yalnızca ilerlemeyi sayar.
class ThemeSettings extends ChangeNotifier {
  ThemeSettings({StorageService? storage}) : _storage = storage;

  static const String storageKey = 'emoji_puzzle.theme_mode';

  final StorageService? _storage;

  ThemeMode _mode = ThemeMode.system;

  /// Hiç seçilmediyse telefonun kendi ayarı.
  ThemeMode get mode => _mode;

  /// Kayıtlı seçimi okur. Açılışta, ilk kareden önce bir kez çağrılır;
  /// yoksa koyu seçen bir ebeveyn her açılışta bir an açık tema görürdü.
  void load() {
    final stored = _parse(_storage?.readString(storageKey));
    if (stored == _mode) return;
    _mode = stored;
    notifyListeners();
  }

  Future<void> setMode(ThemeMode mode) async {
    if (_mode == mode) return;
    _mode = mode;
    notifyListeners();
    await _storage?.writeString(storageKey, mode.name);
  }

  /// Tanınmayan bir değer hata değildir, telefonun ayarına döner (§25.1'in
  /// ruhu: kimseye hata gösterilmez).
  static ThemeMode _parse(String? stored) {
    for (final candidate in ThemeMode.values) {
      if (candidate.name == stored) return candidate;
    }
    return ThemeMode.system;
  }
}
