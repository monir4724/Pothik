import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../core/config/app_config.dart';
import '../core/connectivity/connectivity_status.dart';
import '../core/fake/fake_backend.dart';
import '../core/fake/fake_store.dart';
import '../core/location/location_service.dart';
import '../core/maps/google_places_client.dart';
import '../core/network/api_client.dart';
import '../core/realtime/realtime_client.dart';
import '../core/storage/app_preferences.dart';
import '../core/storage/token_storage.dart';
import '../features/auth/data/auth_repository.dart';
import '../features/auth/presentation/auth_controller.dart';
import '../features/chat/data/chat_repository.dart';
import '../features/places/data/google_backed_places_repository.dart';
import '../features/places/data/places_repository.dart';
import '../features/profile/domain/account_settings.dart';
import '../features/rides/data/ride_repository.dart';
import '../features/sos/data/sos_repository.dart';

// ---------------------------------------------------------------------------
// Bootstrapped singletons — overridden in main() with real instances.
// ---------------------------------------------------------------------------

final appConfigProvider = Provider<AppConfig>(
  (_) => throw UnimplementedError('override in main'),
);

final appPreferencesProvider = Provider<AppPreferences>(
  (_) => throw UnimplementedError('override in main'),
);

final tokenStorageProvider = Provider<TokenStorage>(
  (ref) => ref.watch(appConfigProvider).useFakeBackend
      ? FakePrefsTokenStorage(ref.watch(appPreferencesProvider))
      : SecureTokenStorage(),
);

/// Stable per-install id (not a hardware id) for device-token binding.
final deviceIdProvider = Provider<String>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  final existing = prefs.deviceId;
  if (existing != null) return existing;
  final id = const Uuid().v4();
  unawaited(prefs.setDeviceId(id));
  return id;
});

final fakeWorldProvider = Provider<FakeWorld>((ref) {
  final w = FakeWorld(
    store: PrefsFakeAccountStore(ref.watch(appPreferencesProvider)),
  );
  ref.onDispose(w.dispose);
  return w;
});

// ---------------------------------------------------------------------------
// Network
// ---------------------------------------------------------------------------

final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(appConfigProvider),
    tokenStorage: ref.watch(tokenStorageProvider),
    deviceId: ref.watch(deviceIdProvider),
    onSessionExpired: () =>
        ref.read(authControllerProvider.notifier).onSessionExpired(),
  );
});

final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  final client = RealtimeClient(
    config: ref.watch(appConfigProvider),
    authorize: (socketId, channel) =>
        ref.read(rideRepositoryProvider).authorizeChannel(socketId, channel),
  );
  ref.onDispose(client.dispose);
  return client;
});

final realtimeStatusProvider = StreamProvider<RealtimeStatus>((ref) {
  final c = ref.watch(realtimeClientProvider);
  return c.status.startWith(c.currentStatus);
});

final networkStatusProvider = StreamProvider<NetworkStatus>((ref) async* {
  yield await currentNetworkStatus();
  yield* watchNetworkStatus();
});

// ---------------------------------------------------------------------------
// Repositories (real vs fake chosen once, here)
// ---------------------------------------------------------------------------

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(appConfigProvider).useFakeBackend) {
    return FakeAuthRepository(
      ref.watch(fakeWorldProvider),
      ref.watch(tokenStorageProvider),
    );
  }
  return RemoteAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

final rideRepositoryProvider = Provider<RideRepository>((ref) {
  if (ref.watch(appConfigProvider).useFakeBackend) {
    return FakeRideRepository(ref.watch(fakeWorldProvider));
  }
  return RemoteRideRepository(ref.watch(apiClientProvider));
});

final chatRepositoryProvider = Provider<ChatRepository>((ref) {
  if (ref.watch(appConfigProvider).useFakeBackend) {
    return FakeChatRepository(ref.watch(fakeWorldProvider));
  }
  return RemoteChatRepository(ref.watch(apiClientProvider));
});

final sosRepositoryProvider = Provider<SosRepository>((ref) {
  if (ref.watch(appConfigProvider).useFakeBackend) {
    return FakeSosRepository(ref.watch(fakeWorldProvider));
  }
  return RemoteSosRepository(ref.watch(apiClientProvider));
});

final placesRepositoryProvider = Provider<PlacesRepository>((ref) {
  final local = ref.watch(appConfigProvider).useFakeBackend
      ? FakePlacesRepository(ref.watch(fakeWorldProvider))
      : RemotePlacesRepository(ref.watch(apiClientProvider));
  return GoogleBackedPlacesRepository(
    local: local,
    google: createGooglePlacesClient(ref.watch(appConfigProvider).mapsApiKey),
  );
});

// ---------------------------------------------------------------------------
// Platform services
// ---------------------------------------------------------------------------

final locationServiceProvider = Provider<LocationService>(
  (_) => GeolocatorLocationService(),
);

final locationAvailabilityProvider =
    NotifierProvider<LocationAvailabilityController, LocationAvailability?>(
      LocationAvailabilityController.new,
    );

final class LocationAvailabilityController
    extends Notifier<LocationAvailability?> {
  @override
  LocationAvailability? build() {
    unawaited(refresh());
    return null;
  }

  Future<LocationAvailability> refresh() async {
    final a = await ref.read(locationServiceProvider).check();
    state = a;
    return a;
  }

  Future<LocationAvailability> request() async {
    final a = await ref.read(locationServiceProvider).request();
    state = a;
    return a;
  }
}

// ---------------------------------------------------------------------------
// Locale
// ---------------------------------------------------------------------------

const supportedLocales = [Locale('bn'), Locale('en')];

final localeProvider = NotifierProvider<LocaleController, Locale>(
  LocaleController.new,
);

final class LocaleController extends Notifier<Locale> {
  @override
  Locale build() {
    final code = ref.watch(appPreferencesProvider).localeCode;
    // Default to Bangla: primary market. English is a deliberate opt-in.
    return code == null ? const Locale('bn') : Locale(code);
  }

  Future<void> set(Locale locale) async {
    if (locale == state) return;
    state = locale;
    await ref.read(appPreferencesProvider).setLocaleCode(locale.languageCode);
    // Best-effort server sync so SMS/push copy matches the app language.
    final auth = ref.read(authControllerProvider);
    if (auth is Authenticated) {
      unawaited(
        ref
            .read(authControllerProvider.notifier)
            .updateProfile(locale: locale.languageCode)
            .then<void>((_) {}, onError: (Object _) {}),
      );
    }
  }
}

extension on Stream<RealtimeStatus> {
  Stream<RealtimeStatus> startWith(RealtimeStatus first) async* {
    yield first;
    yield* this;
  }
}

final accountSettingsProvider =
    NotifierProvider<AccountSettingsController, AccountSettings>(
      AccountSettingsController.new,
    );

final class AccountSettingsController extends Notifier<AccountSettings> {
  @override
  AccountSettings build() {
    ref.watch(authControllerProvider);
    if (ref.read(appConfigProvider).useFakeBackend) {
      return ref.read(fakeWorldProvider).settings;
    }
    return const AccountSettings();
  }

  Future<void> save(AccountSettings next) async {
    state = next;
    if (ref.read(appConfigProvider).useFakeBackend) {
      final w = ref.read(fakeWorldProvider);
      w.settings = next;
      await w.persist();
    }
  }
}
