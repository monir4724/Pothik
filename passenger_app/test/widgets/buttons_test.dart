import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/app/theme/app_spacing.dart';
import 'package:pothik_passenger/app/theme/app_theme.dart';
import 'package:pothik_passenger/shared/widgets/buttons.dart';

Widget _wrap(Widget child) => MaterialApp(
  theme: AppTheme.light(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  testWidgets('AppButton meets the 48dp minimum height', (tester) async {
    await tester.pumpWidget(
      _wrap(AppButton.primary(label: 'Go', onPressed: () {}, expand: false)),
    );
    final size = tester.getSize(find.byType(FilledButton));
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
  });

  testWidgets('compact ghost button still has a 48dp hit area', (tester) async {
    await tester.pumpWidget(
      _wrap(AppButton.ghost(label: 'Skip', onPressed: () {}, compact: true)),
    );
    // materialTapTargetSize.padded expands the hit box even when visual
    // height is 44.
    final semantics = tester.getSemantics(find.text('Skip'));
    expect(
      semantics.rect.height,
      greaterThanOrEqualTo(AppSizes.minTapTargetCompact),
    );
  });

  testWidgets('loading state disables taps and shows a spinner', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        AppButton.primary(
          label: 'Book',
          onPressed: () => taps++,
          isLoading: true,
        ),
      ),
    );
    await tester.tap(find.byType(FilledButton), warnIfMissed: false);
    await tester.pump();
    expect(taps, 0);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('AppIconButton exposes its semantic label and 48dp box', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        AppIconButton(
          icon: Icons.close,
          semanticLabel: 'Close dialog',
          onPressed: () {},
        ),
      ),
    );
    expect(find.bySemanticsLabel('Close dialog'), findsOneWidget);
    final size = tester.getSize(find.byType(InkWell));
    expect(size.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
    expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
  });

  testWidgets('long Bangla label wraps to two lines instead of overflowing', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      _wrap(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: AppButton.primary(
            label:
                'পিকআপ লোকেশন ঠিক করে এখনই বুকিং নিশ্চিত করুন এবং চালিয়ে যান',
            onPressed: () {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
