import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/auth/presentation/auth_controller.dart';
import '../features/rides/presentation/active_ride_controller.dart';
import '../l10n/generated/app_localizations.dart';
import 'providers.dart';
import 'router/app_router.dart';
import 'theme/app_theme.dart';

class PothikApp extends ConsumerStatefulWidget {
  const PothikApp({super.key});

  @override
  ConsumerState<PothikApp> createState() => _PothikAppState();
}

class _PothikAppState extends ConsumerState<PothikApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Whenever we become authenticated, load the live ride (if any) from the
    // server — startup, login, or re-login after session expiry.
    ref.listenManual(authControllerProvider, (prev, next) {
      if (next is Authenticated && prev is! Authenticated) {
        ref.read(activeRideProvider.notifier).restore();
      }
      if (next is Unauthenticated) {
        ref.read(realtimeClientProvider).disconnect();
      }
    }, fireImmediately: true);

    ref.read(authControllerProvider.notifier).restore();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // Back from background: re-sync trip state from the server and
      // re-check location permission (Android 12+ can revoke it mid-trip).
      ref.read(activeRideProvider.notifier).resync();
      ref.read(locationAvailabilityProvider.notifier).refresh();
      ref.read(activeRideProvider.notifier).recheckLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final locale = ref.watch(localeProvider);
    final settings = ref.watch(accountSettingsProvider);
    final dark = settings.themeMode == 'dark';
    final large = settings.accessibilityLargeText;

    return MaterialApp.router(
      onGenerateTitle: (context) => AppLocalizations.of(context).appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: dark ? ThemeMode.dark : ThemeMode.light,
      // Avoid TextStyle inherit-mismatch lerp crashes during theme switch
      // on Flutter web (otherwise mouse_tracker asserts spam the console).
      themeAnimationDuration: Duration.zero,
      locale: locale,
      supportedLocales: supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      builder: (context, child) {
        final mq = MediaQuery.of(context);
        final base = mq.textScaler.scale(1).clamp(0.85, 2.0);
        final scale = large ? (base * 1.15).clamp(0.85, 2.0) : base;
        return MediaQuery(
          data: mq.copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        );
      },
    );
  }
}
