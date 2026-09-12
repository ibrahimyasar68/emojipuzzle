import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Small taps through the phone's own vibration API (§27).
///
/// No package for this: Flutter already has it. Every call is fire and
/// forget and every failure is swallowed — a device without a vibrator, or
/// one where the user turned it off, must play exactly the same game.
/// Haptics are the third voice after animation and sound, never the only
/// one carrying a message.
class HapticService {
  const HapticService();

  /// Picking a piece up (§17).
  void selection() => _safely(HapticFeedback.selectionClick);

  /// A piece landing in its slot (§22).
  void light() => _safely(HapticFeedback.lightImpact);

  /// The picture is finished (§23).
  void medium() => _safely(HapticFeedback.mediumImpact);

  void _safely(Future<void> Function() action) {
    action().catchError((Object error) {
      debugPrint('Haptics unavailable: $error');
    });
  }
}
