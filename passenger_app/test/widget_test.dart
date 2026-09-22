// Smoke test: the app boots with the fake backend, shows the splash, and
// proceeds to onboarding once session restore completes.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pothik_passenger/app/app.dart';
import 'package:pothik_passenger/app/providers.dart';
import 'package:pothik_passenger/core/config/app_config.dart';
import 'package:pothik_passenger/core/storage/app_preferences.dart';
import 'package:pothik_passenger/features/onboarding/presentation/onboarding_screen.dart';
import 'package:pothik_passenger/features/onboarding/presentation/splash_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/test_config.dart';

void main() {
  testWidgets('boots to splash then onboarding with fake backend', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferences(await SharedPreferences.getInstance());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(testConfig),
          appPreferencesProvider.overrideWithValue(prefs),
          // Location + connectivity plugins are unavailable in tests.
          locationServiceProvider.overrideWithValue(FakeLocationService()),
          networkStatusProvider.overrideWith((_) => const Stream.empty()),
        ],
        child: const PothikApp(),
      ),
    );

    expect(find.byType(SplashScreen), findsOneWidget);

    // Fake auth restore has ~450ms latency.
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  test('AppConfig.validate rejects fake backend outside dev', () {
    const cfg = AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'https://api.example.com',
      reverbHost: 'ws.example.com',
      reverbPort: 443,
      reverbAppKey: 'real-key',
      reverbUseTls: true,
      sentryDsn: '',
      useFakeBackend: true,
      guardianWebBaseUrl: 'https://track.example.com',
      mapsApiKey: '',
    );
    expect(cfg.validate, throwsStateError);
  });
}
