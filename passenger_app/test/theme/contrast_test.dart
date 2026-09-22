// WCAG AA contrast audit for the token pairs actually used in the UI.
// Body text needs ≥4.5:1; large text (≥18pt / 14pt bold) needs ≥3:1.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/app/theme/app_colors.dart';

double _luminance(Color c) => c.computeLuminance();

double contrast(Color a, Color b) {
  final la = _luminance(a) + 0.05;
  final lb = _luminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}

void main() {
  test('body text on surfaces passes AA (4.5:1)', () {
    expect(
      contrast(AppColors.textPrimary, AppColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.textSecondary, AppColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.textSecondary, AppColors.neutral100),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.textSecondary, AppColors.background),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('primary button ink on amber passes AA', () {
    expect(
      contrast(AppColors.textOnPrimary, AppColors.amber500),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('text links on white pass AA (amber700, not amber600)', () {
    expect(
      contrast(AppColors.textLink, AppColors.surface),
      greaterThanOrEqualTo(4.5),
    );
    // Documented failure that motivated the token choice:
    expect(contrast(AppColors.amber600, AppColors.surface), lessThan(4.5));
  });

  test('white on danger / secondary buttons passes AA', () {
    expect(
      contrast(AppColors.white, AppColors.danger),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.white, AppColors.neutral900),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('semantic text on semantic surfaces passes AA', () {
    expect(
      contrast(AppColors.success, AppColors.successSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.warning, AppColors.warningSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.danger, AppColors.dangerSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.info, AppColors.infoSurface),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      contrast(AppColors.amber800, AppColors.amber50),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('white text on the neutral banner passes AA', () {
    expect(
      contrast(AppColors.white, AppColors.neutral800),
      greaterThanOrEqualTo(4.5),
    );
  });
}
