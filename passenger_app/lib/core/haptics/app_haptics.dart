import 'package:flutter/services.dart';

/// Haptic vocabulary (production UI review §10). Keep it small so feedback
/// stays meaningful.
abstract final class AppHaptics {
  /// Button press / selection change.
  static Future<void> light() => HapticFeedback.lightImpact();

  /// SOS hold progress tick (every ~1s).
  static Future<void> tick() => HapticFeedback.selectionClick();

  /// Booking confirmed, trip complete, rating submitted.
  static Future<void> success() => HapticFeedback.mediumImpact();

  /// Wrong OTP, destructive confirm.
  static Future<void> error() => HapticFeedback.heavyImpact();

  /// SOS triggered.
  static Future<void> alarm() async {
    await HapticFeedback.heavyImpact();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    await HapticFeedback.heavyImpact();
  }
}
