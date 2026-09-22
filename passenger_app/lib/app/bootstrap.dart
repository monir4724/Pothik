import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logger.dart';
import '../core/storage/app_preferences.dart';
import 'app.dart';
import 'providers.dart';

/// Process start. Order matters:
/// 1. config (fail fast on misconfiguration),
/// 2. platform chrome (portrait lock, edge-to-edge),
/// 3. crash reporting wrapping everything else,
/// 4. preferences, then the widget tree.
Future<void> bootstrap() async {
  WidgetsFlutterBinding.ensureInitialized();

  final config = AppConfig.fromEnvironment()..validate();

  // Orientation decision (production UI review §4): portrait-locked. The
  // map + bottom-sheet layout does not have a defined landscape state.
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  Future<void> run() async {
    final prefs = await AppPreferences.load();
    runApp(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(config),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const PothikApp(),
      ),
    );
  }

  if (config.crashReportingEnabled) {
    await SentryFlutter.init((o) {
      o
        ..dsn = config.sentryDsn
        ..environment = config.environment.name
        ..release = 'pothik-passenger@1.0.0+1'
        ..tracesSampleRate = config.isProd ? 0.1 : 1.0
        ..sendDefaultPii = false
        ..attachScreenshot = false
        ..enableAutoSessionTracking = true
        // Scrub anything that might carry PII before it leaves the device.
        ..beforeSend = (event, hint) {
          // Sentry 9: events are mutable; copyWith is deprecated.
          final msg = event.message?.formatted;
          if (msg != null) event.message = SentryMessage(AppLogger.scrub(msg));
          return event;
        };
    }, appRunner: run);
  } else {
    // No DSN (dev): still surface errors loudly in the console.
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      if (kDebugMode) debugPrintStack(stackTrace: details.stack);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      const AppLogger(
        'uncaught',
      ).error('uncaught', error: error, stackTrace: stack);
      return true;
    };
    await run();
  }
}
