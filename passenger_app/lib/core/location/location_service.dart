import 'dart:async';

import 'package:geolocator/geolocator.dart';

/// The full location-availability model. The UI spec's single "permission
/// prompt" collapses four distinct real-world states; the app must handle
/// each differently (production UI review §7).
enum LocationAvailability {
  /// Permission granted (while-in-use or always) and GPS on.
  ready,

  /// Never asked / user tapped "Not now" — we may prompt again.
  denied,

  /// "Don't ask again" / iOS denied — only a Settings deep-link can fix it.
  permanentlyDenied,

  /// Permission fine but device location services are off.
  serviceDisabled,
}

final class GeoPoint {
  const GeoPoint(this.lat, this.lng, {this.accuracyMeters, this.at});

  final double lat;
  final double lng;
  final double? accuracyMeters;
  final DateTime? at;

  @override
  String toString() =>
      'GeoPoint(${lat.toStringAsFixed(5)}, '
      '${lng.toStringAsFixed(5)})';
}

abstract interface class LocationService {
  Future<LocationAvailability> check();

  /// Triggers the OS prompt. Returns the resulting availability.
  Future<LocationAvailability> request();

  Future<GeoPoint?> current({Duration timeout});

  /// Continuous updates while the app is foregrounded.
  Stream<GeoPoint> watch({int distanceFilterMeters});

  Future<void> openAppSettings();
  Future<void> openLocationSettings();
}

final class GeolocatorLocationService implements LocationService {
  @override
  Future<LocationAvailability> check() async {
    final perm = await Geolocator.checkPermission();
    return _resolve(perm);
  }

  @override
  Future<LocationAvailability> request() async {
    var perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied) {
      perm = await Geolocator.requestPermission();
    }
    return _resolve(perm);
  }

  Future<LocationAvailability> _resolve(LocationPermission perm) async {
    switch (perm) {
      case LocationPermission.deniedForever:
        return LocationAvailability.permanentlyDenied;
      case LocationPermission.denied:
      case LocationPermission.unableToDetermine:
        return LocationAvailability.denied;
      case LocationPermission.whileInUse:
      case LocationPermission.always:
        final on = await Geolocator.isLocationServiceEnabled();
        return on
            ? LocationAvailability.ready
            : LocationAvailability.serviceDisabled;
    }
  }

  @override
  Future<GeoPoint?> current({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      final p = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: timeout,
        ),
      );
      return _toPoint(p);
    } on TimeoutException {
      // Fall back to the last cached fix rather than failing the screen.
      final last = await Geolocator.getLastKnownPosition();
      return last == null ? null : _toPoint(last);
    } on Object {
      return null;
    }
  }

  @override
  Stream<GeoPoint> watch({int distanceFilterMeters = 10}) =>
      Geolocator.getPositionStream(
        locationSettings: LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: distanceFilterMeters,
        ),
      ).map(_toPoint);

  GeoPoint _toPoint(Position p) => GeoPoint(
    p.latitude,
    p.longitude,
    accuracyMeters: p.accuracy,
    at: p.timestamp,
  );

  @override
  Future<void> openAppSettings() => Geolocator.openAppSettings();

  @override
  Future<void> openLocationSettings() => Geolocator.openLocationSettings();
}
