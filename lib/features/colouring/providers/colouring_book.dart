import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../../../core/services/storage_service.dart';
import '../data/car_catalog.dart';
import '../models/car_model.dart';

/// Boyaması biten bir araba: modeli ve renkleri (K-15).
typedef FinishedCar = ({CarModel model, Map<String, int> fills});

/// Boyama defteri: hangi arabanın açık olduğu, hangi parçasının hangi
/// renge boyandığı ve en son hangi arabaların bittiği (§24.2, K-15).
///
/// Her safhanın sonunda bir parça boyanır. Arabayı ne zaman bitirip
/// sıradakine geçileceğine defter değil oyun karar verir: beşinci safhadan
/// sonra, parçaları beyaz kalmış olsa bile. Sonuncudan sonra başa dönülür.
///
/// `GameProgress`'te değil kendi anahtarında saklanır: bu özellik puzzle'a
/// bağımlı değildir (§36) ve oyunun ilerleme şeması değiştiğinde defter
/// silinmez (§25.1).
class ColouringBook extends ChangeNotifier {
  ColouringBook({StorageService? storage, List<CarModel>? models})
      : _storage = storage,
        _models = models ?? CarCatalog.models,
        assert(models == null || models.isNotEmpty, 'a book needs a car');

  static const String storageKey = 'emoji_puzzle.colouring';

  /// Saklanan yapının sürümü. Tanınmayan bir sürüm hata değildir: defter
  /// ilk arabadan, boş açılır (§25.1'in ruhu). `recent` alanı sonradan
  /// eklendi; olmaması bir sürüm farkı değildir.
  static const int schemaVersion = 1;

  /// Hatırlanan biten araba sayısı: oyun sonu kutlaması üçünü yan yana
  /// gösterir (K-15).
  static const int recentLimit = 3;

  final StorageService? _storage;
  final List<CarModel> _models;

  int _carIndex = 0;
  Map<String, int> _fills = const {};
  List<FinishedCar> _recent = const [];

  /// Açık olan araba.
  CarModel get car => _models[_carIndex];

  /// Katalogdaki sırası, 0'dan.
  int get carIndex => _carIndex;

  /// Boyanan parçalar ve renkleri, opak ARGB olarak (K-9: renk paletten
  /// serbestçe seçilir, bir listenin sırası değildir).
  Map<String, int> get fills => _fills;

  int? colourOf(String partId) => _fills[partId];

  /// En son biten arabalar, en eskisi önce, en çok [recentLimit] tane.
  List<FinishedCar> get recentCars => _recent;

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
      final model = _modelById(decoded['car']);
      if (model == null) return;

      _carIndex = _models.indexOf(model);
      _fills = _readFills(model, decoded['fills']);
      _recent = List.unmodifiable([
        for (final entry in decoded['recent'] as List<Object?>? ?? const [])
          if (entry is Map<String, Object?>)
            if (_modelById(entry['car']) case final finished?)
              (model: finished, fills: _readFills(finished, entry['fills'])),
      ].take(recentLimit));
      notifyListeners();
    } on Object catch (error) {
      // Çocuğa hiçbir durumda hata gösterilmez (§25.1).
      debugPrint('Colouring book unreadable, starting fresh: $error');
    }
  }

  CarModel? _modelById(Object? id) {
    for (final model in _models) {
      if (model.id == id) return model;
    }
    return null;
  }

  static Map<String, int> _readFills(CarModel model, Object? stored) {
    final map = stored as Map<String, Object?>? ?? const {};
    return Map.unmodifiable({
      for (final entry in map.entries)
        if (model.partById(entry.key) != null &&
            entry.value is int &&
            isPaint(entry.value! as int))
          entry.key: entry.value! as int,
    });
  }

  /// Boya olabilecek bir değer mi: tam opak bir ARGB rengi. Saydam boya
  /// kâğıdı gösterirdi, yani hiçbir şey boyamazdı.
  static bool isPaint(int argb) => argb >= 0xFF000000 && argb <= 0xFFFFFFFF;

  /// Bir parçayı [argb] rengine boyar. Bilinmeyen bir parça ya da boya
  /// olamayacak bir değer yok sayılır. Boyanmış parçayı yeniden boyamamak
  /// ekranın kararıdır (K-15); defter izin verir.
  Future<void> paint(String partId, int argb) async {
    if (car.partById(partId) == null) return;
    if (!isPaint(argb)) return;
    _fills = Map.unmodifiable({..._fills, partId: argb});
    notifyListeners();
    await _save();
  }

  /// Açık arabayı bitenlere ekler ve sıradaki arabayı boş olarak açar;
  /// sonuncudan sonra ilkine döner.
  Future<void> startNextCar() async {
    final finished = [..._recent, (model: car, fills: _fills)];
    _recent = List.unmodifiable(
      finished.skip(finished.length - recentLimit < 0
          ? 0
          : finished.length - recentLimit),
    );
    _carIndex = (_carIndex + 1) % _models.length;
    _fills = const {};
    notifyListeners();
    await _save();
  }

  /// §26 — ilerleme sıfırlanınca defter de ilk arabaya, boş döner.
  Future<void> clear() async {
    _carIndex = 0;
    _fills = const {};
    _recent = const [];
    notifyListeners();
    await _storage?.remove(storageKey);
  }

  Future<void> _save() async {
    await _storage?.writeString(
      storageKey,
      jsonEncode({
        'version': schemaVersion,
        'car': car.id,
        'fills': _fills,
        'recent': [
          for (final finished in _recent)
            {'car': finished.model.id, 'fills': finished.fills},
        ],
      }),
    );
  }
}
