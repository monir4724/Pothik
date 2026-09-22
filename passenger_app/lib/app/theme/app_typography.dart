import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Typography scale. All sizes are in logical pixels and scale with the OS
/// font setting via [MediaQuery.textScaler] (we deliberately do **not** clamp
/// global scaling; layouts are built to survive 200%).
///
/// Family: Hind Siliguri (bundled). It covers Latin + Bengali glyphs so the
/// same family serves both locales without fallback jumps.
abstract final class AppTypography {
  static const String fontFamily = 'HindSiliguri';

  static const TextStyle displayLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 32,
    height: 1.25,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingLg = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    height: 1.3,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMd = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    height: 1.3,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSm = TextStyle(
    fontFamily: fontFamily,
    fontSize: 17,
    height: 1.35,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    height: 1.5,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySecondary = TextStyle(
    fontFamily: fontFamily,
    fontSize: 13,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    height: 1.4,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    height: 1.25,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.2,
  );

  /// Fare / OTP / countdown. Tabular figures so digits don't jitter.
  static const TextStyle numeric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    height: 1.2,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  static TextTheme get textTheme => const TextTheme(
    displayLarge: displayLg,
    headlineLarge: headingLg,
    headlineMedium: headingMd,
    headlineSmall: headingSm,
    titleMedium: headingSm,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: bodySecondary,
    labelLarge: button,
    labelMedium: caption,
    labelSmall: caption,
  );
}
