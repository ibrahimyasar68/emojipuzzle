import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../data/car_catalog.dart';
import '../models/car_model.dart';

/// Boyama defteri: hangi arabanın açık olduğu ve hangi parçasının hangi
/// renge boyandığı (§24.2).
///
/// Her puzzle bitişinde bir parça boyanır; bütün parçalar boyanınca defter
/// sıradaki arabaya geçer, sonuncudan sonra başa döner.
///
/// `GameProgress`'te değil kendi anahtarında saklanır: bu özellik puzzle'a
/// bağımlı değildir (§36) ve oyunun ilerleme şeması değişmediği için
/// kayıtlı ilerleme bu yüzden asla silinmez (§25.1).
class ColouringBook extends ChangeNotifier {
  ColouringBook({StorageService? storage, List<CarModel>? models})
      : _storage = storage,
        _models = models ?? CarCatalog.models,
        assert(models == null || models.isNotEmpty, 'a book needs a car');

  static const String storageKey = 'emoji_puzzle.colouring';

  /// Saklanan yapının sürümü. Tanınmayan bir sürüm hata değildir: defter
  /// ilk arabadan, boş açılır (§25.1'in ruhu).
  static const int schemaVersion = 1;

  final StorageService? _storage;
  final List<CarModel> _models;

  int _carIndex = 0;
  Map<String, int> _fills = const {};

  /// Açık olan araba.
  CarModel get car => _models[_carIndex];

  /// Katalogdaki sırası, 0'dan.
  int get carIndex => _carIndex;

  /// Boyanan parçalar ve renkleri, opak ARGB olarak (K-9: renk paletten
  /// serbestçe seçilir, bir listenin sırası değildir).
  Map<String, int> get fills => _fills;

  int? colourOf(String partId) => _fills[partId];

  /// Arabanın her parçası boyandı mı.
  bool get isCarComplete => car.parts.every((p) => _fills.containsKey(p.id));

  /// Kayıtlı defteri okur. Uygulama açılırken bir kez çağrılır.
  void load() {
    final raw = _storage?.readString(storageKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, Object?>;
      if (decoded['version'] != schemaVersion) {
        debugPrint('Colouring book version ${decoded['version']} — fresh.');
        return;
      }
      final index = _models.indexWhere((m) => m.id == decoded['car']);
      if (index < 0) return;
      final model = _models[index];
      final stored = decoded['fills'] as Map<String, Object?>? ?? const {};

      _carIndex = index;
      _fills = Map.unmodifiable({
        for (final entry in stored.entries)
          if (model.partById(entry.key) != null &&
              entry.value is int &&
              isPaint(entry.value! as int))
            entry.key: entry.value! as int,
      });
      notifyListeners();
    } on Object catch (error) {
      // Çocuğa hiçbir durumda hata gösterilmez (§25.1).
      debugPrint('Colouring book unreadable, starting fresh: $error');
    }
  }

  /// Boya olabilecek bir değer mi: tam opak bir ARGB rengi. Saydam boya
  /// kâğıdı gösterirdi, yani hiçbir şey boyamazdı.
  static bool isPaint(int argb) => argb >= 0xFF000000 && argb <= 0xFFFFFFFF;

  /// Bir parçayı [argb] rengine boyar. Boyanmış parça yeniden boyanabilir.
  /// Bilinmeyen bir parça ya da boya olamayacak bir değer yok sayılır.
  Future<void> paint(String partId, int argb) async {
    if (car.partById(partId) == null) return;
    if (!isPaint(argb)) return;
    _fills = Map.unmodifiable({..._fills, partId: argb});
    notifyListeners();
    await _save();
  }

  /// Sıradaki arabayı boş olarak açar; sonuncudan sonra ilkine döner.
  Future<void> startNextCar() async {
    _carIndex = (_carIndex + 1) % _models.length;
    _fills = const {};
    notifyListeners();
    await _save();
  }

  /// §26 — ilerleme sıfırlanınca defter de ilk arabaya, boş döner.
  Future<void> clear() async {
    _carIndex = 0;
    _fills = const {};
    notifyListeners();
    await _storage?.remove(storageKey);
  }

  Future<void> _save() async {
    await _storage?.writeString(
      storageKey,
      jsonEncode({'version': schemaVersion, 'car': car.id, 'fills': _fills}),
    );
  }
}
