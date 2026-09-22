import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/location/location_service.dart';
import '../../features/auth/domain/user.dart';
import '../../features/auth/presentation/auth_controller.dart';
import '../../features/auth/presentation/otp_verify_screen.dart';
import '../../features/auth/presentation/phone_entry_screen.dart';
import '../../features/auth/presentation/profile_setup_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/history/presentation/ride_detail_screen.dart';
import '../../features/history/presentation/ride_history_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/onboarding/presentation/location_permission_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/places/presentation/saved_places_screen.dart';
import '../../features/profile/presentation/emergency_contacts_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/profile_sections.dart';
import '../../features/rides/domain/ride_models.dart';
import '../../features/rides/presentation/active_ride_controller.dart';
import '../../features/rides/presentation/fare_estimate_screen.dart';
import '../../features/rides/presentation/finding_driver_screen.dart';
import '../../features/rides/presentation/rating_screen.dart';
import '../../features/rides/presentation/tracking_screen.dart';
import '../../features/rides/presentation/trip_complete_screen.dart';
import '../../features/search/presentation/place_search_screen.dart';
import '../providers.dart';
import 'routes.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref
    ..listen(authControllerProvider, (_, _) => refresh.value++)
    ..listen(
      activeRideProvider.select(
        (s) => (s.ride?.id, s.ride?.status, s.isRestoring),
      ),
      (_, _) => refresh.value++,
    )
    ..listen(locationAvailabilityProvider, (_, _) => refresh.value++);

  final router = GoRouter(
    initialLocation: Routes.splash,
    refreshListenable: refresh,
    debugLogDiagnostics: kDebugMode,
    redirect: (context, state) => _redirect(ref, state.uri.path),
    routes: [
      GoRoute(path: Routes.splash, builder: (_, _) => const SplashScreen()),
      GoRoute(
        path: Routes.onboarding,
        builder: (_, _) => const OnboardingScreen(),
      ),
      GoRoute(path: Routes.phone, builder: (_, _) => const PhoneEntryScreen()),
      GoRoute(
        path: Routes.otp,
        redirect: (_, s) => s.extra is OtpChallenge ? null : Routes.phone,
        builder: (_, s) => OtpVerifyScreen(challenge: s.extra! as OtpChallenge),
      ),
      GoRoute(
        path: Routes.profileSetup,
        builder: (_, _) => const ProfileSetupScreen(),
      ),
      GoRoute(
        path: Routes.locationPermission,
        builder: (_, _) => const LocationPermissionScreen(),
      ),
      GoRoute(path: Routes.home, builder: (_, _) => const HomeScreen()),
      GoRoute(
        path: Routes.search,
        builder: (_, s) => PlaceSearchScreen(
          field: s.uri.queryParameters['field'] == 'pickup'
              ? SearchField.pickup
              : SearchField.dropoff,
        ),
      ),
      GoRoute(
        path: Routes.estimate,
        builder: (_, _) => const FareEstimateScreen(),
      ),
      GoRoute(
        path: '/ride/:id',
        builder: (_, s) => TrackingScreen(rideId: s.pathParameters['id']!),
        routes: [
          GoRoute(
            path: 'finding',
            builder: (_, s) =>
                FindingDriverScreen(rideId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'chat',
            builder: (_, s) => ChatScreen(tripId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'complete',
            builder: (_, s) =>
                TripCompleteScreen(rideId: s.pathParameters['id']!),
          ),
          GoRoute(
            path: 'rate',
            builder: (_, s) => RatingScreen(rideId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.history,
        builder: (_, _) => const RideHistoryScreen(),
        routes: [
          GoRoute(
            path: ':id',
            builder: (_, s) =>
                RideDetailScreen(rideId: s.pathParameters['id']!),
          ),
        ],
      ),
      GoRoute(
        path: Routes.places,
        builder: (_, _) => const SavedPlacesScreen(),
      ),
      GoRoute(
        path: Routes.profile,
        builder: (_, _) => const ProfileScreen(),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (_, _) => const ProfileSetupScreen(isEdit: true),
          ),
          GoRoute(
            path: 'emergency-contacts',
            builder: (_, _) => const EmergencyContactsScreen(),
          ),
          GoRoute(
            path: 'security',
            builder: (_, _) => const AccountSecurityScreen(),
          ),
          GoRoute(
            path: 'change-phone',
            builder: (_, _) => const ChangePhoneScreen(),
          ),
          GoRoute(
            path: 'payments',
            builder: (_, _) => const PaymentMethodsScreen(),
          ),
          GoRoute(
            path: 'ratings',
            builder: (_, _) => const RatingsReviewsScreen(),
          ),
          GoRoute(
            path: 'promotions',
            builder: (_, _) => const PromotionsScreen(),
          ),
          GoRoute(
            path: 'notifications',
            builder: (_, _) => const NotificationSettingsScreen(),
          ),
          GoRoute(
            path: 'help',
            builder: (_, _) => const HelpSupportScreen(),
          ),
          GoRoute(
            path: 'settings',
            builder: (_, _) => const AppSettingsScreen(),
          ),
          GoRoute(
            path: 'scheduled',
            builder: (_, _) => const ScheduledRidesScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (_, _) => const _NotFoundScreen(),
  );

  ref.onDispose(() {
    router.dispose();
    refresh.dispose();
  });
  return router;
});

/// Where a live ride *must* be shown, by status.
String? _stageRoute(Ride ride) => switch (ride.status) {
  RideStatus.searching => Routes.finding(ride.id),
  RideStatus.accepted ||
  RideStatus.arriving ||
  RideStatus.arrived ||
  RideStatus.inProgress => Routes.ride(ride.id),
  RideStatus.paymentPending => Routes.complete(ride.id),
  RideStatus.completed || RideStatus.cancelled || RideStatus.noDriver => null,
};

String? _redirect(Ref ref, String path) {
  final auth = ref.read(authControllerProvider);
  final rideState = ref.read(activeRideProvider);
  final prefs = ref.read(appPreferencesProvider);

  // 1. Still restoring session → stay on splash.
  final restoring =
      auth is AuthUnknown || (auth is Authenticated && rideState.isRestoring);
  if (restoring) return path == Routes.splash ? null : Routes.splash;

  // 2. Onboarding gate.
  if (!prefs.onboardingDone) {
    return path == Routes.onboarding ? null : Routes.onboarding;
  }

  // 3. Auth gate.
  if (auth is! Authenticated) {
    final allowed = path == Routes.phone || path == Routes.otp;
    return allowed ? null : Routes.phone;
  }

  // 4. Profile completion gate (first login).
  if (!auth.user.isProfileComplete) {
    return path == Routes.profileSetup ? null : Routes.profileSetup;
  }

  // 5. Live ride: force the correct stage from "home-ish" routes and keep
  //    ride sub-routes consistent with status. Other screens (profile,
  //    history…) remain reachable; Home shows a resume banner.
  final ride = rideState.ride;
  final stage = ride == null ? null : _stageRoute(ride);
  if (ride != null && stage != null) {
    if (path.startsWith('/ride/${ride.id}')) {
      if (path == Routes.chat(ride.id) && ride.status.isTracking) return null;
      return path == stage ? null : stage;
    }
    if (path == Routes.splash ||
        path == Routes.home ||
        path == Routes.search ||
        path == Routes.estimate ||
        path == Routes.profileSetup ||
        path == Routes.locationPermission ||
        Routes.isAuthRoute(path) ||
        Routes.isRideRoute(path)) {
      return stage;
    }
    return null;
  }

  // 6. No live ride but on a ride route with nothing to show → home.
  if (Routes.isRideRoute(path) && ride == null) return Routes.home;

  // 7. Post-auth landing.
  if (path == Routes.splash ||
      path == Routes.onboarding ||
      Routes.isAuthRoute(path)) {
    final loc = ref.read(locationAvailabilityProvider);
    if (!prefs.locationRationaleShown && loc != LocationAvailability.ready) {
      return Routes.locationPermission;
    }
    return Routes.home;
  }
  return null;
}

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: TextButton(
          onPressed: () => context.go(Routes.home),
          child: const Icon(Icons.home_rounded),
        ),
      ),
    );
  }
}
