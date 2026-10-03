import 'package:flutter/services.dart';

/// Clean, crisp single-pulse haptic feedback utility for DocsMind.
/// Each method produces exactly ONE immediate, tactile vibration impulse without delays or duplicate buzzes.
class AppHaptics {
  static int _lastHapticTime = 0;
  static const int _debounceMs = 90;

  static bool _canVibrate() {
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastHapticTime < _debounceMs) {
      return false;
    }
    _lastHapticTime = now;
    return true;
  }

  /// Subtle single selection click (e.g. tab switches, mode chips, sliders)
  static Future<void> selectionClick() async {
    if (!_canVibrate()) return;
    await HapticFeedback.selectionClick();
  }

  /// Pleasant single light tap (e.g. minor button presses, icon taps, dismissals)
  static Future<void> lightImpact() async {
    if (!_canVibrate()) return;
    await HapticFeedback.lightImpact();
  }

  /// Distinct single medium impact (e.g. action buttons, card selections, dialog opens)
  static Future<void> mediumImpact() async {
    if (!_canVibrate()) return;
    await HapticFeedback.mediumImpact();
  }

  /// Strong single heavy impact (e.g. camera shutter, auto-scanner trigger, compression complete)
  static Future<void> heavyImpact() async {
    if (!_canVibrate()) return;
    await HapticFeedback.heavyImpact();
  }

  /// Standard platform vibration pulse
  static Future<void> vibrate() async {
    if (!_canVibrate()) return;
    await HapticFeedback.vibrate();
  }
}
