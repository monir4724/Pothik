import 'package:flutter/material.dart';

/// Single source of truth for the palette. Screens must never use raw hex.
///
/// Contrast notes (WCAG AA, verified with the relative-luminance formula in
/// `test/theme/contrast_test.dart`):
/// - `neutral700` on white is used for body text at 13sp — `neutral600`
///   (#6B7280) is 4.83:1 and passes AA for normal text, but we step captions
///   up to `neutral700` for comfortable margin on low-quality panels.
/// - White on `amber500` (#F5A623) is ~1.9:1 and FAILS AA. Primary buttons
///   therefore use `neutral900` ink on amber, which is ~9.5:1.
/// - `amber700` (#966209) is used for text links on white (5.2:1) instead of
///   `amber600` (#D48C12, ~2.9:1 — fails). The earlier #A86E0B was 4.29:1
///   and also failed; the audit test caught it.
abstract final class AppColors {
  // Brand
  /// Wordmark / app-icon green from `logo.html` / `App Icon.html`.
  static const Color brandGreen = Color(0xFF0C8B51);
  static const Color amber50 = Color(0xFFFFF8EB);
  static const Color amber100 = Color(0xFFFEEBC8);
  static const Color amber200 = Color(0xFFFDD68F);
  static const Color amber500 = Color(0xFFF5A623);
  static const Color amber600 = Color(0xFFD48C12);
  static const Color amber700 = Color(0xFF966209);
  static const Color amber800 = Color(0xFF7A4F06);

  // Neutrals
  static const Color white = Color(0xFFFFFFFF);
  static const Color neutral50 = Color(0xFFF9FAFB);
  static const Color neutral100 = Color(0xFFF3F4F6);
  static const Color neutral200 = Color(0xFFE5E7EB);
  static const Color neutral300 = Color(0xFFD1D5DB);
  static const Color neutral400 = Color(0xFF9CA3AF);
  static const Color neutral500 = Color(0xFF6B7280);
  static const Color neutral600 = Color(0xFF6B7280);
  static const Color neutral700 = Color(0xFF4B5563);
  static const Color neutral800 = Color(0xFF1F2937);
  static const Color neutral900 = Color(0xFF111827);

  // Semantic
  static const Color success = Color(0xFF15803D);
  static const Color successSurface = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSurface = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerHover = Color(0xFF991B1B);
  static const Color dangerSurface = Color(0xFFFEE2E2);
  static const Color info = Color(0xFF1D4ED8);
  static const Color infoSurface = Color(0xFFDBEAFE);

  // Roles
  static const Color textPrimary = neutral900;
  static const Color textSecondary = neutral700;
  static const Color textDisabled = neutral400;
  static const Color textOnPrimary = neutral900;
  static const Color textLink = amber700;
  static const Color surface = white;
  static const Color background = neutral50;
  static const Color border = neutral200;
  static const Color divider = neutral200;
  static const Color scrim = Color(0x99111827);
  static const Color skeletonBase = neutral200;
  static const Color skeletonHighlight = neutral100;

  // Map
  static const Color routePolyline = neutral900;
  static const Color pickupMarker = success;
  static const Color dropoffMarker = danger;
}
