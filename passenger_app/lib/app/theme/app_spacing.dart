import 'package:flutter/widgets.dart';

/// 4dp base grid.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
  static const double xxxl = 48;

  /// Horizontal page gutter.
  static const double gutter = lg;

  static const EdgeInsets page = EdgeInsets.symmetric(horizontal: gutter);
  static const EdgeInsets card = EdgeInsets.all(lg);
}

abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;

  static const BorderRadius smAll = BorderRadius.all(Radius.circular(sm));
  static const BorderRadius mdAll = BorderRadius.all(Radius.circular(md));
  static const BorderRadius lgAll = BorderRadius.all(Radius.circular(lg));
  static const BorderRadius xlAll = BorderRadius.all(Radius.circular(xl));
  static const BorderRadius sheetTop = BorderRadius.vertical(
    top: Radius.circular(xl),
  );
}

/// Accessibility sizing constants (Android/iOS baseline).
abstract final class AppSizes {
  /// Minimum interactive hit area, per WCAG 2.5.5 / platform HIG.
  static const double minTapTarget = 48;

  /// Absolute floor when 48 is impossible (dense rows).
  static const double minTapTargetCompact = 44;

  static const double buttonHeight = 52;
  static const double buttonHeightCompact = 44;
  static const double inputHeight = 52;
  static const double iconSm = 16;
  static const double iconMd = 24;
  static const double iconLg = 32;

  /// Max content width so tablet layouts don't stretch card content.
  static const double maxContentWidth = 560;

  /// Home shell bottom sheet initial height as fraction of screen.
  static const double homeSheetInitialFraction = 0.32;
}
