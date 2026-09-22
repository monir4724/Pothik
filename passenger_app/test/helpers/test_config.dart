import 'package:pothik_passenger/core/config/app_config.dart';
import 'package:pothik_passenger/core/location/location_service.dart';

const testConfig = AppConfig(
  environment: AppEnvironment.dev,
  apiBaseUrl: 'http://localhost/api/v1',
  reverbHost: 'localhost',
  reverbPort: 8080,
  reverbAppKey: 'local-key',
  reverbUseTls: false,
  sentryDsn: '',
  useFakeBackend: true,
  guardianWebBaseUrl: 'https://track.example.com',
  mapsApiKey: '',
);

final class FakeLocationService implements LocationService {
  FakeLocationService({
    this.availability = LocationAvailability.ready,
    this.point = const GeoPoint(23.7925, 90.4078),
  });

  LocationAvailability availability;
  GeoPoint? point;

  @override
  Future<LocationAvailability> check() async => availability;

  @override
  Future<LocationAvailability> request() async => availability;

  @override
  Future<GeoPoint?> current({
    Duration timeout = const Duration(seconds: 8),
  }) async => point;

  @override
  Stream<GeoPoint> watch({int distanceFilterMeters = 10}) =>
      point == null ? const Stream.empty() : Stream.value(point!);

  @override
  Future<void> openAppSettings() async {}

  @override
  Future<void> openLocationSettings() async {}
}
