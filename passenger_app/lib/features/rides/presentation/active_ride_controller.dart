import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/location/location_service.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/realtime/realtime_client.dart';
import '../domain/ride_models.dart';

/// A booking the user asked for. Carries the idempotency key so a retry
/// after a timeout reuses the **same** key and can't double-book.
final class BookingAttempt {
  const BookingAttempt({
    required this.quoteId,
    required this.vehicleType,
    required this.idempotencyKey,
    this.note,
  });

  final String quoteId;
  final VehicleType vehicleType;
  final String idempotencyKey;
  final String? note;
}

final class ActiveRideState {
  const ActiveRideState({
    this.ride,
    this.isRestoring = true,
    this.isResyncing = false,
    this.isBooking = false,
    this.bookingError,
    this.pendingBooking,
    this.locationPaused = false,
    this.cashConfirmError,
    this.isConfirmingCash = false,
  });

  final Ride? ride;

  /// True until the first `GET /rides/active` completes at startup.
  final bool isRestoring;

  /// True while re-fetching after the app returns from background.
  final bool isResyncing;
  final bool isBooking;

  /// Set when `POST /rides` itself failed (timeout/network/5xx) — distinct
  /// from "no drivers found", which is a ride status.
  final ApiException? bookingError;
  final BookingAttempt? pendingBooking;

  /// Passenger location publishing has stopped because permission/GPS was
  /// revoked mid-trip.
  final bool locationPaused;
  final ApiException? cashConfirmError;
  final bool isConfirmingCash;

  bool get hasActiveRide => ride?.status.isActive ?? false;

  ActiveRideState copyWith({
    Object? ride = _sentinel,
    bool? isRestoring,
    bool? isResyncing,
    bool? isBooking,
    Object? bookingError = _sentinel,
    Object? pendingBooking = _sentinel,
    bool? locationPaused,
    Object? cashConfirmError = _sentinel,
    bool? isConfirmingCash,
  }) => ActiveRideState(
    ride: ride == _sentinel ? this.ride : ride as Ride?,
    isRestoring: isRestoring ?? this.isRestoring,
    isResyncing: isResyncing ?? this.isResyncing,
    isBooking: isBooking ?? this.isBooking,
    bookingError: bookingError == _sentinel
        ? this.bookingError
        : bookingError as ApiException?,
    pendingBooking: pendingBooking == _sentinel
        ? this.pendingBooking
        : pendingBooking as BookingAttempt?,
    locationPaused: locationPaused ?? this.locationPaused,
    cashConfirmError: cashConfirmError == _sentinel
        ? this.cashConfirmError
        : cashConfirmError as ApiException?,
    isConfirmingCash: isConfirmingCash ?? this.isConfirmingCash,
  );

  static const _sentinel = Object();
}

final activeRideProvider =
    NotifierProvider<ActiveRideController, ActiveRideState>(
      ActiveRideController.new,
    );

final class ActiveRideController extends Notifier<ActiveRideState> {
  static const _log = AppLogger('ride');
  static const _uuid = Uuid();

  /// Poll cadence: fast when realtime is down (it *is* the transport),
  /// slow when realtime is up (safety net for missed events).
  static const _pollWhenDisconnected = Duration(seconds: 3);
  static const _pollWhenConnected = Duration(seconds: 15);
  static const _locationPublishInterval = Duration(seconds: 5);

  Timer? _pollTimer;
  StreamSubscription<RealtimeEvent>? _eventSub;
  StreamSubscription<RealtimeStatus>? _statusSub;
  StreamSubscription<GeoPoint>? _locationSub;
  String? _subscribedChannel;
  DateTime _lastPublished = DateTime.fromMillisecondsSinceEpoch(0);
  String? _cashConfirmKey;
  bool _fetchInFlight = false;

  @override
  ActiveRideState build() {
    // Riverpod forbids touching `ref`/`state` inside onDispose, so only
    // release raw resources here; the realtime client is captured up front.
    final rt = ref.read(realtimeClientProvider);
    final fake = ref.read(appConfigProvider).useFakeBackend;
    ref.onDispose(() {
      final ch = _subscribedChannel;
      _releaseResources();
      if (ch != null && !fake) rt.unsubscribe(ch);
    });
    return const ActiveRideState();
  }

  // ---------------------------------------------------------------------
  // Restore / resync
  // ---------------------------------------------------------------------

  /// Startup: the server is the source of truth for "do I have a ride?".
  Future<void> restore() async {
    try {
      final ride = await ref.read(rideRepositoryProvider).activeRide();
      _apply(ride);
    } on Object catch (e) {
      _log.warn('restore active ride failed', {'e': '$e'});
    } finally {
      state = state.copyWith(isRestoring: false);
    }
  }

  /// App returned to foreground while a ride is live.
  Future<void> resync() async {
    final id = state.ride?.id;
    if (id == null || !state.hasActiveRide) return;
    state = state.copyWith(isResyncing: true);
    try {
      await _refetch(id);
    } finally {
      state = state.copyWith(isResyncing: false);
    }
  }

  // ---------------------------------------------------------------------
  // Booking
  // ---------------------------------------------------------------------

  Future<void> book({
    required String quoteId,
    required VehicleType vehicleType,
    String? note,
  }) {
    final attempt = BookingAttempt(
      quoteId: quoteId,
      vehicleType: vehicleType,
      idempotencyKey: _uuid.v4(),
      note: note,
    );
    return _submitBooking(attempt);
  }

  /// Retries the *same* attempt (same idempotency key).
  Future<void> retryBooking() {
    final attempt = state.pendingBooking;
    if (attempt == null) return Future.value();
    return _submitBooking(attempt);
  }

  void clearBookingError() =>
      state = state.copyWith(bookingError: null, pendingBooking: null);

  Future<void> _submitBooking(BookingAttempt attempt) async {
    state = state.copyWith(
      isBooking: true,
      bookingError: null,
      pendingBooking: attempt,
    );
    _log.info('booking', {
      'quote': attempt.quoteId,
      'key': attempt.idempotencyKey,
    });
    try {
      final ride = await ref
          .read(rideRepositoryProvider)
          .book(
            quoteId: attempt.quoteId,
            vehicleType: attempt.vehicleType,
            idempotencyKey: attempt.idempotencyKey,
            note: attempt.note,
          );
      _apply(ride);
      state = state.copyWith(isBooking: false, pendingBooking: null);
      unawaited(AppHaptics.success());
    } on ApiException catch (e) {
      _log.warn('booking failed', {
        'code': e.code.name,
        'server': e.serverCode,
      });
      if (e.hasServerCode(ServerErrorCodes.activeRideExists)) {
        // Server says we already have one (e.g. earlier attempt actually
        // succeeded). Recover by loading it.
        await restore();
        state = state.copyWith(isBooking: false, pendingBooking: null);
        return;
      }
      state = state.copyWith(isBooking: false, bookingError: e);
    }
  }

  // ---------------------------------------------------------------------
  // Mutations
  // ---------------------------------------------------------------------

  Future<void> cancel(CancelReason reason) async {
    final id = state.ride?.id;
    if (id == null) return;
    final ride = await ref.read(rideRepositoryProvider).cancel(id, reason);
    _log.info('ride cancelled', {'ride': id, 'reason': reason.wire});
    _apply(ride);
  }

  /// Idempotent: the key is minted once per ride and reused on retry.
  Future<bool> confirmCash() async {
    final id = state.ride?.id;
    if (id == null) return false;
    _cashConfirmKey ??= _uuid.v4();
    state = state.copyWith(isConfirmingCash: true, cashConfirmError: null);
    try {
      final ride = await ref
          .read(rideRepositoryProvider)
          .confirmCash(id, idempotencyKey: _cashConfirmKey!);
      _log.info('cash confirmed', {'ride': id});
      _apply(ride);
      state = state.copyWith(isConfirmingCash: false);
      unawaited(AppHaptics.success());
      return true;
    } on ApiException catch (e) {
      _log.warn('cash confirm failed', {'code': e.code.name});
      state = state.copyWith(isConfirmingCash: false, cashConfirmError: e);
      return false;
    }
  }

  Future<void> rate({required int stars, String? comment}) async {
    final id = state.ride?.id;
    if (id == null) return;
    await ref
        .read(rideRepositoryProvider)
        .rate(id, stars: stars, comment: comment);
    state = state.copyWith(ride: state.ride?.copyWith(rated: true));
  }

  /// Called after the rating/complete flow; forgets the finished ride.
  void dismissFinishedRide() {
    if (state.hasActiveRide) return;
    _cashConfirmKey = null;
    state = state.copyWith(ride: null, cashConfirmError: null);
  }

  // ---------------------------------------------------------------------
  // State application
  // ---------------------------------------------------------------------

  void _apply(Ride? ride) {
    final prev = state.ride;
    state = state.copyWith(ride: ride);

    if (ride == null || ride.status.isTerminal) {
      _stopTracking();
      unawaited(ref.read(appPreferencesProvider).setLastActiveRideId(null));
      if (prev != null && prev.status.isActive && ride != null) {
        _log.info('ride ended', {'ride': ride.id, 'status': ride.status.wire});
      }
      return;
    }

    unawaited(ref.read(appPreferencesProvider).setLastActiveRideId(ride.id));
    _ensureTracking(ride);

    if (prev?.status != ride.status) {
      _log.info('ride status', {'ride': ride.id, 'status': ride.status.wire});
      if (ride.status == RideStatus.accepted) unawaited(AppHaptics.success());
    }
  }

  void _ensureTracking(Ride ride) {
    final channel = 'private-trip.${ride.id}';
    if (_subscribedChannel != channel) {
      _stopTracking();
      _subscribedChannel = channel;
      final rt = ref.read(realtimeClientProvider);
      if (!ref.read(appConfigProvider).useFakeBackend) {
        rt.connect();
        unawaited(rt.subscribe(channel));
      }
      _eventSub = rt.channel(channel).listen(_onEvent);
      _statusSub = rt.status.listen((_) => _restartPolling());
      _restartPolling();
    }
    if (ride.status.isTracking) {
      _startLocationPublishing(ride.id);
    } else {
      _stopLocationPublishing();
    }
  }

  void _stopTracking() {
    final ch = _subscribedChannel;
    _releaseResources();
    if (ch != null && !ref.read(appConfigProvider).useFakeBackend) {
      ref.read(realtimeClientProvider).unsubscribe(ch);
    }
    if (state.locationPaused) state = state.copyWith(locationPaused: false);
  }

  /// Cancels timers/subscriptions only. Must not touch `ref` or `state`
  /// because it also runs from `onDispose`.
  void _releaseResources() {
    _pollTimer?.cancel();
    _pollTimer = null;
    unawaited(_eventSub?.cancel());
    _eventSub = null;
    unawaited(_statusSub?.cancel());
    _statusSub = null;
    unawaited(_locationSub?.cancel());
    _locationSub = null;
    _subscribedChannel = null;
  }

  void _restartPolling() {
    _pollTimer?.cancel();
    final id = state.ride?.id;
    if (id == null) return;
    final connected = ref.read(realtimeClientProvider).isConnected;
    final every = connected ? _pollWhenConnected : _pollWhenDisconnected;
    _pollTimer = Timer.periodic(every, (_) => _refetch(id));
  }

  Future<void> _refetch(String id) async {
    if (_fetchInFlight) return;
    _fetchInFlight = true;
    try {
      final ride = await ref.read(rideRepositoryProvider).getRide(id);
      if (state.ride?.id == id) _apply(ride);
    } on ApiException catch (e) {
      if (e.code == ApiErrorCode.notFound) {
        _log.warn('active ride vanished', {'ride': id});
        _apply(null);
      }
    } on Object catch (e) {
      _log.warn('poll failed', {'e': '$e'});
    } finally {
      _fetchInFlight = false;
    }
  }

  void _onEvent(RealtimeEvent e) {
    final current = state.ride;
    if (current == null) return;
    final rideJson = e.data['ride'];
    if (rideJson is Map<String, Object?>) {
      _apply(Ride.fromJson(rideJson));
      return;
    }
    switch (e.event) {
      case 'DriverLocationUpdated':
        final loc = e.data['location'];
        if (loc is Map<String, Object?>) {
          state = state.copyWith(
            ride: current.copyWith(
              driverLocation: DriverLocation.fromJson(loc),
            ),
          );
        }
      default:
        // Any event we don't fully understand → refetch authoritative state.
        unawaited(_refetch(current.id));
    }
  }

  // ---------------------------------------------------------------------
  // Passenger location publishing (only while a trip is tracking)
  // ---------------------------------------------------------------------

  void _startLocationPublishing(String rideId) {
    if (_locationSub != null) return;
    final svc = ref.read(locationServiceProvider);
    _locationSub = svc
        .watch(distanceFilterMeters: 15)
        .listen(
          (p) => _publish(rideId, p),
          onError: (Object e) {
            _log.warn('location stream error', {'e': '$e'});
            _markLocationPaused();
          },
        );
    unawaited(_checkLocationAvailability());
  }

  void _stopLocationPublishing() {
    unawaited(_locationSub?.cancel());
    _locationSub = null;
    if (state.locationPaused) state = state.copyWith(locationPaused: false);
  }

  Future<void> _checkLocationAvailability() async {
    final a = await ref.read(locationServiceProvider).check();
    if (a != LocationAvailability.ready) {
      _markLocationPaused();
    } else if (state.locationPaused) {
      state = state.copyWith(locationPaused: false);
    }
  }

  void _markLocationPaused() {
    if (!state.locationPaused) {
      _log.warn('passenger location paused');
      state = state.copyWith(locationPaused: true);
    }
  }

  /// UI calls this after the user returns from Settings.
  Future<void> recheckLocation() async {
    await _checkLocationAvailability();
    final r = state.ride;
    if (r != null && r.status.isTracking && !state.locationPaused) {
      _stopLocationPublishing();
      _startLocationPublishing(r.id);
    }
  }

  Future<void> _publish(String rideId, GeoPoint p) async {
    final now = DateTime.now();
    if (now.difference(_lastPublished) < _locationPublishInterval) return;
    _lastPublished = now;
    if (state.locationPaused) state = state.copyWith(locationPaused: false);
    try {
      await ref.read(rideRepositoryProvider).publishLocation(rideId, p);
    } on ApiException catch (e) {
      // Server refused because the trip is over — stop, don't spam.
      if (e.hasServerCode(ServerErrorCodes.tripNotActive) ||
          e.code == ApiErrorCode.conflict) {
        _stopLocationPublishing();
        unawaited(_refetch(rideId));
      }
    } on Object {
      // transient; next tick retries
    }
  }
}

/// A single ride by id: serves the active ride from memory when it matches,
/// otherwise fetches (history detail, or post-trip screens after the active
/// ride has been dismissed).
final rideByIdProvider = FutureProvider.autoDispose.family<Ride, String>((
  ref,
  id,
) async {
  final active = ref.watch(activeRideProvider.select((s) => s.ride));
  if (active != null && active.id == id) return active;
  return ref.read(rideRepositoryProvider).getRide(id);
});
