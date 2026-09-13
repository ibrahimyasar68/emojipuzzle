import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Telefonun kendi titreşim API'si üzerinden küçük dokunuşlar (§27).
///
/// Bunun için paket kullanılmaz: Flutter'da zaten var. Her çağrı yap-unut
/// biçimindedir ve her hata yutulur — titreşimi olmayan ya da kullanıcının
/// kapattığı bir cihaz da tıpatıp aynı oyunu oynamalıdır. Haptik, animasyon
/// ve sesten sonraki üçüncü sestir; mesajı tek başına taşıyan hiçbir zaman
/// o değildir.
class HapticService {
  const HapticService();

  /// Parça alınırken (§17).
  void selection() => _safely(HapticFeedback.selectionClick);

  /// Parça yuvasına otururken (§22).
  void light() => _safely(HapticFeedback.lightImpact);

  /// Resim tamamlandığında (§23).
  void medium() => _safely(HapticFeedback.mediumImpact);

  void _safely(Future<void> Function() action) {
    action().catchError((Object error) {
      debugPrint('Haptics unavailable: $error');
    });
  }
}
