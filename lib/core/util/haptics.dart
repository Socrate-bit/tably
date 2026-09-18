import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Every user interaction routes through here so feedback stays consistent.
abstract final class Haptics {
  /// Taps: buttons, cards, list rows, tabs.
  static Future<void> tap() => _run(HapticFeedback.selectionClick);

  /// Toggles and steppers: something switched state.
  static Future<void> toggle() => _run(HapticFeedback.lightImpact);

  /// Committing an action: continue, generate, submit.
  static Future<void> confirm() => _run(HapticFeedback.mediumImpact);

  /// Something finished or failed and deserves a stronger cue.
  static Future<void> notify() => _run(HapticFeedback.heavyImpact);

  static Future<void> _run(Future<void> Function() feedback) async {
    try {
      await feedback();
    } catch (e) {
      // Haptics are unavailable on some platforms — never block the interaction.
      debugPrint('[Haptics] feedback failed: $e');
    }
  }
}
