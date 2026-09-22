import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/app/theme/app_theme.dart';
import 'package:pothik_passenger/l10n/generated/app_localizations.dart';
import 'package:pothik_passenger/shared/widgets/otp_input.dart';

Widget _wrap(Widget child, {double textScale = 1}) => MaterialApp(
  theme: AppTheme.light(),
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  locale: const Locale('bn'),
  home: MediaQuery(
    data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
    child: Scaffold(
      body: Padding(padding: const EdgeInsets.all(16), child: child),
    ),
  ),
);

void main() {
  testWidgets('calls onCompleted with the 6-digit code', (tester) async {
    String? done;
    await tester.pumpWidget(_wrap(OtpInput(onCompleted: (c) => done = c)));
    await tester.enterText(find.byType(TextField), '482913');
    await tester.pump();
    expect(done, '482913');
  });

  testWidgets('fits a 320dp-wide screen at 200% font scale without overflow', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(_wrap(OtpInput(onCompleted: (_) {}), textScale: 2));
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('error state is announced and clears on retype', (tester) async {
    await tester.pumpWidget(
      _wrap(OtpInput(onCompleted: (_) {}, hasError: true)),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });
}
